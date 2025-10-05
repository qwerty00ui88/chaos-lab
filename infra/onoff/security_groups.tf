resource "aws_security_group_rule" "eks_control_plane_to_nodes_kubelet" {
  count = var.enable_eks ? 1 : 0

  description              = "Allow EKS control plane to reach kubelet on worker nodes"
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = local.eks_node_security_group_id
  source_security_group_id = module.eks[0].cluster_security_group_id
}

resource "aws_security_group_rule" "eks_control_plane_to_nodes_tls" {
  count = var.enable_eks ? 1 : 0

  description              = "Allow EKS control plane to reach nodes over TLS"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = local.eks_node_security_group_id
  source_security_group_id = module.eks[0].cluster_security_group_id
}

resource "aws_security_group_rule" "eks_nodes_to_control_plane_api" {
  count = var.enable_eks ? 1 : 0

  description              = "Allow worker nodes to reach EKS API server"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = module.eks[0].cluster_security_group_id
  source_security_group_id = local.eks_node_security_group_id
}
