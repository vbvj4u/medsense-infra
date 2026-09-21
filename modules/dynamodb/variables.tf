variable "table_name" {
  description = "Name of the DynamoDB table."
  type        = string
}

variable "hash_key" {
  description = "Name of the table's partition key attribute (always type S)."
  type        = string
  default     = "id"
}

variable "additional_attributes" {
  description = "Extra attributes required by global secondary indexes."
  type = list(object({
    name = string
    type = string
  }))
  default = []
}

variable "global_secondary_indexes" {
  description = "Global secondary indexes to create on the table."
  type = list(object({
    name            = string
    hash_key        = string
    projection_type = string
  }))
  default = []
}

variable "enable_point_in_time_recovery" {
  description = "Whether to enable PITR (adds cost beyond the always-free tier at scale; off by default for dev)."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to the table."
  type        = map(string)
  default     = {}
}
