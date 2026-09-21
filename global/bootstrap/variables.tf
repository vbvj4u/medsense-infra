variable "aws_region" {
  description = "AWS region to bootstrap the state backend in."
  type        = string
  default     = "ap-southeast-2"
}

variable "account_name" {
  description = "Logical name of the AWS account being bootstrapped (dev, staging, prod)."
  type        = string
}
