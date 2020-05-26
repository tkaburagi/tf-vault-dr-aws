# VPC
resource "aws_vpc" "playground" {
  count = var.num_of_site
  cidr_block = var.vpc_cidr[count.index]
  instance_tenancy = "default"
  enable_dns_support = "true"
  enable_dns_hostnames = "true"
}

#  Public Subnet
resource "aws_subnet" "public" {
  vpc_id = aws_vpc.playground.id
  count = length(var.availability_zones)
  cidr_block = var.subnets_cidr[count.index]
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "${var.public_subnet_name}-${count.index}"
  }
}

# EIP
resource "aws_eip" "vault_eip_dr_1" {
  count = var.num_of_site
  instance = aws_instance.vault_ec2.*.id[count.index]
  vpc = true
  tags = merge(var.tags, map("Name", "kabu_vault_eip"))
}

# SG
resource "aws_security_group" "vault_security_group" {
  name = "vault_security_group"
  description = "Vault Sercuriy Group"
  vpc_id = aws_vpc.playground.*.id

  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks     = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks     = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks     = ["0.0.0.0/0"]
  }

  ingress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 8200
    to_port = 8200
  }

  ingress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 8201
    to_port = 8201
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol = "-1"
    from_port = 0
    to_port = 0
  }
}