# Team Environment Variables
# 전체 인프라를 배포할 때 외부에서 입력받을 변수 (!! 모듈 variable은 모듈 블럭에서만 !!)
# CIDR , NodeGroup , 환경명 , 공통태그

# Basic Configuration
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-northeast-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "team"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "goteego"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Subnet Configuration - Production Scale
variable "eks_private_subnets" {
  description = "Private subnets for EKS (2 AZs)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"] # EKS subnets
}

variable "postgresql_private_subnets" {
  description = "Private subnets for PostgreSQL (2 AZs)"
  type        = list(string)
  default     = ["10.0.20.0/24", "10.0.21.0/24"] # PostgreSQL subnets
}

variable "mongodb_private_subnets" {
  description = "Private subnets for MongoDB (2 AZs)"
  type        = list(string)
  default     = ["10.0.30.0/24", "10.0.31.0/24"] # MongoDB subnets
}

variable "elasticache_private_subnets" {
  description = "Private subnets for elasticache (2 AZs)"
  type        = list(string)
  default     = ["10.0.40.0/24", "10.0.41.0/24"] # elasticache subnets
}

# Network Security Configuration (Team - Production Ready)
variable "internet_cidr" {
  description = "CIDR block for internet access"
  type        = string
  default     = "0.0.0.0/0"
}

# SSM Configuration
variable "enable_ssm_endpoints" {
  description = "Enable SSM VPC endpoints for private subnet access"
  type        = bool
  default     = true
}

variable "enable_ssm_access" {
  description = "Enable SSM access for EKS nodes"
  type        = bool
  default     = true
}

variable "enable_node_group_limited_admin" {
  description = "Enable limited admin access for EKS node group (for cert-manager installation)"
  type        = bool
  default     = false
}

# EKS Configuration (Production Scale)
variable "eks_cluster_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.30" # stable version
}

variable "eks_node_groups" {
  description = "EKS node groups configuration"
  type = map(object({
    instance_types = list(string)
    min_size       = number
    max_size       = number
    desired_size   = number
    disk_size      = number
    ami_type       = string
    capacity_type  = string
  }))
  default = {
    "general" = {
      instance_types = ["t3.large"]  # ALB Controller 사용을 위해 업그레이드
      min_size       = 1
      max_size       = 2
      desired_size   = 1
      disk_size      = 20
      ami_type       = "AL2_x86_64"
      capacity_type  = "SPOT"
    },
    "compute" = {
      instance_types = ["t3.large"]  # ALB Controller 사용을 위해 업그레이드
      min_size       = 1
      max_size       = 2
      desired_size   = 1
      disk_size      = 20
      ami_type       = "AL2_x86_64"
      capacity_type  = "SPOT"
    }
  }
}

# EKS Advanced Configuration (Production Environment)
variable "max_unavailable_percentage" {
  description = "Maximum percentage of nodes unavailable during update"
  type        = number
  default     = 25 # Conservative for production stability
}

variable "cluster_log_retention_days" {
  description = "Number of days to retain cluster logs"
  type        = number
  default     = 7 # Longer retention for production
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed monitoring for production visibility"
  type        = bool
  default     = true # Enable for production monitoring
}

# High Availability Configuration
variable "enable_multi_az_deployment" {
  description = "Enable multi-AZ deployment for high availability"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30
}

# DB variables ==========
variable "postgresql_ami_id" {
  description = "PostgreSQL 서버에 사용할 AMI ID"
  type        = string
  default     = "ami-0f8d552e06067b477"
}

variable "mongodb_ami_id" {
  description = "MongoDB 서버에 사용할 AMI ID"
  type        = string
  default     = "ami-0f8d552e06067b477"
}

variable "db_instance_type" {
  description = "DB 서버에 사용할 EC2 인스턴스 타입"
  type        = string
  default     = "t3.medium" # 필요에 따라 조정
}

# DB variables ==========

# Database Configuration (for future use)
variable "db_password_postgresql" {
  description = "PostgreSQL database password"
  type        = string
  sensitive   = true
  default     = "" # Will be set via environment variable
}

variable "db_password_mongodb" {
  description = "MongoDB database password"
  type        = string
  sensitive   = true
  default     = "" # Will be set via environment variable
}

variable "db_password_elasticache" {
  description = "elasticache database password"
  type        = string
  sensitive   = true
  default     = "" # Will be set via environment variable
}

# Production Optimization Settings
variable "production_config" {
  description = "Production optimization settings"
  type = object({
    enable_backup           = bool
    enable_encryption       = bool
    enable_detailed_logging = bool
    enable_alerting         = bool
  })
  default = {
    enable_backup           = true
    enable_encryption       = true
    enable_detailed_logging = true
    enable_alerting         = true
  }
}

# Common Tags
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Environment = "team"
    Project     = "goteego"
    ManagedBy   = "terraform"
    CostCenter  = "production"
    Owner       = "teamf2"
    Account     = "teamf2"
    Purpose     = "production"
  }
}

variable "domain_name" {
  description = "domain_name"
  type        = string
  default     = "goteego.store"
}
variable "subject_alternative_names" {
  type        = list(string)
  default     = []
  description = "Optional list of Subject Alternative Names (SANs) for the ACM certificate"
}

variable "redis_auth_token" {
  description = "Redis AUTH token (min 16 characters)"
  type        = string
  sensitive   = true
}

# Monitoring variables ==========
## Alert Emails =========
variable "alert_emails" {
  type        = list(string)
  description = "alert email list"
  default     = [] # 혹은 null로 해도 무방
}

## Grafana admin password ==========
variable "grafana_admin_password" {
  description = "Grafana admin 비밀번호"
  type        = string
  sensitive   = true
  default     = "" # Will be set via environment variable
}

# GitOps Configuration
variable "gitops_repo_url" {
  description = "GitOps repository URL for ArgoCD application manifests"
  type        = string
  default     = ""
}

variable "github_username" {
  description = "GitHub username for GitOps repository"
  type        = string
  default     = ""
}
