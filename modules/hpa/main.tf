# HPA Module - Main

resource "kubernetes_horizontal_pod_autoscaler_v2" "this" {
  metadata {
    name      = var.name
    namespace = var.namespace
    labels    = var.labels
  }

  spec {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    scale_target_ref {
      kind = var.target_kind
      name = var.target_name
    }

    # CPU utilization metric (Utilization)
    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = var.average_cpu_utilization
        }
      }
    }

    # Optional memory utilization metric (Utilization)
    dynamic "metric" {
      for_each = var.average_memory_utilization == null ? [] : [1]
      content {
        type = "Resource"
        resource {
          name = "memory"
          target {
            type                = "Utilization"
            average_utilization = var.average_memory_utilization
          }
        }
      }
    }
  }
} 