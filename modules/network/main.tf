data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = var.instance_tenancy
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name  = var.resource_owner["name"]
    Owner = var.resource_owner["owner"]
  }
}

# Private subnets, one per CIDR, spread over the first available AZs
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name  = "${var.resource_owner["name"]}-private-${count.index + 1}"
    Owner = var.resource_owner["owner"]
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name  = "${var.resource_owner["name"]}-private-rt"
    Owner = var.resource_owner["owner"]
  }
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Free gateway endpoint: lets resources in the private subnets reach DynamoDB
# without a NAT gateway. It only works once it is attached to a route table.
resource "aws_vpc_endpoint" "dynamodb" {
  count             = var.create_vpc_endpoint ? 1 : 0
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${var.aws_region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]
}

# ---------------------------------------------------------------------------
# Optional public subnet, only for the temporary Redis test client. The host
# has no inbound rules; the subnet just gives it a way out for SSM and apt.
# ---------------------------------------------------------------------------
resource "aws_internet_gateway" "igw" {
  count  = var.create_public_subnet ? 1 : 0
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name  = "${var.resource_owner["name"]}-igw"
    Owner = var.resource_owner["owner"]
  }
}

resource "aws_subnet" "public" {
  count                   = var.create_public_subnet ? 1 : 0
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name  = "${var.resource_owner["name"]}-public"
    Owner = var.resource_owner["owner"]
  }
}

resource "aws_route_table" "public" {
  count  = var.create_public_subnet ? 1 : 0
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw[0].id
  }

  tags = {
    Name  = "${var.resource_owner["name"]}-public-rt"
    Owner = var.resource_owner["owner"]
  }
}

resource "aws_route_table_association" "public" {
  count          = var.create_public_subnet ? 1 : 0
  subnet_id      = aws_subnet.public[0].id
  route_table_id = aws_route_table.public[0].id
}
