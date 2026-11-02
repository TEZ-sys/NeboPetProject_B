output "function_name" {
  value = aws_lambda_function.lambda_function.function_name
}

output "function_arn" {
  value = aws_lambda_function.lambda_function.arn
}

output "dlq_arn" {
  value = aws_sqs_queue.dlq.arn
}

output "dlq_url" {
  value = aws_sqs_queue.dlq.url
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.lambda.name
}
