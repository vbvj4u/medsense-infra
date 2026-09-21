variable "api_name" {
  description = "Name of the HTTP API."
  type        = string
}

variable "stage_name" {
  description = "Deployment stage name."
  type        = string
  default     = "$default"
}

variable "lambda_invoke_arn" {
  description = "invoke_arn of the backend Lambda function."
  type        = string
}

variable "lambda_function_name" {
  description = "Name of the backend Lambda function (for the invoke permission)."
  type        = string
}

variable "cors_allowed_origins" {
  description = "Origins allowed to call the API (e.g. the CloudFront frontend URL)."
  type        = list(string)
  default     = ["*"]
}

variable "log_retention_days" {
  description = "CloudWatch access log retention in days."
  type        = number
  default     = 14
}

variable "tags" {
  description = "Tags applied to API Gateway resources."
  type        = map(string)
  default     = {}
}
