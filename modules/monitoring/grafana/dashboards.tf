# 대시보드 파일 목록을 읽어서 파일마다 ConfigMap 1개씩 생성
# 이유: ConfigMap 1개당 1MB 제한 회피를 위해 파일별로 분리
locals {
  dashboard_files = fileset("${path.module}/dashboards", "*.json")
}

resource "kubernetes_config_map" "grafana_dashboards" {
  for_each = { for f in local.dashboard_files : f => f }

  metadata {
    # 파일명에서 .json 제거하고 이름에 안전한 문자만 사용
    name      = "grafana-dashboard-${replace(regex("\\.json$", each.key), "/[^a-zA-Z0-9-]/", "-")}"
    namespace = var.namespace
    labels = {
      # values.yaml의 sidecar가 읽어가는 라벨
      grafana_dashboard = "1"
    }
  }

  # 파일 내용을 그대로 ConfigMap에 탑재
  data = {
    # key는 대시보드 파일명 (그대로 유지)
    "${each.key}" = file("${path.module}/dashboards/${each.key}")
  }

  # Grafana(Helm)가 먼저 올라온 뒤 사이드카가 읽게끔 순서 보장
  depends_on = [helm_release.grafana]
}