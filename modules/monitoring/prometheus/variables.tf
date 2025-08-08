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