############################################
# DynamoDB table (Data tier)
############################################
# PAY_PER_REQUEST billing keeps this inside DynamoDB's always-free
# tier (25 GB storage, 25 provisioned-equivalent WCU/RCU) at
# dev/demo traffic levels - no capacity planning needed.

resource "aws_dynamodb_table" "this" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = var.hash_key

  attribute {
    name = var.hash_key
    type = "S"
  }

  dynamic "attribute" {
    for_each = var.additional_attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  dynamic "global_secondary_index" {
    for_each = var.global_secondary_indexes
    content {
      name            = global_secondary_index.value.name
      hash_key        = global_secondary_index.value.hash_key
      projection_type = global_secondary_index.value.projection_type
    }
  }

  # Point-in-time recovery is off by default to keep this strictly
  # free-tier; flip on per-environment if prod ever needs it.
  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  tags = var.tags
}
