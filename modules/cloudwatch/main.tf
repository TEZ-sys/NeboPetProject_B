# ---------------------------------------------------------------------------
# Logs for the Redis cache (created first, the cache writes into them)
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "slow" {
  name              = "/elasticache/${var.name}/slow-log"
  retention_in_days = var.log_retention_days

  tags = {
    Name  = var.resource_owner["name"]
    Owner = var.resource_owner["owner"]
  }
}

resource "aws_cloudwatch_log_group" "engine" {
  name              = "/elasticache/${var.name}/engine-log"
  retention_in_days = var.log_retention_days

  tags = {
    Name  = var.resource_owner["name"]
    Owner = var.resource_owner["owner"]
  }
}

# ---------------------------------------------------------------------------
# Alarms (ElastiCache publishes the metrics itself; these add alerting).
# One alarm per node, so a failover to a replica is still covered.
# Node ids are "<replication group id>-001", "-002", ...
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "memory" {
  count               = var.num_cache_clusters
  alarm_name          = "${var.name}-${format("%03d", count.index + 1)}-memory-high"
  alarm_description   = "Redis memory usage above 80 percent"
  namespace           = "AWS/ElastiCache"
  metric_name         = "DatabaseMemoryUsagePercentage"
  dimensions          = { CacheClusterId = "${var.name}-${format("%03d", count.index + 1)}" }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  tags = {
    Name  = var.resource_owner["name"]
    Owner = var.resource_owner["owner"]
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu" {
  count               = var.num_cache_clusters
  alarm_name          = "${var.name}-${format("%03d", count.index + 1)}-engine-cpu-high"
  alarm_description   = "Redis engine CPU above 80 percent"
  namespace           = "AWS/ElastiCache"
  metric_name         = "EngineCPUUtilization"
  dimensions          = { CacheClusterId = "${var.name}-${format("%03d", count.index + 1)}" }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  tags = {
    Name  = var.resource_owner["name"]
    Owner = var.resource_owner["owner"]
  }
}
