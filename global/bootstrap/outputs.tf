output "state_bucket_name" {
  value = module.state_backend.state_bucket_name
}

output "lock_table_name" {
  value = module.state_backend.lock_table_name
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "oidc_provider_arn" {
  value = module.github_oidc_infra.oidc_provider_arn
}

output "terraform_ci_role_arn" {
  description = "IAM role the infra repo's own GitHub Actions workflow assumes to plan/apply/destroy. Set this as that repo's AWS_TERRAFORM_CI_ROLE_ARN secret."
  value       = module.github_oidc_infra.role_arn
}

output "backend_deploy_role_arn" {
  description = "IAM role the backend repo's GitHub Actions workflow assumes. Set this as that repo's deploy-role secret."
  value       = module.github_oidc_backend.role_arn
}

output "frontend_deploy_role_arn" {
  description = "IAM role the frontend repo's GitHub Actions workflow assumes. Set this as that repo's deploy-role secret."
  value       = module.github_oidc_frontend.role_arn
}
