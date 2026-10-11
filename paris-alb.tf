# Internet-facing ALB for paris: HTTP and HTTPS -> application HTTP.
resource "aws_security_group" "alb_paris" {
  provider    = aws.paris
  name        = "${local.paris_name}-alb-sg"
  description = "Public HTTP and HTTPS access"
  vpc_id      = aws_vpc.main_paris.id

  tags = { Name = "${local.paris_name}-alb-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http_paris" {
  provider          = aws.paris
  security_group_id = aws_security_group.alb_paris.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "alb_https_paris" {
  provider          = aws.paris
  security_group_id = aws_security_group.alb_paris.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "alb_all_paris" {
  provider          = aws.paris
  security_group_id = aws_security_group.alb_paris.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_lb" "paris" {
  provider           = aws.paris
  name               = substr("${local.paris_name}-alb", 0, 32)
  internal           = false
  load_balancer_type = "application"
  ip_address_type    = "ipv4"
  security_groups    = [aws_security_group.alb_paris.id]
  subnets            = aws_subnet.public_paris[*].id

  depends_on = [aws_route.public_internet_paris, aws_route_table_association.public_paris]

  tags = { Name = "${local.paris_name}-alb" }
}

resource "aws_lb_target_group" "paris" {
  provider    = aws.paris
  name        = substr("${local.paris_name}-tg", 0, 32)
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main_paris.id

  # All other health-check settings use the AWS provider defaults.
  health_check {
    path = "/health.txt"
  }

  tags = { Name = "${local.paris_name}-tg" }
}

resource "aws_lb_target_group_attachment" "paris" {
  count            = var.paris_app_instance_count
  provider         = aws.paris
  target_group_arn = aws_lb_target_group.paris.arn
  target_id        = aws_instance.app_paris[count.index].id
  port             = 80
}

resource "aws_lb_listener" "http_paris" {
  provider          = aws.paris
  load_balancer_arn = aws_lb.paris.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.paris.arn
  }
}

resource "aws_lb_listener" "https_paris" {
  count             = var.paris_certificate_arn != null ? 1 : 0
  provider          = aws.paris
  load_balancer_arn = aws_lb.paris.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = var.paris_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.paris.arn
  }
}
