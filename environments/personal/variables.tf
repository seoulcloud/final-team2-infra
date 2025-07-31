# Personal Environment Variables

# Basic Configuration
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-northeast-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "personal"
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

# Subnet Configuration - Free Tier Optimized
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

# Network Security Configuration (Personal - More Restrictive for Testing)
variable "internet_cidr" {
  description = "CIDR block for internet access"
  type        = string
  default     = "0.0.0.0/0" # Can be restricted for personal use
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed to access EKS cluster endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Consider restricting to your IP for personal use
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

# EKS Configuration (Free Tier)
variable "eks_cluster_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.28" # Latest stable version
}

variable "eks_node_groups" {
  description = "EKS node groups configuration (Free Tier optimized)"
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
    general = {
      instance_types = ["t3.small"] # Free Tier eligible
      min_size       = 1
      max_size       = 2 # Keep minimal for cost
      desired_size   = 1
      disk_size      = 20 # Minimal disk size
      ami_type       = "AL2_x86_64"
      capacity_type  = "SPOT" # Use spot instances for cost saving
    }
  }
}

# EKS Advanced Configuration (Personal Environment Optimized)
variable "max_unavailable_percentage" {
  description = "Maximum percentage of nodes unavailable during update"
  type        = number
  default     = 50 # Higher percentage OK for personal testing environment
}

variable "cluster_log_retention_days" {
  description = "Number of days to retain cluster logs"
  type        = number
  default     = 7 # Shorter retention for cost saving
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed monitoring for cost optimization"
  type        = bool
  default     = false # Disable for cost saving in personal environment
}

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

# Cost Optimization Settings for Personal Account
variable "cost_optimization" {
  description = "Cost optimization settings for personal account"
  type = object({
    use_spot_instances = bool
    minimal_logging    = bool
    reduced_monitoring = bool
    smaller_disk_size  = bool
  })
  default = {
    use_spot_instances = true # Use spot for cost saving
    minimal_logging    = true # Reduce logging costs
    reduced_monitoring = true # Reduce monitoring costs
    smaller_disk_size  = true # Use smaller disks
  }
}

# Common Tags
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Environment = "personal"
    Project     = "team2-infra"
    ManagedBy   = "terraform"
    CostCenter  = "development"
    Owner       = "team2"
    Account     = "personal-freetier"
    Purpose     = "testing-development"
  }
} 