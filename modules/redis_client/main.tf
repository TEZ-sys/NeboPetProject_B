locals {
  tags = {
    Name  = "${var.name}-test-client"
    Owner = var.resource_owner["owner"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# Access is through SSM Session Manager only: no key pair, no inbound ports.
data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "client" {
  name               = "${var.name}-test-client-role"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.client.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "client" {
  name = "${var.name}-test-client-profile"
  role = aws_iam_role.client.name
}

# No ingress rules at all. Egress is open so the SSM agent and apt can work;
# this group is also what the Redis security group allows in.
resource "aws_security_group" "client" {
  name        = "${var.name}-test-client-sg"
  description = "Redis test client: no inbound, outbound for SSM and package install"
  vpc_id      = var.vpc_id

  egress {
    description = "Outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_instance" "client" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.client.id]
  iam_instance_profile        = aws_iam_instance_profile.client.name
  associate_public_ip_address = true # outbound only, nothing listens

  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    redis_host = var.redis_host
    redis_port = var.redis_port
  })

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    encrypted   = true
    volume_size = 8
  }

  tags = local.tags
}
