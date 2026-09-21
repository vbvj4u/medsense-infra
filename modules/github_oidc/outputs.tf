output "role_arn" {
  value = aws_iam_role.deploy.arn
}

output "role_name" {
  value = aws_iam_role.deploy.name
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider this instance created or was given. Pass this into every other instance's oidc_provider_arn variable in the same account."
  value       = local.oidc_provider_arn
}