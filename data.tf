# Available zones in singapore.
data "aws_availability_zones" "available_singapore" {
  provider = aws.singapore
  state    = "available"

  filter {
    name   = "zone-type"
    values = ["availability-zone"]
  }
}

# Available zones in usa.
data "aws_availability_zones" "available_usa" {
  provider = aws.usa
  state    = "available"

  filter {
    name   = "zone-type"
    values = ["availability-zone"]
  }
}

# Available zones in paris.
data "aws_availability_zones" "available_paris" {
  provider = aws.paris
  state    = "available"

  filter {
    name   = "zone-type"
    values = ["availability-zone"]
  }
}

