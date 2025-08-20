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
  eks_private_subnets         = var.eks_private_subnets
  postgresql_private_subnets  = var.postgresql_private_subnets
  mongodb_private_subnets     = var.mongodb_private_subnets
  elasticache_private_subnets = var.elasticache_private_subnets

  # SSM Configuration
  enable_ssm_endpoints = var.enable_ssm_endpoints

  # Tags
  common_tags = var.common_tags
  # eks node sg
  eks_node_security_group = module.eks.node_group_security_group_id
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

  # Cluster Endpoint Configuration (배포 후 콘솔에서 private로 변경)
  cluster_endpoint_config = {
    private_access      = true
    public_access       = true          # Terraform Cloud 배포를 위해 임시 활성화
    public_access_cidrs = ["0.0.0.0/0"] # 배포 완료 후 콘솔에서 private로 변경
  }

  # Node Group Configuration (Production Scale)
  node_groups                = var.eks_node_groups
  max_unavailable_percentage = var.max_unavailable_percentage

  # Monitoring Configuration (Production)
  monitoring_enabled = var.enable_detailed_monitoring

  # SSM Access
  enable_ssm_access = var.enable_ssm_access

  # Node Group Limited Admin Access (for cert-manager installation)
  enable_node_group_limited_admin = var.enable_node_group_limited_admin

  # Tags
  common_tags = var.common_tags
}

# RDS PostgreSQL DB Module
module "rds" {
  source = "./modules/rds"

  # 프로젝트 기본 설정
  project_name = var.project_name
  environment  = var.environment

  # 엔진 및 인스턴스 설정 (프리티어 기준)
  engine_version        = "14.13"
  instance_class        = "db.t3.micro"
  allocated_storage     = 20
  max_allocated_storage = 20
  storage_type          = "gp2"

  # DB 정보
  db_name              = var.project_name
  db_username          = var.project_name
  db_password          = var.db_password_postgresql
  parameter_group_name = "default.postgres14"

  # 가용성 및 백업
  multi_az                = true
  backup_retention_period = 3

  # 네트워크 설정
  db_subnet_group_name   = module.vpc.db_subnet_group_name
  vpc_security_group_ids = [module.vpc.postgresql_sg_id]

  # 태그
  tags = var.common_tags
}

# DocumentDB Cluster Module
module "documentdb" {
  source = "./modules/documentdb"

  # 프로젝트 기본 설정
  project_name = var.project_name
  environment  = var.environment

  # DB 계정 정보
  db_username = var.project_name
  db_password = var.db_password_mongodb

  # 인스턴스 설정
  instance_class = "db.t3.medium" # DocumentDB 최소 사양
  instance_count = 1

  # 백업 설정
  backup_retention_period = 3

  # 네트워크 설정
  db_subnet_group_name   = module.vpc.docdb_subnet_group_name
  vpc_security_group_ids = [module.vpc.mongodb_sg_id]

  # 태그
  tags = var.common_tags
}

## SSM Parameter 등록 ====== test

resource "aws_ssm_parameter" "db_password_postgresql" {
  name       = "/${var.project_name}/${var.environment}/db_password_postgresql"
  type       = "SecureString" # 암호화 저장
  value      = var.db_password_postgresql
  overwrite  = true
  tags       = var.common_tags
  depends_on = [module.rds]
}

resource "aws_ssm_parameter" "db_password_mongodb" {
  name       = "/${var.project_name}/${var.environment}/db_password_mongodb"
  type       = "SecureString"
  value      = var.db_password_mongodb
  overwrite  = true
  tags       = var.common_tags
  depends_on = [module.documentdb]
}

# Output important values - moved to outputs.tf


# OAC ===========

# OAC 생성
module "cloudfront_oac" {
  source      = "./modules/cloudfront_oac"
  name        = "${var.project_name}-${var.environment}-oac"
  description = "OAC for CloudFront"
}

# output "oac_id" {
#   value = module.cloudfront_oac.oac_id
# }

#s3======================

# s3_frontend (prod 환경)
module "s3_frontend_prod" {
  source      = "./modules/s3_frontend"
  prefix      = "prod"
  bucket_name = "${var.project_name}-frontend"
}


resource "aws_s3_bucket_policy" "frontend_policy" {
  bucket = module.s3_frontend_prod.bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "cloudfront.amazonaws.com"
      }
      Action   = "s3:GetObject"
      Resource = "${module.s3_frontend_prod.bucket_arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = module.cloudfront_prod.distribution_arn
        }
      }
    }]
  })

  depends_on = [
    module.s3_frontend_prod,
    module.cloudfront_prod,
  ]
}


