# Team Account - Main Terraform Configuration

##test
# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  # Basic Configuration
  environment        = var.environment
  project_name       = var.project_name
  aws_region         = var.aws_region
  availability_zones = data.aws_availability_zones.available.names

  # VPC Configuration (Production Scale)
  vpc_cidr = var.vpc_cidr

  # Network Configuration
  internet_cidr = var.internet_cidr

  # Subnet Configuration - 8 Private Subnets
  eks_private_subnets        = var.eks_private_subnets
  postgresql_private_subnets = var.postgresql_private_subnets
  mongodb_private_subnets    = var.mongodb_private_subnets
  elasticache_private_subnets = var.elasticache_private_subnets

  # SSM Configuration
  enable_ssm_endpoints = var.enable_ssm_endpoints

  # Tags
  common_tags = var.common_tags
}

# EKS Module
module "eks" {
  source = "./modules/eks"

  # Dependencies
  vpc_id              = module.vpc.vpc_id
  vpc_cidr            = var.vpc_cidr
  eks_private_subnets = module.vpc.eks_private_subnets

  # Basic Configuration
  environment  = var.environment
  project_name = var.project_name
  cluster_name = "${var.project_name}-${var.environment}-cluster"

  # EKS Configuration (Production Scale)
  cluster_version = var.eks_cluster_version

  # Network Configuration
  internet_cidr = var.internet_cidr

  # Cluster Endpoint Configuration
  cluster_endpoint_config = {
    private_access      = true
    public_access       = false
    public_access_cidrs = ["0.0.0.0/0"] # 안써도 있긴있어야함
  }

  # Node Group Configuration (Production Scale)
  node_groups                = var.eks_node_groups
  max_unavailable_percentage = var.max_unavailable_percentage

  # Monitoring Configuration (Production)
  monitoring_enabled = var.enable_detailed_monitoring

  # SSM Access
  enable_ssm_access = var.enable_ssm_access

  # Tags
  common_tags = var.common_tags
}

# DB Module

module "postgresql_server" {
  source            = "./modules/postgresql_server"
  ami_id            = var.postgresql_ami_id
  instance_type     = var.db_instance_type
  subnet_id         = module.vpc.postgresql_private_subnets[0]
  security_group_ids = [module.vpc.postgresql_sg_id]
  # key_name          = var.key_name

  project_name      = var.project_name
  environment       = var.environment
  db_type           = "PostgreSQL"
  common_tags       = var.common_tags

  db_password       = var.db_password_postgresql
}

module "mongodb_server" {
  source            = "./modules/mongodb_server"
  ami_id            = var.mongodb_ami_id
  instance_type     = var.db_instance_type
  subnet_id         = module.vpc.mongodb_private_subnets[0]
  security_group_ids = [module.vpc.mongodb_sg_id]
  # key_name          = var.key_name

  project_name      = var.project_name
  environment       = var.environment
  db_type           = "MongoDB"
  common_tags       = var.common_tags

  db_password         = var.db_password_mongodb 
}

## SSM Parameter 등록 ======

resource "aws_ssm_parameter" "db_password_postgresql" {
  name  = "/${var.project_name}/${var.environment}/db_password_postgresql"
  type  = "SecureString"  # 암호화 저장
  value = var.db_password_postgresql
  tags  = var.common_tags
}

resource "aws_ssm_parameter" "db_password_mongodb" {
  name  = "/${var.project_name}/${var.environment}/db_password_mongodb"
  type  = "SecureString"
  value = var.db_password_mongodb
  tags  = var.common_tags
}

#==========================

module "my_irsa" {
  source = "./modules/irsa"  # or wherever your IRSA module is

  name                       = "my-app-sa"
  namespace                  = "default"
  cluster_oidc_provider_arn = module.eks.cluster_oidc_provider_arn
  cluster_oidc_issuer_url   = module.eks.cluster_oidc_issuer_url
  policy_arns               = [
    aws_iam_policy.ssm_parameter_read.arn
  ]
}


resource "aws_iam_policy" "ssm_parameter_read" {
  name        = "${var.project_name}-${var.environment}-ssm-parameter-read"
  description = "Policy to allow read access to SSM parameters"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "ssm:GetParameters",
          "ssm:GetParameter",
          "ssm:GetParameterHistory",
          "ssm:DescribeParameters"
        ],
        Resource = "*"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-ssm-parameter-read-policy"
  })
}

#==========================

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

