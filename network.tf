# ALB
resource "aws_alb" "vault_alb" {
  count = var.num_of_site
  name = "vault-alb-${count.index}"
  internal = false
  subnets = aws_subnet.public.*.id[count.index]
  security_groups = [aws_security_group.vault_security_group.id]
}

resource "aws_alb_target_group" "vault_tg" {
  count = var.num_of_site
  name = "vault-tg-${count.index}"
  port = 8200
  protocol = "HTTPS"
  vpc_id = aws_vpc.playground.id

  health_check {
    protocol = "HTTPS"
  }
}

resource "aws_alb_target_group_attachment" "alb_attach_tg_vault" {
  count = var.vault_instance_count
  target_group_arn = aws_alb_target_group.vault_tg[count.index].arn
  target_id = aws_instance.vault_ec2.*.id[count.index]
  port = 8200
}

resource "aws_alb_listener" "https_vault" {
  count = var.num_of_site
  load_balancer_arn = aws_alb.vault_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.cert.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.vault_tg[count.index].arn
  }
}

# ACM
resource aws_acm_certificate cert {
  domain_name       = var.domain
  validation_method = "DNS"
}


# VPC
resource "aws_vpc" "playground" {
  cidr_block = var.vpc_cidr
  instance_tenancy = "default"
  enable_dns_support = "true"
  enable_dns_hostnames = "true"
}

# Public Subnet
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
resource "aws_eip" "vault_eip" {
  count = var.num_of_site
  instance = aws_instance.vault_ec2.*.id[count.index]
  vpc = true
  tags = merge(var.tags, map("Name", "kabu_vault_eip"))
}

# NatGateway
resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.playground.id

}

# RouteTable
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.playground.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "public"
  }
}

# SubnetRouteTableAssociation
resource "aws_route_table_association" "public" {
  count = length(var.subnets_cidr)
  subnet_id = aws_subnet.public.*.id[0]
  route_table_id = aws_route_table.public.id
}

# NatGateway
resource "aws_nat_gateway" "nat" {
  count = 1
  subnet_id = aws_subnet.public.*.id[0]
  allocation_id = aws_eip.nat.id
}

# SG
resource "aws_security_group" "vault_security_group" {
  name = "vault_security_group"
  description = "Vault Sercuriy Group"
  vpc_id = aws_vpc.playground.id

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