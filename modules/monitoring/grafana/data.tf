# Grafana LoadBalancer 서비스 정보 조회
data "kubernetes_ingress_v1" "grafana" {
  metadata {
    name      = "grafana"
    namespace = var.namespace
  }

  depends_on = [helm_release.grafana]
}

data "kubernetes_service" "prom" {
  metadata {
    name      = "kube-prometheus-stack-prometheus"
    namespace = var.namespace
  }
}