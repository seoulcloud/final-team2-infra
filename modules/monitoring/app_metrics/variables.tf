variable "namespace" {
  description = "애플리케이션이 배포된 Kubernetes 네임스페이스"
  type        = string
}

variable "app_name" {
  description = "애플리케이션 식별 이름 (라벨/서비스명에 사용)"
  type        = string
}

variable "selector_label_key" {
  description = "Pod를 선택할 라벨 키 (예: app, app.kubernetes.io/name 등)"
  type        = string
  default     = "app"
}

variable "service_port" {
  description = "애플리케이션 컨테이너의 포트"
  type        = number
}

variable "service_port_name" {
  description = "Service 포트 이름 (ServiceMonitor endpoints.port와 동일해야 함)"
  type        = string
}

variable "prom_path" {
  description = "Prometheus 스크레이프 경로 (예: /actuator/prometheus)"
  type        = string
}

variable "prom_release_label" {
  description = "kube-prometheus-stack의 release 라벨 값"
  type        = string
}