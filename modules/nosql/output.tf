output "dynamo_metric_arn" {
  value = "${aws_dynamodb_table.metrics.arn}"
}

output "dynamo_table_name" {
  value = "${aws_dynamodb_table.metrics.name}"
}