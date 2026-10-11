# Network resources for the paris provider.

resource "aws_vpc" "main_paris" {
  provider             = aws.paris
  cidr_block           = var.paris_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.paris_name}-vpc"
  }

  lifecycle {
    precondition {
      condition     = length(data.aws_availability_zones.available_paris.names) >= max(length(var.paris_public_subnets_cidr), length(var.paris_private_subnets_cidr))
      error_message = "Subnet counts must not exceed the number of available standard availability zones in this region."
    }
  }
}

resource "aws_subnet" "public_paris" {
  provider = aws.paris
  count    = length(var.paris_public_subnets_cidr)

  vpc_id                  = aws_vpc.main_paris.id
  cidr_block              = var.paris_public_subnets_cidr[count.index]
  availability_zone       = data.aws_availability_zones.available_paris.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.paris_name}-public-${count.index + 1}"
    Tier = "public"
  }
}

resource "aws_subnet" "private_paris" {
  provider = aws.paris
  count    = length(var.paris_private_subnets_cidr)

  vpc_id                  = aws_vpc.main_paris.id
  cidr_block              = var.paris_private_subnets_cidr[count.index]
  availability_zone       = data.aws_availability_zones.available_paris.names[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.paris_name}-private-${count.index + 1}"
    Tier = "private"
  }
}

resource "aws_internet_gateway" "main_paris" {
  provider = aws.paris
  vpc_id   = aws_vpc.main_paris.id

  tags = {
    Name = "${local.paris_name}-igw"
  }
}

resource "aws_route_table" "public_paris" {
  provider = aws.paris
  vpc_id   = aws_vpc.main_paris.id

  tags = {
    Name = "${local.paris_name}-public-rt"
  }
}

resource "aws_route" "public_internet_paris" {
  provider               = aws.paris
  route_table_id         = aws_route_table.public_paris.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main_paris.id
}

resource "aws_route_table_association" "public_paris" {
  provider = aws.paris
  count    = length(var.paris_public_subnets_cidr)

  subnet_id      = aws_subnet.public_paris[count.index].id
  route_table_id = aws_route_table.public_paris.id
}

resource "aws_eip" "nat_paris" {
  provider = aws.paris
  count    = var.enable_nat_gateway ? 1 : 0
  domain   = "vpc"

  tags = {
    Name = "${local.paris_name}-nat-eip"
  }
}

resource "aws_nat_gateway" "main_paris" {
  provider = aws.paris
  count    = var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat_paris[0].id
  subnet_id     = aws_subnet.public_paris[0].id

  depends_on = [
    aws_internet_gateway.main_paris,
    aws_route.public_internet_paris,
    aws_route_table_association.public_paris,
  ]

  tags = {
    Name = "${local.paris_name}-nat"
  }
}

resource "aws_route_table" "private_paris" {
  provider = aws.paris
  vpc_id   = aws_vpc.main_paris.id

  tags = {
    Name = "${local.paris_name}-private-rt"
  }
}

resource "aws_route" "private_internet_paris" {
  provider = aws.paris
  count    = var.enable_nat_gateway ? 1 : 0

  route_table_id         = aws_route_table.private_paris.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main_paris[0].id
}

resource "aws_route_table_association" "private_paris" {
  provider = aws.paris
  count    = length(var.paris_private_subnets_cidr)

  subnet_id      = aws_subnet.private_paris[count.index].id
  route_table_id = aws_route_table.private_paris.id
}
