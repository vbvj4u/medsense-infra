aws_region  = "ap-southeast-2"
environment = "dev"

# github_org_repos now lives in global/bootstrap/terraform.tfvars - the
# GitHub OIDC identity moved there, see that module's main.tf header.

# Single-account dev setup: leave null. Fill in only if dev is fronted
# by a separate CI/tooling account that assumes into it.
deploy_role_arn = null
