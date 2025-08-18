# Prometheus가 설치될 네임스페이스
variable "namespace" {
  description = "Namespace to install Prometheus"
  type        = string
  default     = "monitoring"
}

# 사용할 Helm chart 버전
variable "chart_version" {
  description = "kube-prometheus-stack Helm chart version"
  type        = string
  default     = "56.6.2" # 필요시 업데이트
}

# 종속 모듈 (예: EKS 등)
variable "depends_on_module" {
  description = "Module to depend on (e.g. EKS cluster)"
  type        = any
  default     = null
}

variable "rds_endpoint" {
  description = "RDS(Postgres) endpoint (예: mydb.abc123.ap-northeast-2.rds.amazonaws.com)"
  type        = string
}

variable "rds_db_name" {
  description = "애플리케이션이 사용하는 Postgres DB명"
  type        = string
}

variable "rds_db_exporter_user" {
  description = "postgres_exporter 접속용 계정"
  type        = string
}

variable "rds_db_exporter_password" {
  description = "postgres_exporter 접속용 비밀번호"
  type        = string
  sensitive   = true
}

variable "postgres_exporter_chart_version" {
  description = "prometheus-postgres-exporter Helm 차트 버전"
  type        = string
  default     = "6.1.0"
}

variable "service_monitor_labels" {
  description = "ServiceMonitor 라벨 (kube-prometheus-stack가 선택하도록 release 라벨 등 맞추기)"
  type        = map(string)
  default     = {
    release = "kube-prometheus-stack"
  }
}