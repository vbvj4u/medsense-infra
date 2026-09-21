provider "aws" {
  region = var.aws_region

  # Multi-account pattern: each environment's pipeline runs with
  # credentials for its own AWS account. When a cross-account
  # deploy role is used (e.g. a central CI account assuming into
  # dev/staging/prod), set deploy_role_arn; leave it null to use the
  # caller's own credentials directly, which is what a solo dev
  # account typically does.
  dynamic "assume_role" {
    for_each = var.deploy_role_arn == null ? [] : [var.deploy_role_arn]
    content {
      role_arn = assume_role.value
    }
  }

  default_tags {
    tags = {
      Project     = "medsense"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

data "aws_caller_identity" "current" {}
