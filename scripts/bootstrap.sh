#!/usr/bin/env bash
# Bootstraps the remote state backend (S3 bucket + DynamoDB lock table)
# for one AWS account, then prints the backend.hcl values to use for
# every `terraform init` in accounts/<env> against that account.
#
# Usage:
#   AWS_PROFILE=medsense-dev ./scripts/bootstrap.sh dev ap-southeast-2
#
set -euo pipefail

ACCOUNT_NAME="${1:?Usage: bootstrap.sh <account-name e.g. dev> [aws-region]}"
AWS_REGION="${2:-ap-southeast-2}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BOOTSTRAP_DIR="${REPO_ROOT}/global/bootstrap"

echo "==> Bootstrapping remote state backend for account '${ACCOUNT_NAME}' in ${AWS_REGION}"
echo "    (uses your current AWS credentials/profile - make sure they point at the right account)"

cd "${BOOTSTRAP_DIR}"
terraform init -input=false
terraform apply -input=false -auto-approve \
  -var="account_name=${ACCOUNT_NAME}" \
  -var="aws_region=${AWS_REGION}"

BUCKET=$(terraform output -raw state_bucket_name)
TABLE=$(terraform output -raw lock_table_name)

echo ""
echo "==> Done. Write this to accounts/${ACCOUNT_NAME}/backend.hcl (gitignored):"
echo ""
echo "    bucket         = \"${BUCKET}\""
echo "    dynamodb_table = \"${TABLE}\""
echo ""
echo "==> Then:"
echo "    cd ${REPO_ROOT}/accounts/${ACCOUNT_NAME}"
echo "    terraform init -backend-config=backend.hcl"
echo "    terraform plan"
