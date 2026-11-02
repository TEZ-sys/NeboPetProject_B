
# ---------------------------------------------------------------------------
# Network placement: private subnets only, reachable from listed clients only
# ---------------------------------------------------------------------------
resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.name}-subnets"
  subnet_ids = var.subnet_ids
  tags       ={
    Name = var.resource_owner["name"]
    Owner = var.resource_owner["owner"]
  }
}

resource "aws_security_group" "redis" {
  name        = "${var.name}-sg"
  description = "Redis access from authorised clients only"
  vpc_id      = var.vpc_id
  tags       ={
    Name = var.resource_owner["name"]
    Owner = var.resource_owner["owner"]
  }
}

# One rule per client security group (for example the Lambda's). count is used
# instead of for_each because the IDs are not known until apply.
resource "aws_vpc_security_group_ingress_rule" "from_clients" {
  count                        = length(var.allowed_security_group_ids)
  security_group_id            = aws_security_group.redis.id
  referenced_security_group_id = var.allowed_security_group_ids[count.index]
  ip_protocol                  = "tcp"
  from_port                    = var.redis_port
  to_port                      = var.redis_port
  description                  = "Redis from client security group"
}



# ---------------------------------------------------------------------------
# Redis. A replication group (even with one node) is required for TLS and AUTH;
# the plain aws_elasticache_cluster resource cannot enable them for Redis.
# ---------------------------------------------------------------------------
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = var.name
  description          = "Redis cache for the metrics project"

  engine         = "redis"
  engine_version = var.engine_version
  node_type      = var.node_type
  port           = var.redis_port

  num_cache_clusters         = var.num_cache_clusters
  automatic_failover_enabled = var.num_cache_clusters > 1 ? true : false
  multi_az_enabled           = var.num_cache_clusters > 1 ? true : false

  subnet_group_name  = aws_elasticache_subnet_group.redis.name
  security_group_ids = [aws_security_group.redis.id]

  # Security: encrypted at rest and in transit, password required
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = var.auth_token

  # Persistence: Redis snapshots (RDB) taken daily and kept for N days
  snapshot_retention_limit = var.snapshot_retention_days
  snapshot_window          = "02:00-03:00"
  maintenance_window       = "sun:04:00-sun:05:00"

  auto_minor_version_upgrade = true
  apply_immediately          = true

  log_delivery_configuration {
    destination      = var.slow_log_group_name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "slow-log"
  }

  log_delivery_configuration {
    destination      = var.engine_log_group_name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "engine-log"
  }

  tags       ={
    Name = var.resource_owner["name"]
    Owner = var.resource_owner["owner"]
  }
}

