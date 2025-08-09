# Metrics Server Module - Main

resource "helm_release" "metrics_server" {
  name       = var.release_name
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = var.chart_version
  namespace  = var.namespace
  timeout    = var.timeout

  set {
    name  = "args[0]"
    value = "--kubelet-preferred-address-types=InternalIP,Hostname,ExternalIP"
  }

  set {
    name  = "args[1]"
    value = "--kubelet-use-node-status-port"
  }

  dynamic "set" {
    for_each = var.insecure_kubelet_tls ? [1] : []
    content {
      name  = "args[2]"
      value = "--kubelet-insecure-tls"
    }
  }

  dynamic "set" {
    for_each = var.host_network ? [1] : []
    content {
      name  = "hostNetwork"
      value = "true"
    }
  }
} 