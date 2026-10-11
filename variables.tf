variable "aws_auth_profile" {
  type        = string
  description = "AWS profile to use for authentication"
  default     = "admin-master-harry-console"
}

variable "project_name" {
  description = "Prefix for resource names and the Project tag."
  type        = string
  default     = "geo-routing"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,39}$", var.project_name))
    error_message = "Use a lowercase project name starting with a letter, up to 40 characters."
  }
}

variable "singapore_region" {
  description = "AWS region for the singapore infrastructure."
  type        = string
  default     = "ap-southeast-1"
}

variable "singapore_vpc_cidr" {
  description = "VPC CIDR for singapore; keep its subnet CIDRs inside this network."
  type        = string
  default     = "10.10.0.0/16"
}

variable "usa_region" {
  description = "AWS region for the usa infrastructure."
  type        = string
  default     = "us-east-1"
}

variable "usa_vpc_cidr" {
  description = "VPC CIDR for usa; keep its subnet CIDRs inside this network."
  type        = string
  default     = "10.20.0.0/16"
}

variable "paris_region" {
  description = "AWS region for the paris infrastructure."
  type        = string
  default     = "eu-west-3"
}

variable "paris_vpc_cidr" {
  description = "VPC CIDR for paris; keep its subnet CIDRs inside this network."
  type        = string
  default     = "10.30.0.0/16"
}

variable "enable_nat_gateway" {
  description = "Create one NAT gateway per region for private subnet internet access. Disable for a public-only demo."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags applied to all regional AWS resources."
  type        = map(string)
  default = {
    Environment = "demo"
  }
}

variable "singapore_public_subnets_cidr" {
  description = "Public subnet CIDRs inside the singapore VPC; one subnet per availability zone."
  type        = list(string)
  default     = ["10.10.1.0/24", "10.10.2.0/24"]

  validation {
    condition     = length(var.singapore_public_subnets_cidr) >= 2
    error_message = "Provide at least 2 public subnet CIDRs."
  }
}

variable "singapore_private_subnets_cidr" {
  description = "Private subnet CIDRs inside the singapore VPC; one subnet per availability zone."
  type        = list(string)
  default     = ["10.10.11.0/24", "10.10.12.0/24"]

  validation {
    condition     = length(var.singapore_private_subnets_cidr) >= 1
    error_message = "Provide at least 1 private subnet CIDRs."
  }
}

variable "usa_public_subnets_cidr" {
  description = "Public subnet CIDRs inside the usa VPC; one subnet per availability zone."
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24"]

  validation {
    condition     = length(var.usa_public_subnets_cidr) >= 2
    error_message = "Provide at least 2 public subnet CIDRs."
  }
}

variable "usa_private_subnets_cidr" {
  description = "Private subnet CIDRs inside the usa VPC; one subnet per availability zone."
  type        = list(string)
  default     = ["10.20.11.0/24", "10.20.12.0/24"]

  validation {
    condition     = length(var.usa_private_subnets_cidr) >= 1
    error_message = "Provide at least 1 private subnet CIDRs."
  }
}

variable "paris_public_subnets_cidr" {
  description = "Public subnet CIDRs inside the paris VPC; one subnet per availability zone."
  type        = list(string)
  default     = ["10.30.1.0/24", "10.30.2.0/24"]

  validation {
    condition     = length(var.paris_public_subnets_cidr) >= 2
    error_message = "Provide at least 2 public subnet CIDRs."
  }
}

variable "paris_private_subnets_cidr" {
  description = "Private subnet CIDRs inside the paris VPC; one subnet per availability zone."
  type        = list(string)
  default     = ["10.30.11.0/24", "10.30.12.0/24"]

  validation {
    condition     = length(var.paris_private_subnets_cidr) >= 1
    error_message = "Provide at least 1 private subnet CIDRs."
  }
}

# Application settings shared by all three regions.
variable "ubuntu_ami_name" {
  description = "Canonical Ubuntu 26.04 LTS AMD64 AMI name pattern, matching the previous project's OS."
  type        = string
  default     = "ubuntu/images/hvm-ssd-gp3/ubuntu-resolute-26.04-amd64-server-*"
}

variable "app_instance_type" {
  description = "AMD64 instance type for each private application server."
  type        = string
  default     = "t3.micro"
}

variable "jump_instance_type" {
  description = "AMD64 instance type for each public jump host."
  type        = string
  default     = "t3.micro"
}

variable "ssh_public_key_path" {
  description = "Path to an existing SSH public key; its private key stays on your computer."
  type        = string
  default     = "/Users/htetnandahein/.ssh/harry-ssh-key.pub"
}

variable "singapore_certificate_arn" {
  description = "Optional issued certificate ARN in the singapore ALB region. Leave null to deploy HTTP only."
  type        = string
  default     = null
}

variable "usa_certificate_arn" {
  description = "Optional issued certificate ARN in the usa ALB region. Leave null to deploy HTTP only."
  type        = string
  default     = null
}

variable "paris_certificate_arn" {
  description = "Optional issued certificate ARN in the paris ALB region. Leave null to deploy HTTP only."
  type        = string
  default     = null
}

variable "singapore_app_instance_count" {
  description = "Number of application instances in singapore; distributed across private subnets."
  type        = number
  default     = 1

  validation {
    condition     = var.singapore_app_instance_count >= 1 && floor(var.singapore_app_instance_count) == var.singapore_app_instance_count
    error_message = "Application instance count must be a positive whole number."
  }
}

variable "usa_app_instance_count" {
  description = "Number of application instances in usa; distributed across private subnets."
  type        = number
  default     = 1

  validation {
    condition     = var.usa_app_instance_count >= 1 && floor(var.usa_app_instance_count) == var.usa_app_instance_count
    error_message = "Application instance count must be a positive whole number."
  }
}

variable "paris_app_instance_count" {
  description = "Number of application instances in paris; distributed across private subnets."
  type        = number
  default     = 1

  validation {
    condition     = var.paris_app_instance_count >= 1 && floor(var.paris_app_instance_count) == var.paris_app_instance_count
    error_message = "Application instance count must be a positive whole number."
  }
}

variable "app_root_volume_size" {
  description = "Root disk size in GiB for application instances in all regions; must fit the selected AMI."
  type        = number
  default     = 8

  validation {
    condition     = var.app_root_volume_size >= 8 && floor(var.app_root_volume_size) == var.app_root_volume_size
    error_message = "Application root volume size must be a whole number of at least 8 GiB."
  }
}
