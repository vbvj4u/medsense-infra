############################################
# GitHub Actions OIDC - keyless deploys from each repo
############################################
# Only the FIRST module instance in an account should create the
# provider (create_oidc_provider = true); every other instance must be
# given that instance's ARN via `oidc_provider_arn`, e.g.:
#   oidc_provider_arn = module.github_oidc_infra.oidc_provider_arn
#
# (Previously this looked the provider up with a data source when
# create_oidc_provider was false. Data sources evaluate at PLAN time,
# before the creating instance's resource exists, so a from-scratch
# `terraform plan` failed with "not found" even though apply would
# have created it moments later in the same run.)

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  # GitHub's OIDC root CA thumbprint (Actions rotates the leaf cert, not
  # this root, so this rarely needs updating).
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

locals {
  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : var.oidc_provider_arn
  repo_pattern       = "${replace(var.github_repo, "/", "*/")}*"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [for c in var.allowed_subject_claims : "repo:${local.repo_pattern}:${c}"]
    }
  }
}

resource "aws_iam_role" "deploy" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "deploy" {
  name   = "${var.role_name}-policy"
  role   = aws_iam_role.deploy.id
  policy = var.permissions_policy_json
}
