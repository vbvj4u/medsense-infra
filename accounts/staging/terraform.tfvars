aws_region  = "ap-southeast-2"
environment = "staging"

# github_org_repos now lives in global/bootstrap/terraform.tfvars - the
# GitHub OIDC identity moved there, see that module's main.tf header.

# Scaffold only - this environment is not deployed. Fill in if/when a
# separate staging AWS account is fronted by a central CI/tooling account.
deploy_role_arn = null
