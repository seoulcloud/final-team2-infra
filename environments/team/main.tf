# Team Account - Main Terraform Configuration
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
###
#####
  # Backend configuration for state management
  # Using local state for development
  # Uncomment below for S3 remote state:
  # backend "s3" {
  #   bucket         = "terraform-state-team-team2"
  #   key            = "team/terraform.tfstate"
  #   region         = "ap-northeast-2"
  #   dynamodb_table = "terraform-lock-team-team2"
  #   encrypt        = true
  # }
}

# Configure AWS Provider for Team Account
provider "aws" {
  region  = var.aws_region
  profile = "default"  # AWS CLI profile for team account
  
  default_tags {
    tags = var.common_tags
  }
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"
  
  # Basic Configuration
  environment         = var.environment
  project_name        = var.project_name
  aws_region         = var.aws_region
  availability_zones = data.aws_availability_zones.available.names
  
  # VPC Configuration (Production Scale)
  vpc_cidr = var.vpc_cidr
  
  # Network Configuration
  internet_cidr = var.internet_cidr
  
  # Subnet Configuration - 6 Private Subnets
  eks_private_subnets        = var.eks_private_subnets
  postgresql_private_subnets = var.postgresql_private_subnets
  mongodb_private_subnets    = var.mongodb_private_subnets
  
  # SSM Configuration
  enable_ssm_endpoints = var.enable_ssm_endpoints
  
  # Tags
  common_tags = var.common_tags
}

# EKS Module
module "eks" {
  source = "../../modules/eks"
  
  # Dependencies
  vpc_id              = module.vpc.vpc_id
  vpc_cidr            = var.vpc_cidr
  eks_private_subnets = module.vpc.eks_private_subnets
  
  # Basic Configuration
  environment    = var.environment
  project_name   = var.project_name
  cluster_name   = "${var.project_name}-${var.environment}-cluster"
  
  # EKS Configuration (Production Scale)
  cluster_version = var.eks_cluster_version
  
  # Network Configuration
  internet_cidr = var.internet_cidr
  
  # Cluster Endpoint Configuration
  cluster_endpoint_config = {
    private_access      = true
    public_access       = true
    public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  }
  
  # Node Group Configuration (Production Scale)
  node_groups = var.eks_node_groups
  max_unavailable_percentage = var.max_unavailable_percentage
  
  # Monitoring Configuration (Production)
  monitoring_enabled = var.enable_detailed_monitoring
  
  # SSM Access
  enable_ssm_access = var.enable_ssm_access
  
  # Tags
  common_tags = var.common_tags
}

# Output important values
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "eks_cluster_endpoint" {
  description = "EKS Cluster Endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_name" {
  description = "EKS Cluster Name"
  value       = module.eks.cluster_name
}

output "ssm_session_manager_url" {
  description = "SSM Session Manager Connection Guide"
  value       = "Use 'aws ssm start-session --target <instance-id> --profile default' to connect"
} 