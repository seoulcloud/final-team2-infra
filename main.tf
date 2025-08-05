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
  depends_on  = [module.eks]
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
  depends_on  = [module.eks]
}

## SSM Parameter 등록 ====== test

resource "aws_ssm_parameter" "db_password_postgresql" {
  name  = "/${var.project_name}/${var.environment}/db_password_postgresql"
  type  = "SecureString"  # 암호화 저장
  value = var.db_password_postgresql
  tags  = var.common_tags
  depends_on  = [module.postgresql_server]
}

resource "aws_ssm_parameter" "db_password_mongodb" {
  name  = "/${var.project_name}/${var.environment}/db_password_mongodb"
  type  = "SecureString"
  value = var.db_password_mongodb
  tags  = var.common_tags
  depends_on  = [module.mongodb_server]
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


# OAC ===========

# OAC 생성
module "cloudfront_oac" {
  source      = "./modules/cloudfront_oac"
  name        = "myapp-oac"
  description = "OAC for myapp CloudFront"
}


# output "oac_id" {
#   value = module.cloudfront_oac.oac_id
# }

#s3======================

# s3_frontend (prod 환경)
module "s3_frontend_prod" {
  source     = "./modules/s3_frontend"
  prefix     = "prod"
  bucket_name = "myapp-frontend"
  oac_id     = module.cloudfront_oac.oac_id
  # cloudfront_distribution_arn = module.cloudfront_prod.aws_cloudfront_distribution_arn
}

# s3_backend (prod 환경)
module "s3_backend_prod" {
  source       = "./modules/s3_backend"
  prefix       = "prod"
  bucket_name  = "myapp-backend"
  lifecycle_days = 30
}

# output "frontend_bucket_name" {
#   value = module.s3_frontend_prod.bucket_name
# }

# output "backend_bucket_name" {
#   value = module.s3_backend_prod.bucket_name
# }

#========================

#cloud_front

module "cloudfront_prod" {
  source                 = "./modules/cloudfront"
  prefix                 = "prod"
  oac_id                 = module.cloudfront_oac.oac_id
  s3_bucket_domain_name  = module.s3_frontend_prod.bucket_domain_name
   acm_certificate_arn   = module.acm_cert.certificate_arn

   depends_on = [
    module.acm_dns_validation,
    module.cloudfront_oac,
    module.s3_frontend_prod
  ]
}


# output "cloudfront_url" {
#   value = module.cloudfront_prod.domain_name
# }

# output "cloudfront_id" {
#   value = module.cloudfront_prod.distribution_id
# }

# output "cloudfront_domain_name" {
#   value = module.cloudfront_prod.domain_name
#   description = "CloudFront 배포 도메인 네임 (예: dxxxxx.cloudfront.net)"
# }
#========================
#static_site

module "web_hosting" {
  source      = "./modules/web_hosting"  
  bucket_name = module.s3_frontend_prod.bucket_name  
  environment = var.environment
  project_name = var.project_name
}

provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}

# Route53 존 생성 (최상위, 독립)

resource "aws_route53_zone" "main" {
  name = var.domain_name # "goteego.store" 대신 변수 사용
}

# output "zone_id" {
#   value = aws_route53_zone.main.zone_id
# }

# ACM 인증서 생성 (us-east-1 리전 지정 provider)
module "acm_cert" {
  source = "./modules/acm_certificate"
  providers = { aws = aws.virginia }

  domain_name = var.domain_name
  subject_alternative_names = var.subject_alternative_names
}

# output "certificate_arn" {
#   value = module.acm_cert.certificate_arn
# }

# ACM DNS 검증용 레코드 생성 
module "acm_dns_validation" {
  source = "./modules/acm_dns_validation"
  providers = { aws = aws.virginia }

  certificate_arn = module.acm_cert.certificate_arn
  zone_id        = aws_route53_zone.main.zone_id
  certificate_domain_validation_options = module.acm_cert.domain_validation_options

  depends_on = [
    aws_route53_zone.main,
    module.acm_cert
  ]
}


# Route53 레코드 (CloudFront 도메인)
resource "aws_route53_record" "root" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"
  alias {
    name                   = module.cloudfront_prod.domain_name
    zone_id                = "Z2FDTNDATAQYW2" # CloudFront 고정 Hosted Zone ID
    evaluate_target_health = false
  }
  depends_on = [
    aws_route53_zone.main,
    module.cloudfront_prod
  ]
}

resource "aws_route53_record" "frontend" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"
  alias {
    name                   = module.cloudfront_prod.domain_name
    zone_id                = "Z2FDTNDATAQYW2" # CloudFront 고정 Hosted Zone ID
    evaluate_target_health = false
  }
  depends_on = [
    aws_route53_zone.main,
    module.cloudfront_prod
  ]
}

# ==========================
