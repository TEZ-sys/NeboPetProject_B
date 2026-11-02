output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "subnet_ids" {
  value = aws_subnet.private[*].id
}

output "route_table_id" {
  value = aws_route_table.private.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}
