variable "resource_owner" {
  description = "resource_owner variables for the Lambda function"
  type        = map(string)
}

variable "subnet_ids" {
  description = "List of subnet IDs for the cache cluster"
  type        = list(string)
}
variable "vpc_id" {
  description = "VPC ID for the cache cluster"
  type        = string
}
variable "num_cache_clusters" {
  description = "Number of cache clusters (1 for single node, 2+ for multi-AZ)"
  type        = number
}
variable "node_type" {
  description = "The instance type for the cache nodes"
  type        = string
}
variable "engine_version" {
  description = "The version of the Redis engine"
  type        = string
}
variable "name" {
  description = "Name of the cache cluster"
  type        = string
}
variable "redis_port" {
  description = "Port for the Redis cache"
  type        = number

}
variable "auth_token" {
  description = "Password for the Redis cache: 16 to 128 printable characters, without @ \" or /"
  type        = string
  sensitive   = true
}

variable "allowed_security_group_ids" {
  description = "Security groups of the clients allowed to connect to Redis"
  type        = list(string)
  default     = []
}

variable "snapshot_retention_days" {
  description = "Days to keep daily snapshots (0 disables persistence)"
  type        = number
  default     = 7
}

variable "slow_log_group_name" {
  description = "CloudWatch log group that receives the slow log"
  type        = string
}

variable "engine_log_group_name" {
  description = "CloudWatch log group that receives the engine log"
  type        = string
}
