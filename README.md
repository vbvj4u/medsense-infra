# medsense-infra

Terraform for MedSense's 3-tier AWS architecture:

```
[ Presentation ]  S3 + CloudFront            (medsense-frontend repo)
        |  HTTPS/JSON
        v
[ Application  ]  Lambda + API Gateway (HTTP)(medsense-backend repo)
        |  AWS SDK
        v
[ Data         ]  DynamoDB
```

Three separate GitHub repos, one per tier, each with its own CI/CD:
**medsense-infra** (this repo, Terraform), **medsense-backend**
(FastAPI on Lambda), **medsense-frontend** (React on S3/CloudFront).
Each repo's pipeline authenticates to AWS via a narrowly-scoped GitHub
OIDC role that this repo provisions for it - no long-lived AWS keys
anywhere.

## Why these services (AWS free tier only)

Every resource here is chosen to run at $0 at dev/demo traffic:

| Tier | Service | Free tier |
|---|---|---|
| Presentation | S3 + CloudFront | 5 GB S3 + 1 TB/10M requests CloudFront, 12 months |
| Application | Lambda + API Gateway (HTTP API) | 1M Lambda requests/month **forever**; API Gateway 1M req/month, 12 months |
| Data | DynamoDB (`PAY_PER_REQUEST`) | 25 GB + 25 WCU/RCU-equivalent, **forever** |
| Secrets | SSM Parameter Store (`SecureString`) | Standard parameters are **free indefinitely** (unlike Secrets Manager, ~$0.40/secret/month after a 30-day trial) |
| State | S3 + DynamoDB (lock table) | Same free tiers as above |

No NAT Gateway, no ALB, no RDS, no always-on EC2/ECS - those are the
usual line items that turn a "free tier" AWS demo into a bill. The
`network` module is included (see its header comment) for a possible
future tier that needs a VPC, but nothing in `dev` calls it.

## Layout: multi-account, multi-environment

```
medsense-infra/
├── global/bootstrap/     # once per AWS account: creates the S3+DynamoDB state backend
├── modules/               # reusable building blocks, one concern each
│   ├── network/           # optional VPC (unused by dev - see file header)
│   ├── dynamodb/          # data tier
│   ├── lambda_backend/    # application tier compute
│   ├── api_gateway/       # application tier HTTP front door
│   ├── frontend_hosting/  # presentation tier (S3 + CloudFront)
│   ├── secrets/           # SSM Parameter Store SecureString
│   ├── github_oidc/       # one role per repo, keyless GitHub Actions -> AWS
│   └── state_backend/     # S3 bucket + DynamoDB lock table
├── accounts/
│   ├── dev/                # ACTIVE - the only environment actually deployed
│   ├── staging/             # scaffold, same modules, not deployed
│   └── prod/                 # scaffold, same modules, not deployed
└── .github/workflows/      # one CI/CD pipeline per environment (see below)
```

