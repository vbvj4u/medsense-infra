aws_region  = "ap-southeast-2"
environment = "dev"

# Set these once the actual GitHub repos exist.
github_org_repos = {
  terraform = "vbvj4u/medsense-infra"
  backend   = "vbvj4u/medsense-backend"
  frontend  = "vbvj4u/medsense-frontend"
}

# Single-account dev setup: leave null. Fill in only if dev is fronted
# by a separate CI/tooling account that assumes into it.
deploy_role_arn = null
