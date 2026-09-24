resource "kubernetes_namespace" "petclinic" {
  metadata {
    name = "petclinic"
  }
}

resource "kubernetes_ingress_v1" "petclinic_ingress" {
  metadata {
    name      = "petclinic-ingress"
    namespace = "petclinic"
    annotations = {
      "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"      = "ip"
      "alb.ingress.kubernetes.io/healthcheck-path" = "/actuator/health"
      "alb.ingress.kubernetes.io/healthcheck-port" = "8080"
    }
  }

  spec {
    ingress_class_name = "alb"
    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "api-gateway"
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_namespace.petclinic]
}