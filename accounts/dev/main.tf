############################################
# medsense - dev environment
############################################
# Wires the reusable modules together into the actual 3-tier stack.
# network is intentionally NOT called - see modules/network/main.tf.

locals {
  name_prefix = "medsense-${var.environment}"
  account_id  = data.aws_caller_identity.current.account_id

  common_tags = {
    Project     = "medsense"
    Environment = var.environment
  }
}

############################
# Data tier
############################
module "dynamodb" {
  source = "../../modules/dynamodb"

  table_name = "${local.name_prefix}-medicines"
  hash_key   = "id"

  tags = local.common_tags
}

############################
# Secrets (API keys, DB passwords, etc.)
############################
# SSM Parameter Store SecureString - see modules/secrets/main.tf for
# why this is used instead of AWS Secrets Manager. Placeholder values
# only; set the real ones out-of-band after apply, e.g.:
#   aws ssm put-parameter --name /medsense/dev/medicine-api-key \
#     --type SecureString --overwrite --value "<real value>"
module "secrets" {
  source = "../../modules/secrets"

  path_prefix = "medsense/${var.environment}"

  secrets = {
    # External medicine-data API key, if/when the backend calls one
    # out (e.g. an authoritative drug database) instead of only
    # reading its own DynamoDB table.
    "medicine-api-key" = {
      description   = "API key for the external medicine-info provider"
      initial_value = "CHANGE-ME"
    }
    # Not used by the DynamoDB-backed stack today; kept so switching
    # the data tier to RDS later is a drop-in (module + this secret
    # already exist, nothing new to wire through CI).
    "db-password" = {
      description   = "Database password (reserved for a future RDS data tier)"
      initial_value = "CHANGE-ME"
    }
  }

  tags = local.common_tags
}

############################
# Application tier
############################
module "lambda_backend" {
  source = "../../modules/lambda_backend"

  function_name      = "${local.name_prefix}-backend"
  handler            = "app.handler" # Mangum-wrapped FastAPI app, see medsense-backend
  runtime            = "python3.12"
  memory_size        = 256
  timeout            = 10
  dynamodb_table_arn = module.dynamodb.table_arn

  environment_variables = {
    DYNAMODB_TABLE         = module.dynamodb.table_name
    ENVIRONMENT            = var.environment
    MEDICINE_API_KEY_PARAM = module.secrets.parameter_names["medicine-api-key"]
  }

  tags = local.common_tags
}

# Least-privilege read access to just the two parameters above - the
# app fetches them by name at runtime (see medsense-backend's
# app/secrets.py) rather than having values baked into env vars at
# deploy time, so rotating a secret needs no redeploy.
data "aws_iam_policy_document" "lambda_secrets_access" {
  statement {
    actions   = ["ssm:GetParameter"]
    resources = values(module.secrets.parameter_arns)
  }
}

resource "aws_iam_role_policy" "lambda_secrets_access" {
  name   = "${local.name_prefix}-backend-secrets-access"
  role   = module.lambda_backend.role_name
  policy = data.aws_iam_policy_document.lambda_secrets_access.json
}

module "api_gateway" {
  source = "../../modules/api_gateway"

  api_name             = "${local.name_prefix}-api"
  stage_name           = "$default"
  lambda_invoke_arn    = module.lambda_backend.invoke_arn
  lambda_function_name = module.lambda_backend.function_name
  cors_allowed_origins = ["https://${module.frontend_hosting.distribution_domain_name}", "http://localhost:5173"]

  tags = local.common_tags
}

############################
# Presentation tier
############################
module "frontend_hosting" {
  source = "../../modules/frontend_hosting"

  bucket_name = "${local.name_prefix}-frontend-${local.account_id}"

  tags = local.common_tags
}

# CI/CD identity (GitHub OIDC provider + the terraform-ci/backend-deploy/
# frontend-deploy roles) lives in global/bootstrap, not here - see the
# comment at the top of global/bootstrap/main.tf for why it must not
# be part of this destroyable stack.
