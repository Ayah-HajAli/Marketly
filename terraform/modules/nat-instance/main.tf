# Amazon Linux 2 — well-tested for the classic NAT-instance iptables pattern
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# IAM role so we can reach this instance via SSM if needed, no SSH key required
resource "aws_iam_role" "nat" {
  name = "${var.project_name}-nat-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "nat_ssm" {
  role       = aws_iam_role.nat.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "nat" {
  name = "${var.project_name}-nat-profile"
  role = aws_iam_role.nat.name
}

resource "aws_instance" "nat" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = "t3.micro"
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.nat_sg_id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.nat.name

  # Required for a NAT instance: it must be allowed to forward traffic
  # that isn't addressed to itself.
  source_dest_check = false

  user_data = <<-EOF
    #!/bin/bash
    set -euo pipefail
    sysctl -w net.ipv4.ip_forward=1
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
    IFACE=$(ip route show default | awk '{print $5}' | head -n1)
    /sbin/iptables -t nat -A POSTROUTING -o "$IFACE" -j MASQUERADE
    service iptables save
  EOF

  tags = {
    Name = "${var.project_name}-nat-instance"
  }
}

resource "aws_eip" "nat" {
  domain   = "vpc"
  instance = aws_instance.nat.id

  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}

# Point the private route table's internet-bound traffic at this
# instance's network interface, completing the private subnets'
# path to the internet.
resource "aws_route" "private_to_nat" {
  route_table_id         = var.private_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_instance.nat.primary_network_interface_id
}