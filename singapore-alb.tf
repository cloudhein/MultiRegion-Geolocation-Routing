# Internet-facing ALB for singapore: HTTP and HTTPS -> application HTTP.
resource "aws_security_group" "alb_singapore" {
  provider    = aws.singapore
  name        = "${local.singapore_name}-alb-sg"
  description = "Public HTTP and HTTPS access"
  vpc_id      = aws_vpc.main_singapore.id

  tags = { Name = "${local.singapore_name}-alb-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http_singapore" {
  provider          = aws.singapore
  security_group_id = aws_security_group.alb_singapore.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "alb_https_singapore" {
  provider          = aws.singapore
  security_group_id = aws_security_group.alb_singapore.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "alb_all_singapore" {
  provider          = aws.singapore
  security_group_id = aws_security_group.alb_singapore.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_lb" "singapore" {
  provider           = aws.singapore
  name               = substr("${local.singapore_name}-alb", 0, 32)
  internal           = false
  load_balancer_type = "application"
  ip_address_type    = "ipv4"
  security_groups    = [aws_security_group.alb_singapore.id]
  subnets            = aws_subnet.public_singapore[*].id

  depends_on = [aws_route.public_internet_singapore, aws_route_table_association.public_singapore]

  tags = { Name = "${local.singapore_name}-alb" }
}

resource "aws_lb_target_group" "singapore" {
  provider    = aws.singapore
  name        = substr("${local.singapore_name}-tg", 0, 32)
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main_singapore.id

  # All other health-check settings use the AWS provider defaults.
  health_check {
    path = "/health.txt"
  }

  tags = { Name = "${local.singapore_name}-tg" }
}

resource "aws_lb_target_group_attachment" "singapore" {
  count            = var.singapore_app_instance_count
  provider         = aws.singapore
  target_group_arn = aws_lb_target_group.singapore.arn
  target_id        = aws_instance.app_singapore[count.index].id
  port             = 80
}

resource "aws_lb_listener" "http_singapore" {
  provider          = aws.singapore
  load_balancer_arn = aws_lb.singapore.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.singapore.arn
  }
}

resource "aws_lb_listener" "https_singapore" {
  count             = var.singapore_certificate_arn != null ? 1 : 0
  provider          = aws.singapore
  load_balancer_arn = aws_lb.singapore.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = var.singapore_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.singapore.arn
  }
}
