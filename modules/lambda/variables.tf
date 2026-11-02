variable "role_arn" {
  description = "ARN of the IAM role the function runs as"
  type        = string
}

variable "role_name" {
  description = "Name of that role (the module attaches its logs and dead-letter-queue policy to it)"
  type        = string
}

variable "table_name" {
  description = "DynamoDB table the collector writes to"
  type        = string
}

variable "targets" {
  description = "URLs to check each interval"
  type = list(object({
    name = string
    url  = string
  }))
}

variable "function_name" {
  description = "Lambda function name"
  type        = string
  default     = "metrics-collector"
}

variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
}

variable "timeout" {
  description = "Function timeout in seconds (must exceed targets x request timeout)"
  type        = number
  default     = 30
}

variable "memory_size" {
  description = "Memory in MB"
  type        = number
  default     = 128
}

variable "schedule_expression" {
  description = "EventBridge schedule. Keep it in step with INTERVAL_SECONDS (default 300) in script.py"
  type        = string
  default     = "rate(5 minutes)"
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention"
  type        = number
  default     = 14
}

variable "resource_owner" {
  description = "Name and owner tags"
  type        = map(string)
}
