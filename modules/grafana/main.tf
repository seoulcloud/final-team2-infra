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