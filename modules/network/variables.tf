variable "enabled" {
  description = "Whether to create any network resources at all. Kept false in dev - nothing there needs a VPC."
  type        = bool
  default     = false
}

variable "name" {
  description = "Name prefix for network resources."
  type        = string
  default     = "medsense"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets."
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "availability_zones" {
  description = "Availability zones for the public subnets (must match length of public_subnet_cidrs)."
  type        = list(string)
  default     = ["ap-southeast-2a", "ap-southeast-2b"]
}

variable "tags" {
  description = "Tags applied to network resources."
  type        = map(string)
  default     = {}
}
