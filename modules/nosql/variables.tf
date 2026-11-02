variable "table_name" {
  description = "Name of the DynamoDB table"
  type        = string
  default     = "metrics"
}

variable "deletion_protection" {
  description = "Block table deletion (set to false before terraform destroy)"
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "Customer managed KMS key; null uses the AWS managed key. A customer key also needs kms permissions on the Lambda roles."
  type        = string
  default     = null
}

variable "resource_owner" {
  description = "resource_owner variables for the Lambda function"
  type        = map(string)
}
