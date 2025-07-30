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
  }
} 