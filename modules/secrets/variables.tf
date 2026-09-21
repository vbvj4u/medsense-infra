variable "path_prefix" {
  description = "SSM parameter path prefix, e.g. \"medsense/dev\". Parameters are created at /<path_prefix>/<key>."
  type        = string
}

variable "secrets" {
  description = "Map of secret name -> { description, initial_value }. initial_value is a one-time placeholder; set the real value out-of-band after apply."
  type = map(object({
    description   = string
    initial_value = string
  }))
}

variable "tags" {
  type    = map(string)
  default = {}
}
