############################################
# Lambda backend (Application tier)
############################################
# Lambda's always-free tier (1M requests + 400,000 GB-seconds/month,
# forever, not just 12 months) is why this is the compute choice for
# the API - no EC2/NAT/ALB cost sitting idle between requests.

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name               = "${var.function_name}-exec-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "dynamodb_access" {
  statement {
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan",
    ]
    resources = [
      var.dynamodb_table_arn,
      "${var.dynamodb_table_arn}/index/*",
    ]
  }
}

resource "aws_iam_role_policy" "dynamodb_access" {
  name   = "${var.function_name}-dynamodb-access"
  role   = aws_iam_role.lambda_exec.id
  policy = data.aws_iam_policy_document.dynamodb_access.json
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

# The function is provisioned here with a tiny placeholder package,
# committed to the repo (placeholder.zip) rather than built at
# plan/apply time by an `archive_file` data source. Plan and apply run
# as separate jobs on separate, ephemeral GitHub Actions runners -
# apply only replays the reviewed plan's resource actions, it doesn't
# re-run data sources, so a file `archive_file` generated on the plan
# runner would never exist on the apply runner (this happened in
# practice: "no such file or directory" reading .placeholder.zip). A
# git-tracked file is present on both, since both run actions/checkout.
#
# The backend application repo's own CI pipeline (assuming the
# github_oidc backend-deploy role) pushes real code afterwards via
# `aws lambda update-function-code`, so Terraform never needs to know
# about individual app releases.
resource "aws_lambda_function" "this" {
  function_name = var.function_name
  role          = aws_iam_role.lambda_exec.arn
  handler       = var.handler
  runtime       = var.runtime
  memory_size   = var.memory_size
  timeout       = var.timeout

  filename         = "${path.module}/placeholder.zip"
  source_code_hash = filebase64sha256("${path.module}/placeholder.zip")

  environment {
    variables = var.environment_variables
  }

  # Real deployments overwrite the code; Terraform should not fight
  # that on every plan/apply.
  lifecycle {
    ignore_changes = [filename, source_code_hash, environment]
  }

  tags = var.tags

  depends_on = [aws_cloudwatch_log_group.lambda]
}
