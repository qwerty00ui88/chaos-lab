locals {
  cluster_tag_subnet_ids = var.enable_eks ? distinct(concat(local.node_subnet_ids, local.alb_subnet_ids)) : []
}

resource "aws_ec2_tag" "eks_cluster_subnets" {
  for_each = length(local.cluster_tag_subnet_ids) > 0 ? toset(local.cluster_tag_subnet_ids) : toset([])

  resource_id = each.value
  key         = "kubernetes.io/cluster/${local.cluster_name}"
  value       = "shared"
}

resource "aws_ec2_tag" "alb_public_subnets" {
  for_each = var.enable_eks && var.enable_alb ? toset(local.alb_subnet_ids) : toset([])

  resource_id = each.value
  key         = "kubernetes.io/role/elb"
  value       = "1"
}
