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

# OAC 생성 (한 번만)
module "cloudfront_oac" {
  source      = "./modules/cloudfront_oac"
  name        = "myapp-oac"
  description = "OAC for myapp CloudFront"
}


output "oac_id" {
  value = module.cloudfront_oac.oac_id
}

#s3======================

# s3_frontend (prod 환경 예시)
module "s3_frontend_prod" {
  source     = "./modules/s3_frontend"
  prefix     = "prod"
  bucket_name = "myapp-frontend"
  oac_id     = module.cloudfront_oac.oac_id
  cloudfront_distribution_arn = module.cloudfront_prod.aws_cloudfront_distribution_arn
}

# s3_backend (prod 환경 예시)
module "s3_backend_prod" {
  source       = "./modules/s3_backend"
  prefix       = "prod"
  bucket_name  = "myapp-backend"
  lifecycle_days = 30
}

output "frontend_bucket_name" {
  value = module.s3_frontend_prod.bucket_name
}

output "backend_bucket_name" {
  value = module.s3_backend_prod.bucket_name
}

#========================

#cloud_front

module "cloudfront_prod" {
  source                 = "./modules/cloudfront"
  prefix                 = "prod"
  oac_id                 = module.cloudfront_oac.oac_id
  s3_bucket_domain_name  = module.s3_frontend_prod.bucket_domain_name
  cloudfront_distribution_arn = module.cloudfront_prod.aws_cloudfront_distribution_arn

  acm_certificate_arn    = aws_acm_certificate.cert.arn
}


output "cloudfront_url" {
  value = module.cloudfront_prod.domain_name
}

output "cloudfront_id" {
  value = module.cloudfront_prod.distribution_id
}

output "cloudfront_domain_name" {
  value = module.cloudfront_prod.domain_name
  description = "CloudFront 배포 도메인 네임 (예: dxxxxx.cloudfront.net)"
}
#========================
#static_site

module "web_hosting" {
  source      = "./modules/web_hosting"  # 실제 모듈 경로로 수정하세요
  bucket_name = "goteego"         # 원하는 버킷 이름 넣기 (ex: prod-myapp-frontend)
  environment = var.environment
  project_name = var.project_name
}



resource "aws_route53_record" "frontend" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.goteego.store"    # www.goteego.shop
  type    = "A"

  # alias {
  #   name                   = module.web_hosting.website_endpoint      # S3 웹사이트 엔드포인트
  #   zone_id                = module.web_hosting.hosted_zone_id        # S3 웹사이트 호스팅 존 ID
  #   evaluate_target_health = false
  # }
  alias {
    name                   = module.cloudfront_prod.domain_name
    zone_id                = "Z2FDTNDATAQYW2"  # CloudFront 고정 Hosted Zone ID
    evaluate_target_health = false
  }

}


resource "aws_route53_record" "root" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "goteego.store"
  type    = "A"

  alias {
    name                   = module.cloudfront_prod.domain_name
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}

resource "aws_route53_zone" "main" {
  name = "goteego.store"
}

output "route53_zone_id" {
  description = "Route53 Hosted Zone ID without prefix"
  value       = replace(aws_route53_zone.main.zone_id, "/hostedzone/", "")
}

output "route53_zone_name" {
  value = aws_route53_zone.main.name
}

#================================
#ACM 인증서 요청

provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}

resource "aws_acm_certificate" "cert" {
  provider          = aws.virginia
  domain_name       = "goteego.store"
  validation_method = "DNS"

  subject_alternative_names = ["www.goteego.store","goteego.store"]

  lifecycle {
    create_before_destroy = true
  }
}

output "debug_acm_certificate_arn" {
  value = aws_acm_certificate.cert.arn
}



# DNS 검증용 레코드 Route53에 생성
resource "aws_route53_record" "cert_validation" {
  provider = aws.virginia
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = aws_route53_zone.main.zone_id  # goteego.shop 호스팅 존 ID 여야 함
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60

  depends_on = [aws_acm_certificate.cert]
}
# ACM 인증서 DNS 검증을 최종적으로 완료 -> 인증서를 ISSUED 상태로 전환
resource "aws_acm_certificate_validation" "cert_validation" {
  provider                = aws.virginia
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

  depends_on = [aws_route53_record.cert_validation]
}
#==================================

# 루트 도메인 A 레코드 생성

resource "aws_route53_record" "root" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "goteego.store"  
  type    = "A"

  alias {
    name                   = module.cloudfront_prod.domain_name
    zone_id                = "Z2FDTNDATAQYW2"  # CloudFront 고정 Hosted Zone ID
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "frontend" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.goteego.store"  
  type    = "A"

  alias {
    name                   = module.cloudfront_prod.domain_name
    zone_id                = "Z2FDTNDATAQYW2"  # CloudFront 고정 Hosted Zone ID
    evaluate_target_health = false
  }
}