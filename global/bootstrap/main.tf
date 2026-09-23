############################################
# Bootstrap: remote state backend + CI/CD identity
############################################
# This is deployed with plain local state (chicken-and-egg problem:
# you cannot use an S3 backend before the S3 bucket exists). Run this
# once per AWS account, then every environment under accounts/<env>
# points its backend.tf at the bucket/table this creates.
#
#   cd global/bootstrap
#   terraform init
#   terraform apply -var="account_name=dev" -var="github_org_repos={...}"
#
# The state file this produces (terraform.tfstate) should itself be
# stored somewhere durable (e.g. committed to a private repo, or
# copied to S3 by hand afterwards) since it is not remote.
#
# The GitHub OIDC provider + the three per-repo deploy roles also live
# here rather than in accounts/<env>, and that's deliberate, not an
# oversight: those roles (in particular medsense-<env>-terraform-ci)
# are the credentials the accounts/<env> destroy workflow runs as. A
# `terraform destroy` on accounts/<env> tears down everything in that
# state, in dependency order - if the CI role's own permissions were
# part of that state, destroy would revoke its own credentials
# mid-run (this happened in practice: the role's inline policy has no
# dependents, so it gets destroyed in the very first wave, and every
# AWS call afterwards - including the final state write - starts
# failing with AccessDenied). Keeping CI identity in this
# never-destroyed, separately-applied state means accounts/<env> can
# be destroyed and recreated freely without ever touching the
# credentials used to do it, and without GitHub secrets (the role
# ARNs) ever needing to change.
#
# Because this state doesn't know about accounts/<env>'s resources,
# the backend/frontend deploy roles' scoped permissions are built from
# the same deterministic naming convention accounts/<env>/main.tf uses
# (medsense-<env>-backend, medsense-<env>-frontend-<account_id>)
# rather than live module references.

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "medsense"
      ManagedBy   = "terraform"
      Layer       = "bootstrap"
      Environment = var.account_name
    }
  }
}

module "state_backend" {
  source = "../../modules/state_backend"

  state_bucket_name = "medsense-tfstate-${var.account_name}-${data.aws_caller_identity.current.account_id}"
  lock_table_name   = "medsense-terraform-locks-${var.account_name}"

  tags = local.common_tags
}

data "aws_caller_identity" "current" {}

locals {
  name_prefix = "medsense-${var.account_name}"
  account_id  = data.aws_caller_identity.current.account_id

  common_tags = {
    Project     = "medsense"
    ManagedBy   = "terraform"
    Environment = var.account_name
  }
}

############################
# CI/CD identity (GitHub OIDC) - one role per repo
############################
module "github_oidc_infra" {
  source = "../../modules/github_oidc"

  create_oidc_provider = true # only the first module instance in the account creates it
  github_repo          = var.github_org_repos.terraform
  allowed_subject_claims = [
    "pull_request",
    "ref:refs/heads/main",
    "environment:${var.account_name}",
    "environment:${var.account_name}-destroy",
  ]
  role_name = "${local.name_prefix}-terraform-ci"

  permissions_policy_json = data.aws_iam_policy_document.terraform_ci_permissions.json

  tags = local.common_tags
}

module "github_oidc_backend" {
  source = "../../modules/github_oidc"

  create_oidc_provider   = false
  oidc_provider_arn      = module.github_oidc_infra.oidc_provider_arn
  github_repo            = var.github_org_repos.backend
  allowed_subject_claims = ["environment:${var.account_name}"]
  role_name              = "${local.name_prefix}-backend-deploy"

  permissions_policy_json = data.aws_iam_policy_document.backend_deploy_permissions.json

  tags = local.common_tags
}

module "github_oidc_frontend" {
  source = "../../modules/github_oidc"

  create_oidc_provider   = false
  oidc_provider_arn      = module.github_oidc_infra.oidc_provider_arn
  github_repo            = var.github_org_repos.frontend
  allowed_subject_claims = ["environment:${var.account_name}"]
  role_name              = "${local.name_prefix}-frontend-deploy"

  permissions_policy_json = data.aws_iam_policy_document.frontend_deploy_permissions.json

  tags = local.common_tags
}

############################
# Least-privilege policies for each CI role
############################

# The terraform repo's own CI needs broad-ish infra permissions to
# plan/apply the accounts/<env> stack. Scope further per your
# organisation's needs; this is intentionally still narrower than
# AdministratorAccess.
data "aws_iam_policy_document" "terraform_ci_permissions" {
  statement {
    sid    = "InfraManagement"
    effect = "Allow"
    actions = [
      "dynamodb:*",
      "lambda:*",
      "apigateway:*",
      "s3:*",
      "cloudfront:*",
      "iam:GetRole",
      "iam:PassRole",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:TagRole",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "iam:GetRolePolicy",
      "iam:CreateOpenIDConnectProvider",
      "iam:GetOpenIDConnectProvider",
      "iam:TagOpenIDConnectProvider",
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:PutParameter",
      "ssm:DeleteParameter",
      "ssm:DescribeParameters",
      "ssm:ListTagsForResource",
      "ssm:AddTagsToResource",
      "logs:*",
      "cloudwatch:*",
    ]
    resources = ["*"]
  }
}

# Scoped to the Lambda function accounts/<env>/main.tf creates, by its
# deterministic name - this state has no live reference to that
# module, on purpose (see the header comment).
data "aws_iam_policy_document" "backend_deploy_permissions" {
  statement {
    sid    = "UpdateLambdaCode"
    effect = "Allow"
    actions = [
      "lambda:UpdateFunctionCode",
      "lambda:UpdateFunctionConfiguration",
      "lambda:GetFunction",
      "lambda:GetFunctionConfiguration",
      "lambda:PublishVersion",
    ]
    resources = ["arn:aws:lambda:${var.aws_region}:${local.account_id}:function:${local.name_prefix}-backend"]
  }
}

# Scoped to the frontend bucket accounts/<env>/main.tf creates, by its
# deterministic name (bucket_name = "${name_prefix}-frontend-${account_id}"
# there - no random suffix, so it's reproducible here too).
data "aws_iam_policy_document" "frontend_deploy_permissions" {
  statement {
    sid    = "SyncFrontendAssets"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:DeleteObject",
    ]
    resources = [
      "arn:aws:s3:::${local.name_prefix}-frontend-${local.account_id}",
      "arn:aws:s3:::${local.name_prefix}-frontend-${local.account_id}/*",
    ]
  }

  statement {
    sid    = "InvalidateCloudFront"
    effect = "Allow"
    actions = [
      "cloudfront:CreateInvalidation",
    ]
    resources = ["*"]
  }
}
