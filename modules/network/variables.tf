variable "create_vpc_endpoint" {
  description = "Create a DynamoDB gateway endpoint (needed for Lambdas in a VPC without NAT)"
  type        = bool
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "instance_tenancy" {
  description = "The tenancy of the instance"
  type        = string
}
variable "resource_owner" {
  description = "resource_owner variables for the Lambda function"
  type        = map(string)
}
variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
}

variable "private_subnet_cidrs" {
  description = "CIDRs of the private subnets, one per availability zone (use at least two for a Multi-AZ cache)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "create_public_subnet" {
  description = "Create an internet gateway and a public subnet (used only by the Redis test client)"
  type        = bool
  default     = false
}

variable "public_subnet_cidr" {
  description = "CIDR of the optional public subnet"
  type        = string
  default     = "10.0.10.0/24"
}
