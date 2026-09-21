############################################
# Remote state backend (S3 + DynamoDB lock)
############################################
# Deployed once per AWS account (via global/bootstrap) before any
# other environment in that account can use a "s3" backend block.

resource "aws_s3_bucket" "state" {
  bucket = var.state_bucket_name

  # Protect the state bucket from accidental deletion via terraform destroy.
  lifecycle {
    prevent_destroy = true
  }

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB is used only for state locking here (PAY_PER_REQUEST keeps it
# inside the DynamoDB always-free tier: 25 GB storage / 25 WCU-RCU worth
# of on-demand throughput is effectively free at this scale).
resource "aws_dynamodb_table" "lock" {
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = var.tags
}
