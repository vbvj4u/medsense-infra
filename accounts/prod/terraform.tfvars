aws_region  = "ap-southeast-2"
environment = "prod"

# Set these once the actual GitHub repos exist.
github_org_repos = {
  terraform = "your-org/medsense-infra"
  backend   = "your-org/medsense-backend"
  frontend  = "your-org/medsense-frontend"
}

# Scaffold only - this environment is not deployed. Fill in if/when a
# separate prod AWS account is fronted by a central CI/tooling account.
deploy_role_arn = null
