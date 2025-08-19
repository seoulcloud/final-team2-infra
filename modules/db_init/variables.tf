variable "namespace" {
  description = "Flyway Job이 실행될 네임스페이스"
  type        = string
}

variable "app_suffix" {
  description = "Job 이름에 붙일 식별자 (예: backend)"
  type        = string
  default     = "backend"
}

variable "job_name" {
  description = "Job 이름(옵션). 비우면 flyway-init-<app_suffix>"
  type        = string
  default     = ""
}

variable "db_host" {
  description = "RDS 엔드포인트 (호스트만)"
  type        = string
}

variable "db_port" {
  description = "DB 포트"
  type        = string
  default     = "5432"
}

variable "db_name" {
  description = "DB 이름"
  type        = string
}

variable "db_user" {
  description = "DB 접속 유저"
  type        = string
}

variable "db_password" {
  description = "DB 접속 패스워드"
  type        = string
  sensitive   = true
}

# Exporter 계정(초기화 SQL에서 생성/권한부여)
variable "exporter_user" {
  description = "Prometheus Exporter DB 유저"
  type        = string
}

variable "exporter_password" {
  description = "Prometheus Exporter DB 유저 비밀번호"
  type        = string
  sensitive   = true
}

# Flyway 이미지/동작
variable "flyway_image" {
  description = "Flyway 컨테이너 이미지"
  type        = string
  default     = "flyway/flyway:9.22.3"
}

variable "backoff_limit" {
  description = "Job 실패 재시도 횟수"
  type        = number
  default     = 4
}

variable "connect_retries" {
  description = "Flyway DB 연결 재시도 횟수"
  type        = number
  default     = 30
}

variable "ttl_seconds_after_finished" {
  description = "Job 완료 후 자동 정리 TTL(초). 0 또는 null이면 보존"
  type        = number
  default     = 3600
}

# SQL 오버라이드(원하면 이 변수들로 교체 가능)
variable "sql_init" {
  description = "V1__init.sql 콘텐츠 오버라이드"
  type        = string
  default     = null
}

variable "sql_pgvector" {
  description = "V2__pgvector.sql 콘텐츠 오버라이드"
  type        = string
  default     = null
}