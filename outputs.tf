output "regional_vpcs" {
  description = "VPCs, subnets, routing resources, and optional NAT gateways keyed by regional label."
  value = {
    singapore = {
      region                 = var.singapore_region
      vpc_id                 = aws_vpc.main_singapore.id
      vpc_cidr               = aws_vpc.main_singapore.cidr_block
      availability_zones     = aws_subnet.public_singapore[*].availability_zone
      public_subnet_ids      = aws_subnet.public_singapore[*].id
      private_subnet_ids     = aws_subnet.private_singapore[*].id
      public_subnet_cidrs    = aws_subnet.public_singapore[*].cidr_block
      private_subnet_cidrs   = aws_subnet.private_singapore[*].cidr_block
      internet_gateway_id    = aws_internet_gateway.main_singapore.id
      public_route_table_id  = aws_route_table.public_singapore.id
      private_route_table_id = aws_route_table.private_singapore.id
      nat_gateway_id         = one(aws_nat_gateway.main_singapore[*].id)
      nat_public_ip          = one(aws_eip.nat_singapore[*].public_ip)
    }
    usa = {
      region                 = var.usa_region
      vpc_id                 = aws_vpc.main_usa.id
      vpc_cidr               = aws_vpc.main_usa.cidr_block
      availability_zones     = aws_subnet.public_usa[*].availability_zone
      public_subnet_ids      = aws_subnet.public_usa[*].id
      private_subnet_ids     = aws_subnet.private_usa[*].id
      public_subnet_cidrs    = aws_subnet.public_usa[*].cidr_block
      private_subnet_cidrs   = aws_subnet.private_usa[*].cidr_block
      internet_gateway_id    = aws_internet_gateway.main_usa.id
      public_route_table_id  = aws_route_table.public_usa.id
      private_route_table_id = aws_route_table.private_usa.id
      nat_gateway_id         = one(aws_nat_gateway.main_usa[*].id)
      nat_public_ip          = one(aws_eip.nat_usa[*].public_ip)
    }
    paris = {
      region                 = var.paris_region
      vpc_id                 = aws_vpc.main_paris.id
      vpc_cidr               = aws_vpc.main_paris.cidr_block
      availability_zones     = aws_subnet.public_paris[*].availability_zone
      public_subnet_ids      = aws_subnet.public_paris[*].id
      private_subnet_ids     = aws_subnet.private_paris[*].id
      public_subnet_cidrs    = aws_subnet.public_paris[*].cidr_block
      private_subnet_cidrs   = aws_subnet.private_paris[*].cidr_block
      internet_gateway_id    = aws_internet_gateway.main_paris.id
      public_route_table_id  = aws_route_table.public_paris.id
      private_route_table_id = aws_route_table.private_paris.id
      nat_gateway_id         = one(aws_nat_gateway.main_paris[*].id)
      nat_public_ip          = one(aws_eip.nat_paris[*].public_ip)
    }
  }
}

output "vpc_ids" {
  description = "VPC IDs keyed by regional label."
  value = {
    singapore = aws_vpc.main_singapore.id
    usa       = aws_vpc.main_usa.id
    paris     = aws_vpc.main_paris.id
  }
}

output "regional_applications" {
  description = "ALB alias targets, app private addresses, and jump host access for each region."
  value = {
    singapore = {
      alb_dns_name           = aws_lb.singapore.dns_name
      alb_zone_id            = aws_lb.singapore.zone_id
      alb_arn                = aws_lb.singapore.arn
      target_group_arn       = aws_lb_target_group.singapore.arn
      app_instance_ids       = aws_instance.app_singapore[*].id
      app_private_ips        = aws_instance.app_singapore[*].private_ip
      app_availability_zones = aws_instance.app_singapore[*].availability_zone
      jump_public_ip         = aws_instance.jump_singapore.public_ip
      ubuntu_ami_id          = data.aws_ami.ubuntu_singapore.id
      ssh_key_name           = aws_key_pair.singapore.key_name
    }
    usa = {
      alb_dns_name           = aws_lb.usa.dns_name
      alb_zone_id            = aws_lb.usa.zone_id
      alb_arn                = aws_lb.usa.arn
      target_group_arn       = aws_lb_target_group.usa.arn
      app_instance_ids       = aws_instance.app_usa[*].id
      app_private_ips        = aws_instance.app_usa[*].private_ip
      app_availability_zones = aws_instance.app_usa[*].availability_zone
      jump_public_ip         = aws_instance.jump_usa.public_ip
      ubuntu_ami_id          = data.aws_ami.ubuntu_usa.id
      ssh_key_name           = aws_key_pair.usa.key_name
    }
    paris = {
      alb_dns_name           = aws_lb.paris.dns_name
      alb_zone_id            = aws_lb.paris.zone_id
      alb_arn                = aws_lb.paris.arn
      target_group_arn       = aws_lb_target_group.paris.arn
      app_instance_ids       = aws_instance.app_paris[*].id
      app_private_ips        = aws_instance.app_paris[*].private_ip
      app_availability_zones = aws_instance.app_paris[*].availability_zone
      jump_public_ip         = aws_instance.jump_paris.public_ip
      ubuntu_ami_id          = data.aws_ami.ubuntu_paris.id
      ssh_key_name           = aws_key_pair.paris.key_name
    }
  }
}