# s3_backend (prod 환경)  -> 백엔드에서 s3 사용 안함
# module "s3_backend_prod" {
#   source         = "./modules/s3_backend"
#   prefix         = "prod"
#   bucket_name    = "${var.project_name}-backend"
#   lifecycle_days = 30
# }

# output "frontend_bucket_name" {
#   value = module.s3_frontend_prod.bucket_name
# }

# output "backend_bucket_name" {
#   value = module.s3_backend_prod.bucket_name
# }




#========================

#cloud_front

module "cloudfront_prod" {
  source                = "./modules/cloudfront"
  prefix                = "prod"
  oac_id                = module.cloudfront_oac.oac_id
  s3_bucket_domain_name = module.s3_frontend_prod.bucket_domain_name
  acm_certificate_arn   = module.acm_cert.certificate_arn
  aliases               = [var.domain_name, "www.${var.domain_name}"]

  depends_on = [
    module.acm_dns_validation,
    module.cloudfront_oac,
    module.s3_frontend_prod
  ]
}

# ACM for ALB/EKS in ap-northeast-2 (wildcard)
module "acm_cert_kor" {
  source    = "./modules/acm_certificate"
  providers = { aws = aws }  # 기본 provider (ap-northeast-2)

  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}", "dev.api.${var.domain_name}", "argocd.${var.domain_name}"]
}

module "acm_kor_dns_validation" {
  source    = "./modules/acm_dns_validation"
  providers = { aws = aws }  # 기본 provider (ap-northeast-2)

  certificate_arn                       = module.acm_cert_kor.certificate_arn
  zone_id                               = aws_route53_zone.main.zone_id
  certificate_domain_validation_options = module.acm_cert_kor.domain_validation_options

  depends_on = [
    aws_route53_zone.main,
    module.acm_cert_kor
  ]
}

# ExternalDNS to manage Route53 records from Ingress
module "external_dns" {
  source = "./modules/external-dns"

  project_name = var.project_name
  environment  = var.environment
  namespace    = "kube-system"

  cluster_oidc_provider_arn = module.eks.cluster_oidc_provider_arn
  cluster_oidc_issuer_url   = module.eks.cluster_oidc_issuer_url

  domain_filters = [var.domain_name]
  hosted_zone_id = aws_route53_zone.main.zone_id
  sources        = ["ingress"]
  policy         = "upsert-only"
  registry       = "txt"

  common_tags = var.common_tags

  depends_on = [module.eks, aws_route53_zone.main]
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
  source     = "./modules/web_hosting"
  bucket_id  = module.s3_frontend_prod.bucket_id
  bucket_arn = module.s3_frontend_prod.bucket_arn
  # bucket_name  = module.s3_frontend_prod.bucket_name
  environment  = var.environment
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
  source    = "./modules/acm_certificate"
  providers = { aws = aws.virginia }

  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
}

# output "certificate_arn" {
#   value = module.acm_cert.certificate_arn
# }

# ACM DNS 검증용 레코드 생성 
module "acm_dns_validation" {
  source    = "./modules/acm_dns_validation"
  providers = { aws = aws.virginia }

  certificate_arn                       = module.acm_cert.certificate_arn
  zone_id                               = aws_route53_zone.main.zone_id
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

# PostgreSQL (RDS)
resource "aws_route53_record" "rds_endpoint" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "pg-db.${var.domain_name}" # 예: pg-db.goteego.store
  type    = "CNAME"
  ttl     = 300
  records = [module.rds.db_instance_endpoint] # RDS 모듈 output
}

# MongoDB (DocumentDB)
resource "aws_route53_record" "mongodb_endpoint" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "mongo-db.${var.domain_name}" # 예: mongo-db.goteego.store
  type    = "CNAME"
  ttl     = 300
  records = [module.documentdb.docdb_cluster_endpoint] # DocumentDB 모듈 output
}

# Redis (ElastiCache)
resource "aws_route53_record" "redis_endpoint" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "redis.${var.domain_name}" # 예: redis.goteego.store
  type    = "CNAME"
  ttl     = 300
  records = [module.elasticache.primary_endpoint_address] # ElastiCache 모듈 output
}

# Grafana 외부 접속용 도메인(grafana.goteego.store)
# resource "aws_route53_record" "grafana" {
#   zone_id = aws_route53_zone.main.zone_id
#   name    = "grafana.${var.domain_name}"
#   type    = "CNAME"
#   ttl     = 300
#
#   records = [module.grafana.grafana_alb_dns]
#   depends_on = [module.grafana]
# }

