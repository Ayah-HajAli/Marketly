# ── ALB security group ──────────────────────────────────────────────
# Public entry point: only this SG is open to the whole internet.
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Allow HTTP/HTTPS from the internet"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from anywhere"
}

resource "aws_security_group_rule" "alb_ingress_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from anywhere"
}

resource "aws_security_group_rule" "alb_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "Allow all outbound"
}

# ── k3s node security group (control-plane + workers) ──────────────
# NOT open to the internet at all. Only reachable via the ALB, plus
# internal cluster traffic between nodes themselves.
resource "aws_security_group" "k3s" {
  name        = "${var.project_name}-k3s-sg"
  description = "k3s nodes: NodePort from ALB only, plus internal cluster traffic"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-k3s-sg"
  }
}

resource "aws_security_group_rule" "k3s_ingress_nodeport_from_alb" {
  type                     = "ingress"
  from_port                = 30000
  to_port                  = 32767
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.k3s.id
  description              = "NodePort range from ALB only"
}

resource "aws_security_group_rule" "k3s_ingress_self_all" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.k3s.id
  description       = "All traffic between k3s nodes (control-plane and workers): API server, kubelet, flannel VXLAN, etc."
}

resource "aws_security_group_rule" "k3s_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.k3s.id
  description       = "Allow all outbound (via NAT instance to reach ECR, package repos, etc.)"
}

# ── RDS security group ──────────────────────────────────────────────
# Only the k3s nodes can ever reach Postgres. Not even the ALB or NAT.
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Allow Postgres only from k3s nodes"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}

resource "aws_security_group_rule" "rds_ingress_from_k3s" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.k3s.id
  security_group_id        = aws_security_group.rds.id
  description              = "Postgres from k3s nodes only"
}

resource "aws_security_group_rule" "rds_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rds.id
  description       = "Allow all outbound"
}

# ── NAT instance security group ─────────────────────────────────────
# Only accepts traffic from inside the VPC (the private subnets it's
# routing for) — never from the public internet directly.
resource "aws_security_group" "nat" {
  name        = "${var.project_name}-nat-sg"
  description = "Allow traffic from inside the VPC only, for NAT forwarding"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-nat-sg"
  }
}

resource "aws_security_group_rule" "nat_ingress_vpc" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [var.vpc_cidr]
  security_group_id = aws_security_group.nat.id
  description       = "All traffic from inside the VPC CIDR"
}

resource "aws_security_group_rule" "nat_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.nat.id
  description       = "Allow all outbound to the internet"
}