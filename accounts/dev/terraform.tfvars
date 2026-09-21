aws_region  = "ap-southeast-2"
environment = "dev"

# Set these once the actual GitHub repos exist.
github_org_repos = {
  terraform = "your-org/medsense-infra"
  backend   = "your-org/medsense-backend"
  frontend  = "your-org/medsense-frontend"
}

# Single-account dev setup: leave null. Fill in only if dev is fronted
# by a separate CI/tooling account that assumes into it.
deploy_role_arn = null
