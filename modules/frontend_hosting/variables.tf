variable "bucket_name" {
  description = "Globally-unique S3 bucket name for the built frontend assets."
  type        = string
}

variable "tags" {
  description = "Tags applied to the S3 bucket and CloudFront distribution."
  type        = map(string)
  default     = {}
}
