output "state_bucket_name" {
  value = module.state_backend.state_bucket_name
}

output "lock_table_name" {
  value = module.state_backend.lock_table_name
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}
