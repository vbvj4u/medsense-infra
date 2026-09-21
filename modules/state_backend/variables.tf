variable "state_bucket_name" {
  description = "Globally-unique name for the S3 bucket that stores Terraform state."
  type        = string
}

variable "lock_table_name" {
  description = "Name of the DynamoDB table used for Terraform state locking."
  type        = string
  default     = "medsense-terraform-locks"
}

variable "tags" {
  description = "Tags applied to the state bucket and lock table."
  type        = map(string)
  default     = {}
}
