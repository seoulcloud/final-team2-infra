# Prometheus Helm 차트 배포
resource "helm_release" "prometheus" {
 # 릴리스 이름
 name       = "kube-prometheus-stack"
 # 배포할 네임스페이스
 namespace  = var.namespace
 # 사용할 차트 이름 및 저장소
 chart      = "kube-prometheus-stack"
 repository = "https://prometheus-community.github.io/helm-charts"
 version    = var.chart_version

 # 사용자 정의 values.yaml 값 적용
 values = [file("${path.module}/values.yaml")]

  wait            = true
  timeout         = 1200
  atomic          = true
  cleanup_on_fail = true

 # 의존성 모듈이 모두 완료된 후 실행
 depends_on = [var.depends_on_module]
}