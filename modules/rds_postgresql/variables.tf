# 프로젝트 기본 정보
variable "project_name" {
  description = "Project name for tagging and resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
}

# RDS 엔진 버전
variable "engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "14.13"
}

# 인스턴스 사양
variable "instance_class" {
  description = "RDS instance type (e.g., db.t3.medium)"
  type        = string
  default     = "db.t3.micro"
}

# 스토리지 설정
variable "allocated_storage" {
  description = "Initial allocated storage in GB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum allocated storage in GB"
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "RDS storage type (e.g., gp2, gp3)"
  type        = string
  default     = "gp2"
}

# DB 기본 설정
variable "db_name" {
  description = "The name of the initial database to create"
  type        = string
}

variable "db_username" {
  description = "Master username for RDS"
  type        = string
}

variable "db_password" {
  description = "Master password for RDS"
  type        = string
  sensitive   = true
}

# 파라미터 그룹
variable "parameter_group_name" {
  description = "Parameter group for PostgreSQL"
  type        = string
  default     = "default.postgres14"
}

# 고가용성 및 백업
variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 3
}

# 네트워크 설정
variable "vpc_security_group_ids" {
  description = "List of VPC security group IDs for the RDS instance"
  type        = list(string)
}

variable "db_subnet_group_name" {
  description = "The name of the DB subnet group to use"
  type        = string
}

# 공통 태그
variable "tags" {
  description = "Tags for the RDS instance"
  type        = map(string)
}