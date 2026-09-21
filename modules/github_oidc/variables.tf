variable "create_oidc_provider" {
  description = "Create the GitHub Actions OIDC provider. Set true on only ONE module instance per AWS account; every other instance must set this false and pass that instance's oidc_provider_arn output in via the oidc_provider_arn variable."
  type        = bool
  default     = false
}

variable "oidc_provider_arn" {
  description = "ARN of an OIDC provider created by another instance of this module in the same account. Required (and only used) when create_oidc_provider = false."
  type        = string
  default     = null
}

variable "github_repo" {
  description = "GitHub repo allowed to assume this role, as \"org/repo\"."
  type        = string
}

variable "allowed_subject_claims" {
  description = "The part of the sub claim after \"repo:<org>/<repo>:\", one per workflow shape, e.g. \"ref:refs/heads/main\", \"pull_request\", \"environment:dev\"."
  type        = list(string)
}

variable "role_name" {
  description = "Name of the IAM role GitHub Actions assumes."
  type        = string
}

variable "permissions_policy_json" {
  description = "IAM policy JSON granting this role only what its repo's pipeline needs."
  type        = string
}

variable "tags" {
  description = "Tags applied to the IAM role."
  type        = map(string)
  default     = {}
}
