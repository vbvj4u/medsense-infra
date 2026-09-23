variable "aws_region" {
  description = "AWS region to bootstrap the state backend in."
  type        = string
  default     = "ap-southeast-2"
}

variable "account_name" {
  description = "Logical name of the AWS account being bootstrapped (dev, staging, prod)."
  type        = string
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
