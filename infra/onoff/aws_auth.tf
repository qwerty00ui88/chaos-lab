locals {
  aws_auth_node_role = var.enable_eks && var.enable_nodegroup ? try(module.nodegroup[0].role_arn, "") : ""

  aws_auth_roles = var.enable_eks ? concat(
    local.aws_auth_node_role != ""
    ? [
      {
        rolearn  = local.aws_auth_node_role
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      }
    ]
    : [],
    var.aws_auth_additional_roles
  ) : []

  aws_auth_users    = var.enable_eks ? var.aws_auth_map_users : []
  aws_auth_accounts = var.enable_eks ? var.aws_auth_map_accounts : []
}

resource "kubernetes_config_map" "aws_auth" {
  count    = var.enable_eks && var.enable_nodegroup ? 1 : 0
  provider = kubernetes.eks

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles    = yamlencode(local.aws_auth_roles)
    mapUsers    = yamlencode(local.aws_auth_users)
    mapAccounts = yamlencode(local.aws_auth_accounts)
  }

  depends_on = [
    module.nodegroup
  ]
}
