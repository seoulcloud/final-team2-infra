resource "kubernetes_horizontal_pod_autoscaler_v2" "hpa" {
  metadata {
    name      = "${var.deployment_name}-hpa"
    namespace = var.namespace
  }
  spec {
    scale_target_ref {
      kind       = "Deployment"
      name       = var.deployment_name
      api_version = "apps/v1"
    }

    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type               = "Utilization"
          average_utilization = var.target_cpu_utilization
        }
      }
    }
  }
}


resource "kubernetes_service" "hpa_test_internal_svc" {
  metadata {
    name      = "hpa-test-internal-svc"
    namespace = var.namespace  # 변수로 네임스페이스 관리 추천
    labels = {
      app = "hpa-test-internal-svc"
    }
  }

  spec {
    selector = {
      app = "hpa-test"
    }
    port {
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }
    type = "ClusterIP"  # 내부용 서비스
  }
}

resource "kubernetes_service" "hpa_test_external_svc" {
  metadata {
    name      = "hpa-test-external-svc"
    namespace = var.namespace
    labels = {
      app = "hpa-test-external-svc"
    }
  }

  spec {
    selector = {
      app = "hpa-test"
    }
    port {
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }
    type = "LoadBalancer"  # 외부용 서비스
  }
}


resource "kubernetes_deployment" "hpa_test" {
  metadata {
    name      = var.deployment_name    # 예: "hpa-test"
    namespace = var.namespace
    labels = {
      app = "hpa-test"
    }
  }

  spec {
    replicas = var.min_replicas

    selector {
      match_labels = {
        app = "hpa-test"
      }
    }

    template {
      metadata {
        labels = {
          app = "hpa-test"
        }
      }

      spec {
        container {
          name  = "hpa-test-container"
          image = var.container_image   # 예: "nginx:latest" 등 원하는 이미지

          port {
            container_port = 80
          }

          resources {
            requests = {
              cpu    = "200m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }
        }
      }
    }
  }
}