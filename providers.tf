provider "aws" {
  alias  = "singapore"
  region = var.singapore_region

  profile = var.aws_auth_profile

  default_tags {
    tags = local.common_tags
  }
}

provider "aws" {
  alias  = "usa"
  region = var.usa_region

  profile = var.aws_auth_profile

  default_tags {
    tags = local.common_tags
  }
}

provider "aws" {
  alias  = "paris"
  region = var.paris_region

  profile = var.aws_auth_profile

  default_tags {
    tags = local.common_tags
  }
}
