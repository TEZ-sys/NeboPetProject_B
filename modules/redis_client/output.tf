output "security_group_id" {
  value = aws_security_group.client.id
}

output "instance_id" {
  value = aws_instance.client.id
}
