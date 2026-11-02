output "lambda_function_name" {
  value = module.lambda.function_name
}

output "dynamodb_table_name" {
  value = module.nosql.dynamo_table_name
}

output "dead_letter_queue_url" {
  value = module.lambda.dlq_url
}

output "redis_endpoint" {
  value = module.elastic_cache.primary_endpoint_address
}

output "redis_security_group_id" {
  value = module.elastic_cache.security_group_id
}

output "redis_connection_string_template" {
  value = module.elastic_cache.connection_string_template
}

output "redis_test_client_instance_id" {
  value = length(module.redis_client) > 0 ? module.redis_client[0].instance_id : null
}
