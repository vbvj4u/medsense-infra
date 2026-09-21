variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "ap-southeast-2"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "prod"
}

variable "deploy_role_arn" {
  description = "IAM role to assume for deploys into this account. Null when running with the caller's own credentials (typical for a single prod account)."
  type        = string
  default     = null
}

variable "github_org_repos" {
  description = "GitHub \"org/repo\" for each of the three repos, used to scope the OIDC trust policies."
  type = object({
    terraform = string
    backend   = string
    frontend  = string
  })
  default = {
    terraform = "your-org/medsense-infra"
    backend   = "your-org/medsense-backend"
    frontend  = "your-org/medsense-frontend"
  }
}
