############################################
# Bootstrap: creates the remote state backend
############################################
# This is the ONE piece of infra that is deployed with plain local
# state (chicken-and-egg problem: you cannot use an S3 backend before
# the S3 bucket exists). Run this once per AWS account, then every
# environment under accounts/<env> points its backend.tf at the
# bucket/table this creates.
#
#   cd global/bootstrap
#   terraform init
#   terraform apply -var="account_name=dev"
#
# The state file this produces (terraform.tfstate) should itself be
# stored somewhere durable (e.g. committed to a private repo, or
# copied to S3 by hand afterwards) since it is not remote.

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

  tags = {
    Project     = "medsense"
    ManagedBy   = "terraform"
    Environment = var.account_name
  }
}

data "aws_caller_identity" "current" {}
