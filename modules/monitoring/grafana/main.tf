# Grafana Helm 설치
resource "helm_release" "grafana" {
  name       = "grafana"
  namespace  = var.namespace
  chart      = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  version    = var.chart_version

  create_namespace = true

  # values.yaml 설정 적용
  values = [file("${path.module}/values.yaml")]

  # admin 비밀번호는 민감하므로 별도 관리
  set_sensitive {
    name  = "adminPassword"
    value = var.grafana_admin_password
  }

  depends_on = [var.depends_on_module]
}

# 1) 잠깐 대기해서 ALB 붙을 시간 주기 (60초는 예시)
resource "time_sleep" "wait_for_alb" {
  depends_on       = [helm_release.grafana]
  create_duration  = "60s"
}

# Grafana LoadBalancer 서비스 정보 조회
data "kubernetes_ingress_v1" "grafana" {
  metadata {
    name      = "grafana"
    namespace = var.namespace
  }

  depends_on = [helm_release.grafana]
}