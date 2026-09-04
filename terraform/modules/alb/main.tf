resource "aws_lb" "this" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  tags = {
    Name = "${var.project_name}-alb"
  }
}

resource "aws_lb_target_group" "k3s" {
  name        = "${var.project_name}-k3s-tg"
  port        = var.target_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 5
  }

  tags = {
    Name = "${var.project_name}-k3s-tg"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k3s.arn
  }
}

# The control-plane is a standalone instance, not part of the ASG,
# so it has to be registered with the target group by hand.
resource "aws_lb_target_group_attachment" "control_plane" {
  target_group_arn = aws_lb_target_group.k3s.arn
  target_id        = var.control_plane_instance_id
  port             = var.target_port
}

# Workers register/deregister automatically as the ASG scales up/down.
resource "aws_autoscaling_attachment" "workers" {
  autoscaling_group_name = var.worker_asg_name
  lb_target_group_arn    = aws_lb_target_group.k3s.arn
}