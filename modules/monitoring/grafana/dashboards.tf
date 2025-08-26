# 대시보드 파일별로 ConfigMap 1개 생성
locals {
  dashboard_files = fileset("${path.module}/dashboards", "*.json")

  # 파일명 정규화 준비: .json 제거 → 소문자
  dash_base = {
    for f in local.dashboard_files :
    f => lower(replace(f, ".json", ""))
  }

  # 허용문자(a-z0-9.-)만 남기고 양끝의 .,- 제거
  dash_safe = {
    for f, name in local.dash_base :
    f => trim(join("", regexall("[a-z0-9.-]", name)), ".-")
  }
}

resource "kubernetes_config_map" "grafana_dashboards" {
  for_each = { for f in local.dashboard_files : f => f }

  # K8s 이름 63자 제한 대비: md5 해시로 유니크 보장 + 전체 substr
  metadata {
    name      = substr("grafana-dashboard-${substr(md5(each.key), 0, 6)}-${local.dash_safe[each.key]}", 0, 63)
    # name      = replace(substr("grafana-dashboard-${substr(md5(each.key),0,6)}-${local.dash_safe[each.key]}", 0, 63), "-$", "")
    namespace = var.namespace
    labels = {
      grafana_dashboard = "1" # Grafana sidecar가 보는 라벨
    }
  }

  data = {
    # 키는 원래 파일명 유지 (사이드카가 내용만 읽음)
    "${each.key}" = file("${path.module}/dashboards/${each.key}")
  }

  depends_on = [helm_release.grafana]
}