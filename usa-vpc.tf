# Network resources for the usa provider.

resource "aws_vpc" "main_usa" {
  provider             = aws.usa
  cidr_block           = var.usa_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.usa_name}-vpc"
  }

  lifecycle {
    precondition {
      condition     = length(data.aws_availability_zones.available_usa.names) >= max(length(var.usa_public_subnets_cidr), length(var.usa_private_subnets_cidr))
      error_message = "Subnet counts must not exceed the number of available standard availability zones in this region."
    }
  }
}

resource "aws_subnet" "public_usa" {
  provider = aws.usa
  count    = length(var.usa_public_subnets_cidr)

  vpc_id                  = aws_vpc.main_usa.id
  cidr_block              = var.usa_public_subnets_cidr[count.index]
  availability_zone       = data.aws_availability_zones.available_usa.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.usa_name}-public-${count.index + 1}"
    Tier = "public"
  }
}

resource "aws_subnet" "private_usa" {
  provider = aws.usa
  count    = length(var.usa_private_subnets_cidr)

  vpc_id                  = aws_vpc.main_usa.id
  cidr_block              = var.usa_private_subnets_cidr[count.index]
  availability_zone       = data.aws_availability_zones.available_usa.names[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.usa_name}-private-${count.index + 1}"
    Tier = "private"
  }
}

resource "aws_internet_gateway" "main_usa" {
  provider = aws.usa
  vpc_id   = aws_vpc.main_usa.id

  tags = {
    Name = "${local.usa_name}-igw"
  }
}

resource "aws_route_table" "public_usa" {
  provider = aws.usa
  vpc_id   = aws_vpc.main_usa.id

  tags = {
    Name = "${local.usa_name}-public-rt"
  }
}

resource "aws_route" "public_internet_usa" {
  provider               = aws.usa
  route_table_id         = aws_route_table.public_usa.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main_usa.id
}

resource "aws_route_table_association" "public_usa" {
  provider = aws.usa
  count    = length(var.usa_public_subnets_cidr)

  subnet_id      = aws_subnet.public_usa[count.index].id
  route_table_id = aws_route_table.public_usa.id
}

resource "aws_eip" "nat_usa" {
  provider = aws.usa
  count    = var.enable_nat_gateway ? 1 : 0
  domain   = "vpc"

  tags = {
    Name = "${local.usa_name}-nat-eip"
  }
}

resource "aws_nat_gateway" "main_usa" {
  provider = aws.usa
  count    = var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat_usa[0].id
  subnet_id     = aws_subnet.public_usa[0].id

  depends_on = [
    aws_internet_gateway.main_usa,
    aws_route.public_internet_usa,
    aws_route_table_association.public_usa,
  ]

  tags = {
    Name = "${local.usa_name}-nat"
  }
}

resource "aws_route_table" "private_usa" {
  provider = aws.usa
  vpc_id   = aws_vpc.main_usa.id

  tags = {
    Name = "${local.usa_name}-private-rt"
  }
}

resource "aws_route" "private_internet_usa" {
  provider = aws.usa
  count    = var.enable_nat_gateway ? 1 : 0

  route_table_id         = aws_route_table.private_usa.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main_usa[0].id
}

resource "aws_route_table_association" "private_usa" {
  provider = aws.usa
  count    = length(var.usa_private_subnets_cidr)

  subnet_id      = aws_subnet.private_usa[count.index].id
  route_table_id = aws_route_table.private_usa.id
}
