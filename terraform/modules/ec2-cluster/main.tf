data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

data "aws_region" "current" {}

locals {
  param_prefix = "/${var.project_name}/k3s"
}

# ── Shared IAM role for control-plane + workers ─────────────────────
resource "aws_iam_role" "k3s_node" {
  name = "${var.project_name}-k3s-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "k3s_node_ssm" {
  role       = aws_iam_role.k3s_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Scoped narrowly: this role can only touch SSM parameters under our
# own path, not every parameter in the account.
resource "aws_iam_role_policy" "k3s_node_ssm_params" {
  name = "${var.project_name}-k3s-ssm-params"
  role = aws_iam_role.k3s_node.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ssm:PutParameter",
        "ssm:GetParameter",
        "ssm:GetParameters"
      ]
      Resource = "arn:aws:ssm:*:*:parameter${local.param_prefix}/*"
    }]
  })
}

# Lets the cluster nodes fetch the RDS credentials themselves at deploy
# time, so the real password never has to appear in a human's terminal
# output or be typed into any file.
resource "aws_iam_role_policy" "k3s_node_secrets" {
  name = "${var.project_name}-k3s-secrets-read"
  role = aws_iam_role.k3s_node.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = var.rds_secret_arn
    }]
  })
}

# Lets the cluster nodes pull images from our private ECR repos, and
# generate their own short-lived ECR pull tokens for a k8s regcred secret.
resource "aws_iam_role_policy_attachment" "k3s_node_ecr" {
  role       = aws_iam_role.k3s_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "k3s_node" {
  name = "${var.project_name}-k3s-node-profile"
  role = aws_iam_role.k3s_node.name
}

# ── Control-plane (single instance, private subnet, no public IP) ───
resource "aws_instance" "control_plane" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.control_plane_instance_type
  subnet_id              = var.private_subnet_ids[0]
  vpc_security_group_ids = [var.k3s_sg_id]
  iam_instance_profile   = aws_iam_instance_profile.k3s_node.name

  user_data = templatefile("${path.module}/templates/control-plane-user-data.sh.tpl", {
    region       = data.aws_region.current.name
    param_prefix = local.param_prefix
  })

  tags = {
    Name = "${var.project_name}-k3s-control-plane"
    Role = "control-plane"
  }
}

# ── Worker Auto Scaling Group ─────────────────────────────────────────
resource "aws_launch_template" "worker" {
  name_prefix   = "${var.project_name}-k3s-worker-"
  image_id      = data.aws_ami.al2023.id
  instance_type = var.worker_instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.k3s_node.name
  }

  vpc_security_group_ids = [var.k3s_sg_id]

  user_data = base64encode(templatefile("${path.module}/templates/worker-user-data.sh.tpl", {
    region       = data.aws_region.current.name
    param_prefix = local.param_prefix
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-k3s-worker"
      Role = "worker"
    }
  }
}

resource "aws_autoscaling_group" "workers" {
  name                = "${var.project_name}-k3s-workers"
  min_size            = var.worker_min_size
  max_size            = var.worker_max_size
  desired_capacity    = var.worker_desired_capacity
  vpc_zone_identifier = var.private_subnet_ids

  launch_template {
    id      = aws_launch_template.worker.id
    version = "$Latest"
  }

  # Give the control-plane a head start so workers don't spin
  # waiting on a control-plane that hasn't even launched yet.
  depends_on = [aws_instance.control_plane]

  tag {
    key                 = "Name"
    value               = "${var.project_name}-k3s-worker"
    propagate_at_launch = true
  }
}