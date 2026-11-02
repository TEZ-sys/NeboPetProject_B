output "primary_endpoint_address" {
  value = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "port" {
  value = var.redis_port
}

output "security_group_id" {
  value = aws_security_group.redis.id
}

# Documentation-friendly connection string: the password is a placeholder.
output "connection_string_template" {
  value = "rediss://:<AUTH_TOKEN>@${aws_elasticache_replication_group.redis.primary_endpoint_address}:${var.redis_port}"
}
