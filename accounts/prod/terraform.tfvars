aws_region  = "ap-southeast-2"
environment = "prod"

# Set these once the actual GitHub repos exist.
github_org_repos = {
  terraform = "vbvj4u/medsense-infra"
  backend   = "vbvj4u/medsense-backend"
  frontend  = "vbvj4u/medsense-frontend"
}

# Scaffold only - this environment is not deployed. Fill in if/when a
# separate prod AWS account is fronted by a central CI/tooling account.
deploy_role_arn = null
