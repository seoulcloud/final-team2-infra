# Grafana LoadBalancer 서비스 정보 조회
data "kubernetes_ingress_v1" "grafana" {
  metadata {
    name      = "grafana"
    namespace = var.namespace
  }

  depends_on = [helm_release.grafana]
}