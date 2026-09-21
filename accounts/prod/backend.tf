# Remote state, created by global/bootstrap (run once per account).
#
# This is a *partial* backend configuration on purpose: the bucket
# name includes the AWS account ID, which we don't want hardcoded
# here for reuse across accounts. Fill it in at init time:
#
#   terraform init -backend-config=backend.hcl
#
# where backend.hcl (gitignored, one per account/person) contains:
#   bucket         = "medsense-tfstate-prod-<account-id>"
#   dynamodb_table = "medsense-terraform-locks-prod"
#
# See backend.hcl.example for a template.

terraform {
  backend "s3" {
    key     = "prod/terraform.tfstate"
    region  = "ap-southeast-2"
    encrypt = true
  }
}
