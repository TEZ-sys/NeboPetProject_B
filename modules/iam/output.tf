output "collector_role_arn" {
  value = aws_iam_role.collector.arn
}

output "collector_role_name" {
  value = aws_iam_role.collector.name
}

output "reader_role_arn" {
  value = aws_iam_role.reader.arn
}
