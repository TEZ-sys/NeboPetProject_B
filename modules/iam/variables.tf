variable "dynamo_metric_arn" {
  description = "ARN of the DynamoDB table"
  type        = string
}

variable "dynamo_table_name" {
  description = "Name of the DynamoDB table"
  type        = string
}

variable "resource_owner" {
  description = "resource_owner variables for the Lambda function"
  type        = map(string)
}
