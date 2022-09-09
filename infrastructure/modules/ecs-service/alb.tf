data "aws_vpc" "default" {
  default = true
}

# Application Load Balancer infront of each
resource "aws_alb" "application_load_balancer" {
  name               = "${var.service-config.name}-lb"
  load_balancer_type = "application"
  subnets            = var.default_azs
  security_groups    = ["${aws_security_group.load_balancer_security_group.id}"]
  idle_timeout       = 300 # default:60s

  # TODO: enable loadbalancer logs
  /* access_logs {
    bucket = "${var.logging_bucket_name}"
    prefix = "${var.service-config.name}-loadbalancer"
    enabled = true
  } */
}

# Load Balancer Security Group
resource "aws_security_group" "load_balancer_security_group" {
    name            = "${var.service-config.name}-sg"

    # Configuration for incoming trafic
    ingress {
        from_port   = 80            # Allowing traffic in from port 80, HTTP requests
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # Allowing traffic in from all sources
    }

    # Configuration for out-going trafic
    egress {
        from_port   = 0    # Allowing any incoming port
        to_port     = 0    # Allowing any outgoing port
        protocol    = "-1" # Allowing any outgoing protocol
        cidr_blocks = ["0.0.0.0/0"] # Allowing traffic out to all IP addresses
    }
}

resource "aws_lb_target_group" "target_group" {
  name        = "${var.service-config.name}-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "${data.aws_vpc.default.id}" # Referencing the default VPC
  health_check {
    matcher = "200,301,302"
    path = "/"
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = "${aws_alb.application_load_balancer.arn}"
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.target_group.arn}"
  }
}