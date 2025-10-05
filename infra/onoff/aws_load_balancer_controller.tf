resource "aws_iam_policy" "aws_lb_controller" {
  count = var.enable_eks && var.enable_aws_load_balancer_controller ? 1 : 0

  name        = "${module.shared.project_name}-${var.environment}-aws-lbc"
  description = "Permissions required by AWS Load Balancer Controller"

  policy = templatefile("${path.module}/templates/aws_lb_controller_policy.json.tpl", {
    cluster_name = module.eks[0].name
  })
}

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
  policy_arn = aws_iam_policy.aws_lb_controller[0].arn
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

  set = [
    {
      name  = "clusterName"
      value = module.eks[0].name
    },
    {
      name  = "region"
      value = var.region
    },
    {
      name  = "vpcId"
      value = local.vpc_id
    },
    {
      name  = "serviceAccount.create"
      value = "false"
    },
    {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller"
    },
    {
      name  = "image.repository"
      value = "602401143452.dkr.ecr.${var.region}.amazonaws.com/amazon/aws-load-balancer-controller"
    },
    {
      name  = "image.tag"
      value = "v2.8.1"
    }
  ]
}