data "kubernetes_service" "hpa_service" {
  metadata {
    name      = "hpa-test-external-svc"
    namespace = "autoscale-dev"
  }
  depends_on = [module.autoscale, module.alb]
}

# AutoScaling HPA
resource "aws_route53_record" "autoscaling" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "hpa.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [data.kubernetes_service.hpa_service.status[0].load_balancer[0].ingress[0].hostname]
  depends_on = [module.autoscale, module.alb]
}


# elasticache ==========================
#test
module "elasticache" {
  source             = "./modules/elasticache"
  project_name       = var.project_name
  environment        = var.environment
  subnet_ids         = module.vpc.elasticache_private_subnets
  security_group_ids = [module.vpc.elasticache_sg_id]
  node_type          = "cache.t3.micro"
  num_cache_nodes    = 1
  redis_auth_token   = var.redis_auth_token
  common_tags        = var.common_tags
  depends_on         = [module.eks]
}
# redis_auth_parameter
resource "aws_ssm_parameter" "redis_auth_token" {
  name      = "/${var.project_name}/${var.environment}/redis_auth_token"
  type      = "SecureString" # 보안 문자열로 저장
  value     = var.redis_auth_token
  overwrite = true
  tags      = var.common_tags
}

# Kubernetes Secrets Module - Dev 환경
module "kubernetes_secrets_dev" {
  source = "./modules/kubernetes_secrets"

  namespace_name = "backend-dev"
  namespace_labels = {
    environment = "dev"
    app         = "backend-api"
  }

  secret_name = "db-secrets"
  secret_labels = {
    environment = "dev"
    app         = "backend-api"
  }

  db_password_postgresql = var.db_password_postgresql
  db_password_mongodb    = var.db_password_mongodb
  redis_auth_token       = var.redis_auth_token

  eks_dependency = module.eks
  ssm_parameters_dependency = [
    aws_ssm_parameter.db_password_postgresql,
    aws_ssm_parameter.db_password_mongodb,
    aws_ssm_parameter.redis_auth_token
  ]
}

# Kubernetes Secrets Module - Prod 환경
module "kubernetes_secrets_prod" {
  source = "./modules/kubernetes_secrets"

  namespace_name = "backend-prod"
  namespace_labels = {
    environment = "prod"
    app         = "backend-api"
  }

  secret_name = "db-secrets"
  secret_labels = {
    environment = "prod"
    app         = "backend-api"
  }

  db_password_postgresql = var.db_password_postgresql
  db_password_mongodb    = var.db_password_mongodb
  redis_auth_token       = var.redis_auth_token

  eks_dependency = module.eks
  ssm_parameters_dependency = [
    aws_ssm_parameter.db_password_postgresql,
    aws_ssm_parameter.db_password_mongodb,
    aws_ssm_parameter.redis_auth_token
  ]
}
# ========================================
# Kubernetes Applications (cert-manager & ArgoCD)
# ========================================


# ArgoCD namespace
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"

    labels = {
      "name"                         = "argocd"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  depends_on = [module.eks]
}


# ALB Module
module "alb" {
  source = "./modules/alb"

  # Basic Configuration
  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  cluster_name = module.eks.cluster_name

  # Network Configuration
  public_subnets = module.vpc.public_subnets

  # OIDC Configuration
  cluster_oidc_issuer_url   = module.eks.cluster_oidc_issuer_url
  cluster_oidc_provider_arn = module.eks.cluster_oidc_provider_arn

  # Security Configuration
  node_group_security_group_id = module.eks.node_group_security_group_id

  # Domain Configuration
  domain_name     = var.domain_name
  zone_id         = aws_route53_zone.main.zone_id
  certificate_arn = module.acm_cert.certificate_arn

  # Tags
  common_tags = var.common_tags

  depends_on = [
    module.eks,
    module.vpc,
    module.acm_cert
  ]
}



# ArgoCD Helm chart
module "argocd" {
  source        = "./modules/argocd"
  namespace     = kubernetes_namespace.argocd.metadata[0].name
  chart_version = "8.2.5" # 버전관리는 루트에서 모듈은 에러방지
  timeout       = 900     # 900초 대기 (EKS 설치 대기)

  alb_security_group_id = module.alb.alb_security_group_id

  # TLS settings
  certificate_arn  = module.acm_cert_kor.certificate_arn
  ssl_redirect     = "443"
  insecure         = false
  ingress_hostname = "argocd.${var.domain_name}"
  ingress_hosts    = ["argocd.${var.domain_name}"]

