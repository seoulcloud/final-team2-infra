variable "namespace" {
  description = "Grafana 설치 namespace"
  type        = string
  default     = "monitoring"
}

variable "chart_version" {
  description = "Grafana Helm 차트 버전"
  type        = string
  default     = "7.3.9"
}

variable "depends_on_module" {
  description = "의존성 모듈 (ex: Prometheus)"
  type        = any
}

variable "grafana_admin_password" {
  description = "Grafana 관리자 비밀번호"
  type        = string
  sensitive   = true
}

variable "alb_sg_id" {
  description = "ALB SG ID"
}

variable "node_sg_id" {
  description = "EKS NodeGroup SG ID"
}

variable "grafana_target_port" {
  description = "Grafana 서비스 포트"
  default     = 3000
}