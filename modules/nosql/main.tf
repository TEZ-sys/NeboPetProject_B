resource "aws_dynamodb_table" "metrics" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST" # no idle cost, fits a bursty pet project
  hash_key     = "host"
  range_key    = "ts"

  attribute {
    name = "host"
    type = "S"
  }

  attribute {
    name = "ts"
    type = "S"
  }

  # Old metrics expire by themselves (the collector sets expires_at).
  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  # enabled = true uses the AWS managed key (aws/dynamodb) when kms_key_arn is null.
  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  deletion_protection_enabled = var.deletion_protection

  tags = {
    Name = var.table_name
    Owner = var.resource_owner["owner"]
  }
}
