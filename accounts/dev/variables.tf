variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "ap-southeast-2"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "dev"
}

variable "deploy_role_arn" {
  description = "IAM role to assume for deploys into this account. Null when running with the caller's own credentials (typical for a single dev account)."
  type        = string
  default     = null
}
