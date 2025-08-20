# Prometheus Helm 차트 배포
resource "helm_release" "prometheus" {
  # 릴리스 이름
  name = "kube-prometheus-stack"
  # 배포할 네임스페이스
  namespace = var.namespace
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

########################
# Postgres Exporter Secret
########################
resource "kubernetes_secret" "postgres_exporter" {
  metadata {
    name      = "postgres-exporter-secret"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name" = "postgres-exporter"
    }
  }

  type = "Opaque"

  data = {
    DATA_SOURCE_URI  = base64encode("${var.rds_endpoint}:5432/${var.rds_db_name}?sslmode=disable")
    DATA_SOURCE_USER = base64encode(var.rds_db_exporter_user)
    DATA_SOURCE_PASS = base64encode(var.rds_db_exporter_password)
  }
}

########################
# Postgres Exporter (Helm)
########################
resource "helm_release" "postgres_exporter" {
  name       = "postgres-exporter"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-postgres-exporter"
  version    = var.postgres_exporter_chart_version
  namespace  = var.namespace

  values = [
    yamlencode({
      config = {
        datasource = {
          host     = var.rds_endpoint
          port     = "5432"
          user     = var.rds_db_exporter_user
          dbname   = var.rds_db_name
          sslmode  = "disable"
          password = var.rds_db_exporter_password
        }
      }
      # 민감정보는 Secret에서 주입
      # envFromSecret = kubernetes_secret.postgres_exporter.metadata[0].name

      # ServiceMonitor를 만들어 kube-prometheus-stack이 자동 스크레이프
      serviceMonitor = {
        enabled       = true
        interval      = "15s"
        scrapeTimeout = "10s"
        # kube-prometheus-stack이 인식할 라벨 (values.yaml에서 쓰는 release 라벨과 맞추기)
        labels        = var.service_monitor_labels
        namespace     = var.namespace
      }

      # Pod/Service 기본 라벨(선택)
      podLabels = { "team" = "platform" }
      service = {
        labels = { "team" = "platform" }
        port   = 9187
      }
    })
  ]

  depends_on = [
    helm_release.prometheus,
    kubernetes_secret.postgres_exporter,
  ]
}