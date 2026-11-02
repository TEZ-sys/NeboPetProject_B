variable "name" {
  description = "Name prefix for the test client resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC of the Redis cache"
  type        = string
}

variable "subnet_id" {
  description = "Subnet for the test host (needs a route to the internet for SSM and apt)"
  type        = string
}

variable "redis_host" {
  description = "Redis primary endpoint address"
  type        = string
}

variable "redis_port" {
  description = "Redis port"
  type        = number
}

variable "instance_type" {
  description = "Instance size of the test host"
  type        = string
  default     = "t3.micro"
}

variable "resource_owner" {
  description = "Name and owner tags"
  type        = map(string)
}
