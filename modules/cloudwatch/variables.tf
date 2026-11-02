variable "name" {
  description = "Replication group id of the cache (alarms and log groups are named after it)"
  type        = string
}

variable "num_cache_clusters" {
  description = "Number of cache nodes, one pair of alarms is created per node"
  type        = number
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
}

variable "resource_owner" {
  description = "Name and owner tags"
  type        = map(string)
}
