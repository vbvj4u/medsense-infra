############################################
# Secrets (API keys, DB passwords, etc.)
############################################
# Uses SSM Parameter Store SecureString rather than AWS Secrets
# Manager: functionally the same (KMS-encrypted, IAM-gated, read by
# the app at runtime, never in code/env files) but Parameter Store
# standard parameters are free indefinitely, whereas Secrets Manager
# bills ~$0.40/secret/month after a 30-day trial - not free-tier safe.
# Swap the resource for aws_secretsmanager_secret[_version] here if a
# real Secrets Manager feature (automatic rotation, cross-account
# resource policies) is ever needed and the cost is acceptable.
#
# Values are written here as a placeholder on first apply and then
# ignored by Terraform - rotate/set the real value out-of-band
# (`aws ssm put-parameter --overwrite`) so secrets never live in
# .tf source or state diffs after that.

resource "aws_ssm_parameter" "this" {
  for_each = var.secrets

  name        = "/${var.path_prefix}/${each.key}"
  description = each.value.description
  type        = "SecureString"
  key_id      = "alias/aws/ssm" # AWS-managed key: no monthly charge, unlike a customer-managed CMK
  value       = each.value.initial_value

  lifecycle {
    ignore_changes = [value] # real values are set out-of-band after apply, see above
  }

  tags = var.tags
}
