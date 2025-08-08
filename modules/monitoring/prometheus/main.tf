# Prometheus Helm 차트 배포
#resource "helm_release" "prometheus" {
#  # 릴리스 이름
#  name       = "kube-prometheus-stack"
#  # 배포할 네임스페이스
#  namespace  = var.namespace
#  # 사용할 차트 이름 및 저장소
#  chart      = "kube-prometheus-stack"
#  repository = "https://prometheus-community.github.io/helm-charts"
#  version    = var.chart_version
#
#  # 네임스페이스가 없다면 생성
#  create_namespace = true
#
#  # 사용자 정의 values.yaml 값 적용
#  values = [file("${path.module}/values.yaml")]
#
#  # 의존성 모듈이 모두 완료된 후 실행
#  depends_on = [var.depends_on_module]
#}