output "slow_log_group_name" {
  value = aws_cloudwatch_log_group.slow.name
}

output "engine_log_group_name" {
  value = aws_cloudwatch_log_group.engine.name
}
