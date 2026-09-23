output "api_endpoint" {
  description = "Base URL of the backend HTTP API."
  value       = module.api_gateway.api_endpoint
}

output "frontend_url" {
  description = "CloudFront URL serving the frontend."
  value       = module.frontend_hosting.site_url
}

output "frontend_bucket_name" {
  description = "S3 bucket the frontend CI syncs built assets into."
  value       = module.frontend_hosting.bucket_name
}

output "frontend_distribution_id" {
  description = "CloudFront distribution ID, used by frontend CI to invalidate cache."
  value       = module.frontend_hosting.distribution_id
}

output "backend_lambda_function_name" {
  description = "Lambda function name the backend CI deploys code to."
  value       = module.lambda_backend.function_name
}

output "dynamodb_table_name" {
  value = module.dynamodb.table_name
}

output "secrets_parameter_names" {
  description = "SSM Parameter Store paths for app secrets - set real values with `aws ssm put-parameter --overwrite`."
  value       = module.secrets.parameter_names
}