Each `accounts/<env>/` is a root module wiring the same reusable
modules together, with its own state file, its own `backend.tf`
(pointing at that account's S3/DynamoDB backend), and its own
`terraform.tfvars`. This is the standard "account per environment"
pattern: promoting to staging/prod later means pointing that
environment's backend + `deploy_role_arn` at a real AWS account and
running its Terraform - no code changes, no restructuring.

**Only `dev` is deployed.** `staging` and `prod` are complete,
plan-ready scaffolds (identical module wiring, different
`environment`/tfvars) kept so the "whole structure" exists without
costing anything until a second/third AWS account is actually
provisioned.

## CI/CD (GitHub Actions, per environment) - plan / manual-approve-apply / manual-approve-destroy

Terraform's own pipeline is entirely plan-then-apply, with an
approval gate in between - CI never applies anything on its own.
Three reusable workflows implement the steps once; nine thin callers
(3 per environment) wire them to `dev`/`staging`/`prod`:

| Step | Workflow | Trigger | What happens |
|---|---|---|---|
| 1. Plan | `terraform-<env>-plan.yml` | Automatically on PR open/update touching `accounts/<env>/**` or `modules/**` (or manually, given a PR number) | Runs `terraform plan -out=tfplan`, uploads `tfplan` as a build artifact (keyed to the PR), and posts the human-readable plan as a PR comment. **Nothing is applied.** |
| 2. Review | - | A person reads the plan comment (or the run's summary) | |
| 3. Apply | `terraform-<env>-apply.yml` | **Manual only** (`workflow_dispatch`, give it the PR number) | Downloads *that exact* `tfplan` artifact (pinned to the commit it was planned against, so later commits on the PR can't silently change what gets applied), then the job pauses on the `<env>` GitHub Environment until a required reviewer clicks **Approve** - only then does it run `terraform apply tfplan`, unchanged. |
| Destroy | `terraform-<env>-destroy.yml` | **Manual only**, requires typing the environment name to confirm | Two jobs: first computes `terraform plan -destroy` and publishes it to the run's summary (nothing destroyed yet); second job pauses on a **separate** `<env>-destroy` GitHub Environment for required-reviewer approval, then runs the destroy. |

Set up once per repo, in **Settings → Environments**:

- `dev`, `staging`, `prod` - add **Required reviewers** to each (this
  is literally what makes plan → apply a manual, approved step).
- `dev-destroy`, `staging-destroy`, `prod-destroy` - same, ideally
  with different/additional required reviewers than the plain `<env>`
  ones, so a destroy always needs its own sign-off.
- Each environment holds that account's secrets: `AWS_TERRAFORM_CI_ROLE_ARN`
  (the `terraform_ci_role_arn` output), `TF_STATE_BUCKET` /
  `TF_LOCK_TABLE` (from `global/bootstrap`'s output for that account).

Typical flow for a change to `dev`:

```text
1. Open a PR touching accounts/dev/** or modules/**
   -> "Terraform - dev (plan)" runs automatically, comments the plan on the PR
2. Read the plan comment
3. Actions tab -> "Terraform - dev (apply)" -> Run workflow -> enter the PR number
   -> job pauses "Waiting for review" on the `dev` Environment
4. A required reviewer approves it in the Actions UI
   -> terraform apply runs against exactly the reviewed plan
5. Merge the PR (keeps main in sync with what's now deployed)
```

The plan → apply artifact hand-off uses the community action
[`dawidd6/action-download-artifact`](https://github.com/dawidd6/action-download-artifact)
to fetch an artifact across separate workflow runs (GitHub's own
`actions/download-artifact` only works within a single run) - allow
it in **Settings → Actions → Allow list** if your org restricts
third-party actions.

The backend and frontend repos have their own, separate
`deploy-dev.yml` / `deploy-staging.yml` / `deploy-prod.yml` pipelines
(auto-deploy on push for dev, manual for staging/prod) - see their
READMEs for the secrets each one needs (all sourced from this repo's
Terraform outputs). Those aren't Terraform applies, so they don't need
the same plan/apply artifact hand-off - ask if you'd like the same
manual-approval gate added there too.

## Secrets

API keys and DB passwords are stored in **SSM Parameter Store**
(`SecureString`, KMS-encrypted) via the `secrets` module, never in
Terraform variables, env files, or app code. The Lambda's IAM role is
granted `ssm:GetParameter` on only the specific parameters it needs;
the app resolves them by name at runtime (see
`medsense-backend/app/secrets.py`). Parameter Store was chosen over
AWS Secrets Manager specifically to stay inside the AWS free tier -
see `modules/secrets/main.tf` for the cost reasoning and how to swap
to Secrets Manager later if rotation/cross-account features are ever
needed.

After `terraform apply`, set real values (Terraform only writes a
`CHANGE-ME` placeholder, then ignores further changes to it):

```bash
aws ssm put-parameter --name /medsense/dev/medicine-api-key \
  --type SecureString --overwrite --value "<real value>"
```

## Getting started (dev account)

```bash
# 1. One-time per AWS account: create the remote state backend
AWS_PROFILE=medsense-dev ./scripts/bootstrap.sh dev ap-southeast-2
# -> prints the bucket/table to put in accounts/dev/backend.hcl

# 2. Deploy the stack
cd accounts/dev
cp backend.hcl.example backend.hcl   # fill in with step 1's output
terraform init -backend-config=backend.hcl
terraform plan
terraform apply

# 3. Wire up GitHub Actions:
#    - repo secrets (see CI/CD table above) on this repo, medsense-backend, medsense-frontend
#    - copy the *_deploy_role_arn / bucket / function name / API URL outputs into each repo's GitHub Environment
```

## Promoting to staging/prod

1. Provision (or designate) a separate AWS account for that
   environment.
2. Run `scripts/bootstrap.sh staging <region>` (or `prod`) against it.
3. Fill in `accounts/staging/backend.hcl` and
   `accounts/staging/terraform.tfvars` (real `github_org_repos`, and
   `deploy_role_arn` if a central CI account assumes into it).
4. `terraform init -backend-config=backend.hcl && terraform plan` in
   `accounts/staging`.
5. Add the `staging` GitHub Environment's secrets, then run
   `terraform-staging.yml` with "apply" ticked.

`prod` follows the same steps; give the `prod` GitHub Environment
required reviewers so nothing applies without a human approving it.
