output "parameter_arns" {
  description = "Map of secret name -> SSM parameter ARN, for scoping IAM read access."
  value       = { for k, v in aws_ssm_parameter.this : k => v.arn }
}

output "parameter_names" {
  description = "Map of secret name -> full SSM parameter name (path), for the app to read at runtime."
  value       = { for k, v in aws_ssm_parameter.this : k => v.name }
}
