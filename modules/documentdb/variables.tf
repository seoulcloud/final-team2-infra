# 프로젝트 기본 정보
variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
}

# DocumentDB 사용자 인증
variable "db_username" {
  description = "Master username for DocumentDB cluster"
  type        = string
}

variable "db_password" {
  description = "Master password for DocumentDB cluster"
  type        = string
  sensitive   = true
}

# 인스턴스 및 클러스터 설정
variable "instance_class" {
  description = "DocumentDB instance class (e.g., db.r5.large)"
  type        = string
  default     = "db.r5.large"
}

variable "instance_count" {
  description = "Number of instances in DocumentDB cluster (recommended: 2 for HA)"
  type        = number
  default     = 2
}

variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 3
}

# 네트워크 설정
variable "db_subnet_group_name" {
  description = "The name of the DB subnet group"
  type        = string
}

variable "vpc_security_group_ids" {
  description = "List of VPC security group IDs for the DocumentDB cluster"
  type        = list(string)
}

# 공통 태그
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}