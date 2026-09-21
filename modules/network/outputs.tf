output "vpc_id" {
  value = var.enabled ? aws_vpc.this[0].id : null
}

output "public_subnet_ids" {
  value = var.enabled ? aws_subnet.public[*].id : []
}
