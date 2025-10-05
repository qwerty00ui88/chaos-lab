resource "kubernetes_ingress_v1" "target_app" {
  count    = var.enable_eks && var.enable_aws_load_balancer_controller ? 1 : 0
  provider = kubernetes.eks

  metadata {
    name      = "target-app"
    namespace = kubernetes_namespace.target_app[0].metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"           = "alb"
      "alb.ingress.kubernetes.io/scheme"      = "internet-facing"
      "alb.ingress.kubernetes.io/target-type" = "ip"
      "alb.ingress.kubernetes.io/listen-ports" = jsonencode([
        {
          HTTP = 80
        }
      ])
      "alb.ingress.kubernetes.io/load-balancer-name" = "${module.shared.project_name}-${var.environment}-target-app"
      "alb.ingress.kubernetes.io/group.name"         = "${module.shared.project_name}-${var.environment}"
      "alb.ingress.kubernetes.io/healthcheck-path"   = "/actuator/health/readiness"
    }
    labels = {
      "app.kubernetes.io/name" = "target-app"
    }
  }

  spec {
    ingress_class_name = "alb"

    rule {
      http {
        path {
          path      = "/api/user"
          path_type = "Prefix"

          backend {
            service {
              name = "svc-user"
              port {
                number = 8080
              }
            }
          }
        }

        path {
          path      = "/api/order"
          path_type = "Prefix"

          backend {
            service {
              name = "svc-order"
              port {
                number = 8080
              }
            }
          }
        }

        path {
          path      = "/api/catalog"
          path_type = "Prefix"

          backend {
            service {
              name = "svc-catalog"
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
  }

  wait_for_load_balancer = true

  depends_on = [
    kubernetes_namespace.target_app,
    helm_release.aws_lb_controller,
    helm_release.svc_user,
    helm_release.svc_order,
    helm_release.svc_catalog
  ]
}
