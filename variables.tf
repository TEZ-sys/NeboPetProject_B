variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "eu-west-2"
}

variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.12"
}

variable "resource_owner" {
  description = "Name and owner tags"
  type        = map(string)
  default = {
    name  = "dima"
    owner = "dfutumai"
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "instance_tenancy" {
  description = "The tenancy of the instance"
  type        = string
  default     = "default"
}
variable "create_vpc_endpoint" {
  description = "Create a DynamoDB gateway endpoint (needed for Lambdas in a VPC without NAT)"
  type        = bool
  default     = false
}

variable "monitor_targets" {
  description = "URLs the collector Lambda checks every interval"
  type = list(object({
    name = string
    url  = string
  }))
  default = [
    { name = "example", url = "https://example.com" }
  ]
}

variable "num_cache_clusters" {
  description = "Number of cache clusters (1 for single node, 2+ for multi-AZ)"
  type        = number
  default     = 2
}

variable "node_type" {
  description = "The instance type for the cache nodes"
  type        = string
  default     = "cache.t4g.micro"
}
variable "engine_version" {
  description = "The version of the Redis engine"
  type        = string
  default     = "7.0"
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 14
}

variable "redis_port" {
  description = "Port for the Redis cache"
  type        = number
  default     = 6379
}

variable "snapshot_retention_days" {
  description = "Days to keep daily Redis snapshots (0 disables persistence)"
  type        = number
  default     = 7
}

variable "redis_allowed_security_group_ids" {
  description = "Security groups of the clients allowed to reach Redis (for example the Lambda or a test host)"
  type        = list(string)
  default     = []
}

variable "create_test_client" {
  description = "Build the temporary EC2 host used to test Redis (adds an internet gateway and a public subnet)"
  type        = bool
  default     = true
}

variable "test_client_instance_type" {
  description = "Instance size of the Redis test host"
  type        = string
  default     = "t3.micro"
}
