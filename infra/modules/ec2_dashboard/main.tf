data "aws_ami" "ubuntu_jammy" {
  owners      = ["099720109477"]
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "dashboard" {
  name        = "${var.name}-sg"
  description = "Security group for dashboard EC2 host"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-sg"
  })
}

resource "aws_iam_role" "dashboard" {
  count = var.create_instance_profile ? 1 : 0

  name = "${var.name}-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.name}-instance-role"
  })
}

resource "aws_iam_role_policy_attachment" "dashboard_ecr" {
  count = var.create_instance_profile ? 1 : 0

  role       = aws_iam_role.dashboard[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "dashboard_ssm" {
  count = var.create_instance_profile ? 1 : 0

  role       = aws_iam_role.dashboard[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "dashboard_additional" {
  for_each = var.create_instance_profile ? toset(var.iam_managed_policy_arns) : toset([])

  role       = aws_iam_role.dashboard[0].name
  policy_arn = each.value
}

resource "aws_iam_instance_profile" "dashboard" {
  count = var.create_instance_profile ? 1 : 0

  name = "${var.name}-instance-profile"
  role = aws_iam_role.dashboard[0].name
}

locals {
  iam_instance_profile = var.create_instance_profile ? aws_iam_instance_profile.dashboard[0].name : var.instance_profile_name
}

resource "aws_instance" "this" {
  ami                         = data.aws_ami.ubuntu_jammy.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  key_name                    = var.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.dashboard.id]
  user_data                   = var.user_data
  iam_instance_profile        = local.iam_instance_profile

  tags = merge(var.tags, {
    Name = var.name
  })
}
