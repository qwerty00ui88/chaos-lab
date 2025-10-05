resource "aws_iam_role" "aws_lb_controller" {
  count = var.enable_eks && var.enable_aws_load_balancer_controller ? 1 : 0

  name = "${module.shared.project_name}-${var.environment}-aws-lbc"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks[0].arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(local.eks_oidc_issuer, "https://", "")}:aud" = "sts.amazonaws.com"
            "${replace(local.eks_oidc_issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })

  tags = merge(module.shared.default_tags, {
    Component = "aws-load-balancer-controller"
  })
}

resource "aws_iam_role_policy_attachment" "aws_lb_controller" {
  count = var.enable_eks && var.enable_aws_load_balancer_controller ? 1 : 0

  role       = aws_iam_role.aws_lb_controller[0].name
  policy_arn = "arn:aws:iam::aws:policy/AWSLoadBalancerControllerIAMPolicy"
}

resource "kubernetes_service_account" "aws_lb_controller" {
  count    = var.enable_eks && var.enable_aws_load_balancer_controller ? 1 : 0
  provider = kubernetes.eks

  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.aws_lb_controller[0].arn
    }
    labels = {
      "app.kubernetes.io/name" = "aws-load-balancer-controller"
    }
  }
}

resource "helm_release" "aws_lb_controller" {
  count    = var.enable_eks && var.enable_aws_load_balancer_controller ? 1 : 0
  provider = helm.eks

  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.8.1"
  namespace  = "kube-system"

  depends_on = [
    kubernetes_service_account.aws_lb_controller,
    aws_iam_role_policy_attachment.aws_lb_controller
  ]

  set {
    name  = "clusterName"
    value = module.eks[0].name
  }

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = local.vpc_id
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
}
