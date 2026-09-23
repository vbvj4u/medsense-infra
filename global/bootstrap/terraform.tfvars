# Shared across every account_name this is applied for (dev/staging/prod
# all use the same three repos) - override per-invocation if that stops
# being true.
github_org_repos = {
  terraform = "vbvj4u/medsense-infra"
  backend   = "vbvj4u/medsense-backend"
  frontend  = "vbvj4u/medsense-frontend"
}