  depends_on = [
    module.eks,
    kubernetes_namespace.argocd,
    module.alb,
    module.acm_kor_dns_validation
  ]
}

# ArgoCD Ingress hostname (Kubernetes data source)
# data "kubernetes_ingress_v1" "argocd" {
#   metadata {
#     name      = "argocd-server"
#     namespace = kubernetes_namespace.argocd.metadata[0].name
#   }
#
#   depends_on = [
#     module.argocd
#   ]
# }

# Safely extract ALB hostname (may be empty on first apply)
# locals {
#   argocd_ingress_hostname = try(
#     data.kubernetes_ingress_v1.argocd.status[0].load_balancer[0].ingress[0].hostname,
#     null
#   )
# }

# Route53 CNAME for ArgoCD: argocd.<domain> → ALB hostname
# resource "aws_route53_record" "argocd" {
#   count   = local.argocd_ingress_hostname != null && length(local.argocd_ingress_hostname) > 0 ? 1 : 0
#   zone_id = aws_route53_zone.main.zone_id
#   name    = "argocd.${var.domain_name}"
#   type    = "CNAME"
#   ttl     = 300
#
#   records = [local.argocd_ingress_hostname]
#
#   depends_on = [
#     aws_route53_zone.main,
#     module.argocd
#   ]
# }

# Route53 CNAME for prod API: api.<domain> → provided hostname (conditional)
# resource "aws_route53_record" "api_prod" {
#   count   = length(var.prod_backend_hostname) > 0 ? 1 : 0
#   zone_id = aws_route53_zone.main.zone_id
#   name    = "api.${var.domain_name}"
#   type    = "CNAME"
#   ttl     = 300
#   records = [var.prod_backend_hostname]
# }

# Route53 CNAME for dev API: dev.api.<domain> → provided hostname (conditional)
# resource "aws_route53_record" "api_dev" {
#   count   = length(var.dev_backend_hostname) > 0 ? 1 : 0
#   zone_id = aws_route53_zone.main.zone_id
#   name    = "dev.api.${var.domain_name}"
#   type    = "CNAME"
#   ttl     = 300
#   records = [var.dev_backend_hostname]
# }
# ALB → EKS NodeGroup SG: ArgoCD 서버 targetPort(8080) 허용
resource "aws_security_group_rule" "allow_alb_to_nodes_argo_8080" {
  type                     = "ingress"
  description              = "Allow ALB to reach ArgoCD server on targetPort 8080"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = module.eks.node_group_security_group_id
  source_security_group_id = module.alb.alb_security_group_id

  depends_on = [
    module.alb,
    module.eks
  ]
}

# EKS 클러스터와 Helm 차트는 Terraform으로 자동 배포됩니다
# GitOps 설정만 수동으로 진행하면 됩니다



# ALB Module Outputs
output "alb_controller_role_arn" {
  description = "AWS Load Balancer Controller IAM Role ARN"
  value       = module.alb.aws_load_balancer_controller_role_arn
}

output "alb_security_group_id" {
  description = "ALB Security Group ID"
  value       = module.alb.alb_security_group_id
}

output "alb_controller_status" {
  description = "AWS Load Balancer Controller installation status"
  value       = "AWS Load Balancer Controller installed with IRSA support"
}

# Backend API IRSA Module
module "backend_api_irsa" {
  source = "./modules/irsa"

  name      = "backend-api"
  namespace = "backend-prod" # 기본값으로 prod 사용

  cluster_oidc_issuer_url   = module.eks.cluster_oidc_issuer_url
  cluster_oidc_provider_arn = module.eks.cluster_oidc_provider_arn
  project_name              = var.project_name
  environment               = var.environment

  create_backend_api_role = true
  common_tags             = var.common_tags

  depends_on = [module.eks]
}

# Frontend Deploy
module "github_oidc_roles" {
  source = "./modules/github_oidc_roles"

  github_org                 = "CLD-3rd"
  github_repo                = "final-team2-frontend"
  s3_bucket_name             = module.s3_frontend_prod.bucket_name
  cloudfront_distribution_id = module.cloudfront_prod.distribution_id
}


# autoscale ================

module "autoscale" {
  source        = "./modules/autoscale"
  cluster_name  = module.eks.cluster_name
  project_name              = var.project_name
  environment               = var.environment
 # alb_arn              = module.alb.alb_arn       
 # alb_target_group_arn = module.alb.backend_tg_arn  

depends_on = [ module.eks, module.alb ]
}
