data "aws_region" "current" {}

locals {
  base_tags = merge(var.tags, {
    Name = var.name
  })

  private_subnet_ids_by_key = {
    for key, subnet in aws_subnet.private :
    key => subnet.id
  }

  private_subnet_arns_by_key = {
    for key, subnet in aws_subnet.private :
    key => subnet.arn
  }

  public_subnet_ids_by_key = {
    for key, subnet in aws_subnet.public :
    key => subnet.id
  }

  private_subnets_by_az_grouped = {
    for s in aws_subnet.private : s.availability_zone => s.id...
  }

  # 모든 프라이빗 서브넷의 AZ 목록
  private_azs = distinct([for s in aws_subnet.private : s.availability_zone])

  # AZ별 프라이빗 서브넷 ID 리스트 (한 AZ에 여러 개 있을 수 있음)
  private_subnets_by_az = {
    for az in local.private_azs :
    az => [for s in aws_subnet.private : s.id if s.availability_zone == az]
  }

  # VPC 엔드포인트용: 각 AZ에서 대표 서브넷 하나만 선택
  vpce_subnet_ids = [for az, ids in local.private_subnets_by_az : ids[0]]
}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.base_tags, {
    Component = "vpc"
  })
}

resource "aws_subnet" "private" {
  for_each = var.private_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = false

  tags = merge(local.base_tags, {
    Component = "subnet"
    Scope     = "private"
    Name      = "${var.name}-${each.key}"
  })
}

resource "aws_subnet" "public" {
  for_each = var.public_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = merge(local.base_tags, {
    Component = "subnet"
    Scope     = "public"
    Name      = "${var.name}-${each.key}"
  })
}

resource "aws_internet_gateway" "this" {
  count = length(var.public_subnets) > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(local.base_tags, {
    Component = "internet-gateway"
  })
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.base_tags, {
    Component = "route-table"
    Scope     = "private"
  })
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table" "public" {
  count = length(var.public_subnets) > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(local.base_tags, {
    Component = "route-table"
    Scope     = "public"
  })
}

resource "aws_route" "public_internet" {
  count = length(var.public_subnets) > 0 ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_security_group" "alb" {
  name        = "${var.name}-alb"
  description = "Ingress for Application Load Balancer"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.base_tags, {
    Component = "security-group"
    Role      = "alb"
  })
}

resource "aws_security_group" "eks_nodes" {
  name        = "${var.name}-eks-nodes"
  description = "Security group for EKS worker nodes"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "NodePort/ingress from ALB"
    from_port       = 30000
    to_port         = 32767
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "From EKS control plane to kubelets"
    from_port       = 1025
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description = "Cluster internal communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.base_tags, {
    Component = "security-group"
    Role      = "eks-nodes"
  })
}

resource "aws_security_group" "vpce" {
  name        = "${var.name}-vpce"
  description = "Security group for VPC interface endpoints"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTPS access from within the VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.cidr_block]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.base_tags, {
    Component = "security-group"
    Role      = "vpce"
  })
}

resource "aws_security_group" "rds" {
  name        = "${var.name}-rds"
  description = "Security group for RDS access"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "MySQL from EKS nodes"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.base_tags, {
    Component = "security-group"
    Role      = "rds"
  })
}

resource "aws_security_group_rule" "alb_to_eks_https" {
  description              = "ALB to EKS control plane/ingress"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "eks_to_alb_https" {
  description              = "EKS nodes to ALB"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb.id
  source_security_group_id = aws_security_group.eks_nodes.id
}
