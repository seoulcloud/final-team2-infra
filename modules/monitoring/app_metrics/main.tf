resource "kubernetes_service" "app" {
  metadata {
    name      = "${var.app_name}-metrics"
    namespace = var.namespace
    labels = {
      app = var.app_name
    }  
  }

  spec {
    type = "ClusterIP"

    selector = {
      (var.selector_label_key) = var.app_name
    }

    port {
      name        = var.service_port_name
      port        = var.service_port
      target_port = var.service_port
    }
  }
}

resource "kubernetes_manifest" "servicemonitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "${var.app_name}-metrics"
      namespace = var.namespace
      labels = {
        # kube-prometheus-stack 의 values.yaml 에서 사용하는 release 라벨과 동일해야 자동 스크레이프됨
        release = var.prom_release_label
      }
    }
    spec = {
      namespaceSelector = {
        matchNames = [var.namespace]
      }
      selector = {
        matchLabels = {
          app = var.app_name
        }
      }
      endpoints = [
        {
          port          = var.service_port_name
          path          = var.prom_path
          interval      = "15s"
          scrapeTimeout = "10s"
        }
      ]
    }
  }
}