# Ubuntu application and public jump host for singapore.
data "aws_ami" "ubuntu_singapore" {
  provider    = aws.singapore
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = [var.ubuntu_ami_name]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_key_pair" "singapore" {
  provider   = aws.singapore
  key_name   = "${local.singapore_name}-key"
  public_key = file(pathexpand(var.ssh_public_key_path))
}

resource "aws_security_group" "jump_singapore" {
  provider    = aws.singapore
  name        = "${local.singapore_name}-jump-sg"
  description = "Public SSH access to the jump host"
  vpc_id      = aws_vpc.main_singapore.id

  tags = { Name = "${local.singapore_name}-jump-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "jump_ssh_singapore" {
  provider          = aws.singapore
  security_group_id = aws_security_group.jump_singapore.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "jump_all_singapore" {
  provider          = aws.singapore
  security_group_id = aws_security_group.jump_singapore.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "app_singapore" {
  provider    = aws.singapore
  name        = "${local.singapore_name}-app-sg"
  description = "HTTP from ALB and SSH from jump host only"
  vpc_id      = aws_vpc.main_singapore.id

  tags = { Name = "${local.singapore_name}-app-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "app_http_singapore" {
  provider                     = aws.singapore
  security_group_id            = aws_security_group.app_singapore.id
  referenced_security_group_id = aws_security_group.alb_singapore.id
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
}

resource "aws_vpc_security_group_ingress_rule" "app_ssh_singapore" {
  provider                     = aws.singapore
  security_group_id            = aws_security_group.app_singapore.id
  referenced_security_group_id = aws_security_group.jump_singapore.id
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
}

resource "aws_vpc_security_group_egress_rule" "app_all_singapore" {
  provider          = aws.singapore
  security_group_id = aws_security_group.app_singapore.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_instance" "jump_singapore" {
  provider                    = aws.singapore
  ami                         = data.aws_ami.ubuntu_singapore.id
  instance_type               = var.jump_instance_type
  subnet_id                   = aws_subnet.public_singapore[0].id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.jump_singapore.id]
  key_name                    = aws_key_pair.singapore.key_name

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_type = "gp3"
    encrypted   = true
  }

  depends_on = [aws_route.public_internet_singapore, aws_route_table_association.public_singapore]

  tags = {
    Name = "${local.singapore_name}-jump"
    Tier = "management"
  }
}

resource "aws_instance" "app_singapore" {
  provider                    = aws.singapore
  count                       = var.singapore_app_instance_count
  ami                         = data.aws_ami.ubuntu_singapore.id
  instance_type               = var.app_instance_type
  subnet_id                   = aws_subnet.private_singapore[count.index % length(var.singapore_private_subnets_cidr)].id
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.app_singapore.id]
  key_name                    = aws_key_pair.singapore.key_name
  user_data                   = templatefile("${path.module}/templates/singapore-user-data.sh.tftpl", {})
  user_data_replace_on_change = true

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = var.app_root_volume_size
    encrypted   = true
  }

  # Package installation and Docker image pulls require the private NAT route.
  depends_on = [
    aws_route.private_internet_singapore,
    aws_route_table_association.private_singapore,
    aws_vpc_security_group_egress_rule.app_all_singapore,
  ]

  lifecycle {
    precondition {
      condition     = var.enable_nat_gateway
      error_message = "Keep enable_nat_gateway=true: the private application needs internet access to install Docker and pull its image."
    }
  }

  tags = {
    Name = "${local.singapore_name}-app-${count.index + 1}"
    Tier = "application"
  }
}
