terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
  }
}

resource "kubernetes_namespace" "this" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "fluent_bit" {
  name       = "aws-for-fluent-bit"
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluent-bit"
  namespace  = kubernetes_namespace.this.metadata[0].name

  values = [
    jsonencode({
      image = {
        repository = "amazon/aws-for-fluent-bit"
      }
      serviceAccount = {
        create = true
        name   = var.service_account_name
        annotations = {
          "eks.amazonaws.com/role-arn" = var.iam_role_arn
        }
      }
      cloudWatch = {
        enabled    = true
        logGroupName = var.cloudwatch_log_group
        logStreamPrefix = var.cloudwatch_log_stream_prefix
        region          = var.region
      }
    })
  ]
}
