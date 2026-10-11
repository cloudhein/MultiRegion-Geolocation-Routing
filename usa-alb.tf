# Internet-facing ALB for usa: HTTP and HTTPS -> application HTTP.
resource "aws_security_group" "alb_usa" {
  provider    = aws.usa
  name        = "${local.usa_name}-alb-sg"
  description = "Public HTTP and HTTPS access"
  vpc_id      = aws_vpc.main_usa.id

  tags = { Name = "${local.usa_name}-alb-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http_usa" {
  provider          = aws.usa
  security_group_id = aws_security_group.alb_usa.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "alb_https_usa" {
  provider          = aws.usa
  security_group_id = aws_security_group.alb_usa.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "alb_all_usa" {
  provider          = aws.usa
  security_group_id = aws_security_group.alb_usa.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_lb" "usa" {
  provider           = aws.usa
  name               = substr("${local.usa_name}-alb", 0, 32)
  internal           = false
  load_balancer_type = "application"
  ip_address_type    = "ipv4"
  security_groups    = [aws_security_group.alb_usa.id]
  subnets            = aws_subnet.public_usa[*].id

  depends_on = [aws_route.public_internet_usa, aws_route_table_association.public_usa]

  tags = { Name = "${local.usa_name}-alb" }
}

resource "aws_lb_target_group" "usa" {
  provider    = aws.usa
  name        = substr("${local.usa_name}-tg", 0, 32)
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main_usa.id

  # All other health-check settings use the AWS provider defaults.
  health_check {
    path = "/health.txt"
  }

  tags = { Name = "${local.usa_name}-tg" }
}

resource "aws_lb_target_group_attachment" "usa" {
  count            = var.usa_app_instance_count
  provider         = aws.usa
  target_group_arn = aws_lb_target_group.usa.arn
  target_id        = aws_instance.app_usa[count.index].id
  port             = 80
}

resource "aws_lb_listener" "http_usa" {
  provider          = aws.usa
  load_balancer_arn = aws_lb.usa.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.usa.arn
  }
}

resource "aws_lb_listener" "https_usa" {
  count             = var.usa_certificate_arn != null ? 1 : 0
  provider          = aws.usa
  load_balancer_arn = aws_lb.usa.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = var.usa_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.usa.arn
  }
}
