resource "kubernetes_namespace" "target_app" {
  count    = var.enable_eks ? 1 : 0
  provider = kubernetes.eks

  metadata {
    name = "target-app"
  }
}

resource "helm_release" "svc_user" {
  count      = var.enable_eks ? 1 : 0
  provider   = helm.eks
  name       = "svc-user"
  chart      = "../../target-app/charts/svc-user"
  namespace  = kubernetes_namespace.target_app[0].metadata[0].name
  depends_on = [module.nodegroup]

  # Helm v3: set 블록 대신 리스트로
  set = [
    {
      name  = "image.repository"
      value = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.ecr_repository_prefix}-svc-user"
    },
    {
      name  = "image.tag"
      value = var.target_app_image_tag
    }
  ]
}

resource "helm_release" "svc_order" {
  count      = var.enable_eks ? 1 : 0
  provider   = helm.eks
  name       = "svc-order"
  chart      = "../../target-app/charts/svc-order"
  namespace  = kubernetes_namespace.target_app[0].metadata[0].name
  depends_on = [module.nodegroup]

  set = [
    {
      name  = "image.repository"
      value = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.ecr_repository_prefix}-svc-order"
    },
    {
      name  = "image.tag"
      value = var.target_app_image_tag
    }
  ]
}

resource "helm_release" "svc_catalog" {
  count      = var.enable_eks ? 1 : 0
  provider   = helm.eks
  name       = "svc-catalog"
  chart      = "../../target-app/charts/svc-catalog"
  namespace  = kubernetes_namespace.target_app[0].metadata[0].name
  depends_on = [module.nodegroup]

  set = [
    {
      name  = "image.repository"
      value = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.ecr_repository_prefix}-svc-catalog"
    },
    {
      name  = "image.tag"
      value = var.target_app_image_tag
    }
  ]
}
