# Team Environment Variables

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
  default     = "team2-infra"
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
  default     = ["10.0.10.0/24", "10.0.11.0/24"]  # EKS subnets
}

variable "postgresql_private_subnets" {
  description = "Private subnets for PostgreSQL (2 AZs)"
  type        = list(string)
  default     = ["10.0.20.0/24", "10.0.21.0/24"]  # PostgreSQL subnets
}

variable "mongodb_private_subnets" {
  description = "Private subnets for MongoDB (2 AZs)"
  type        = list(string)
  default     = ["10.0.30.0/24", "10.0.31.0/24"]  # MongoDB subnets
}

# Network Security Configuration (Team - Production Ready)
variable "internet_cidr" {
  description = "CIDR block for internet access"
  type        = string
  default     = "0.0.0.0/0"
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed to access EKS cluster endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # TODO: Restrict to office/VPN IPs in production
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

# EKS Configuration (Production Scale)
variable "eks_cluster_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.28"  # Latest stable version
}

variable "eks_node_groups" {
  description = "EKS node groups configuration (Production scale)"
  type = map(object({
    instance_types = list(string)
    min_size      = number
    max_size      = number
    desired_size  = number
    disk_size     = number
    ami_type      = string
    capacity_type = string
  }))
  default = {
    general = {
      instance_types = ["t3.medium", "t3.large"] # Production scale instances
      min_size      = 2
      max_size      = 10                          # Higher max for production
      desired_size  = 3                           # Higher desired for production
      disk_size     = 50                          # Larger disk for production
      ami_type      = "AL2_x86_64"
      capacity_type = "ON_DEMAND"                 # On-demand for production stability
    }
    compute = {
      instance_types = ["c5.large", "c5.xlarge"] # Compute optimized nodes
      min_size      = 1
      max_size      = 5
      desired_size  = 2
      disk_size     = 50
      ami_type      = "AL2_x86_64"
      capacity_type = "SPOT"                      # Mix of spot for cost optimization
    }
  }
}

# EKS Advanced Configuration (Production Environment)
variable "max_unavailable_percentage" {
  description = "Maximum percentage of nodes unavailable during update"
  type        = number
  default     = 25  # Conservative for production stability
}

variable "cluster_log_retention_days" {
  description = "Number of days to retain cluster logs"
  type        = number
  default     = 30  # Longer retention for production
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed monitoring for production visibility"
  type        = bool
  default     = true  # Enable for production monitoring
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

# Database Configuration (for future use)
variable "db_password_postgresql" {
  description = "PostgreSQL database password"
  type        = string
  sensitive   = true
  default     = ""  # Will be set via environment variable
}

variable "db_password_mongodb" {
  description = "MongoDB database password"
  type        = string
  sensitive   = true
  default     = ""  # Will be set via environment variable
}

# Production Optimization Settings
variable "production_config" {
  description = "Production optimization settings"
  type = object({
    enable_backup           = bool
    enable_encryption       = bool
    enable_detailed_logging = bool
    enable_alerting        = bool
  })
  default = {
    enable_backup           = true
    enable_encryption       = true
    enable_detailed_logging = true
    enable_alerting        = true
  }
}

# Common Tags
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Environment   = "team"
    Project       = "team2-infra"
    ManagedBy    = "terraform"
    CostCenter   = "production"
    Owner        = "team2"
    Account      = "team-production"
    Purpose      = "production-workloads"
  }
} 