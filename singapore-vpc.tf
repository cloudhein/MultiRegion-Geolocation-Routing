# Network resources for the singapore provider.

resource "aws_vpc" "main_singapore" {
  provider             = aws.singapore
  cidr_block           = var.singapore_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.singapore_name}-vpc"
  }

  lifecycle {
    precondition {
      condition     = length(data.aws_availability_zones.available_singapore.names) >= max(length(var.singapore_public_subnets_cidr), length(var.singapore_private_subnets_cidr))
      error_message = "Subnet counts must not exceed the number of available standard availability zones in this region."
    }
  }
}

resource "aws_subnet" "public_singapore" {
  provider = aws.singapore
  count    = length(var.singapore_public_subnets_cidr)

  vpc_id                  = aws_vpc.main_singapore.id
  cidr_block              = var.singapore_public_subnets_cidr[count.index]
  availability_zone       = data.aws_availability_zones.available_singapore.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.singapore_name}-public-${count.index + 1}"
    Tier = "public"
  }
}

resource "aws_subnet" "private_singapore" {
  provider = aws.singapore
  count    = length(var.singapore_private_subnets_cidr)

  vpc_id                  = aws_vpc.main_singapore.id
  cidr_block              = var.singapore_private_subnets_cidr[count.index]
  availability_zone       = data.aws_availability_zones.available_singapore.names[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.singapore_name}-private-${count.index + 1}"
    Tier = "private"
  }
}

resource "aws_internet_gateway" "main_singapore" {
  provider = aws.singapore
  vpc_id   = aws_vpc.main_singapore.id

  tags = {
    Name = "${local.singapore_name}-igw"
  }
}

resource "aws_route_table" "public_singapore" {
  provider = aws.singapore
  vpc_id   = aws_vpc.main_singapore.id

  tags = {
    Name = "${local.singapore_name}-public-rt"
  }
}

resource "aws_route" "public_internet_singapore" {
  provider               = aws.singapore
  route_table_id         = aws_route_table.public_singapore.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main_singapore.id
}

resource "aws_route_table_association" "public_singapore" {
  provider = aws.singapore
  count    = length(var.singapore_public_subnets_cidr)

  subnet_id      = aws_subnet.public_singapore[count.index].id
  route_table_id = aws_route_table.public_singapore.id
}

resource "aws_eip" "nat_singapore" {
  provider = aws.singapore
  count    = var.enable_nat_gateway ? 1 : 0
  domain   = "vpc"

  tags = {
    Name = "${local.singapore_name}-nat-eip"
  }
}

resource "aws_nat_gateway" "main_singapore" {
  provider = aws.singapore
  count    = var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat_singapore[0].id
  subnet_id     = aws_subnet.public_singapore[0].id

  depends_on = [
    aws_internet_gateway.main_singapore,
    aws_route.public_internet_singapore,
    aws_route_table_association.public_singapore,
  ]

  tags = {
    Name = "${local.singapore_name}-nat"
  }
}

resource "aws_route_table" "private_singapore" {
  provider = aws.singapore
  vpc_id   = aws_vpc.main_singapore.id

  tags = {
    Name = "${local.singapore_name}-private-rt"
  }
}

resource "aws_route" "private_internet_singapore" {
  provider = aws.singapore
  count    = var.enable_nat_gateway ? 1 : 0

  route_table_id         = aws_route_table.private_singapore.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main_singapore[0].id
}

resource "aws_route_table_association" "private_singapore" {
  provider = aws.singapore
  count    = length(var.singapore_private_subnets_cidr)

  subnet_id      = aws_subnet.private_singapore[count.index].id
  route_table_id = aws_route_table.private_singapore.id
}
