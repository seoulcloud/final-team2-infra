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
    public_access       = true   # Terraform Cloud 배포를 위해 임시 활성화
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
module "rds_postgresql" {
  source = "./modules/rds_postgresql"

  # 프로젝트 기본 설정
  project_name = var.project_name
  environment  = var.environment

  # 엔진 및 인스턴스 설정 (프리티어 기준)
  engine_version          = "14.13"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  max_allocated_storage   = 20
  storage_type            = "gp2"

  # DB 정보
  db_name      = var.project_name
  db_username  = var.project_name
  db_password  = var.db_password_postgresql
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
  name  = "/${var.project_name}/${var.environment}/db_password_postgresql"
  type  = "SecureString"  # 암호화 저장
  value = var.db_password_postgresql
  tags  = var.common_tags
  depends_on  = [module.rds_postgresql]
}

resource "aws_ssm_parameter" "db_password_mongodb" {
  name       = "/${var.project_name}/${var.environment}/db_password_mongodb"
  type       = "SecureString"
  value      = var.db_password_mongodb
  tags       = var.common_tags
  depends_on = [module.documentdb]
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
  source      = "./modules/s3_frontend"
  prefix      = "prod"
  bucket_name = "myapp-frontend"
  oac_id      = module.cloudfront_oac.oac_id
  # cloudfront_distribution_arn = module.cloudfront_prod.aws_cloudfront_distribution_arn
}

# s3_backend (prod 환경)
module "s3_backend_prod" {
  source         = "./modules/s3_backend"
  prefix         = "prod"
  bucket_name    = "myapp-backend"
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
  source                = "./modules/cloudfront"
  prefix                = "prod"
  oac_id                = module.cloudfront_oac.oac_id
  s3_bucket_domain_name = module.s3_frontend_prod.bucket_domain_name
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
  source       = "./modules/web_hosting"
  bucket_name  = module.s3_frontend_prod.bucket_name
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


# elasticache ==========================
#test
module "elasticache" {
  source = "./modules/elasticache"
  project_name        = var.project_name
  environment         = var.environment
  subnet_ids          = module.vpc.elasticache_private_subnets
  security_group_ids  = [module.vpc.elasticache_sg_id]
  node_type           = "cache.t3.micro"
  num_cache_nodes     = 1
  redis_auth_token    = var.redis_auth_token
  common_tags         = var.common_tags
  depends_on = [module.eks]
}
# redis_auth_parameter
resource "aws_ssm_parameter" "redis_auth_token" {
  name  = "/${var.project_name}/${var.environment}/redis_auth_token"
  type  = "SecureString"  # 보안 문자열로 저장
  value = var.redis_auth_token 
  tags = var.common_tags

}
# ========================================
# Kubernetes Applications (cert-manager & ArgoCD)
# ========================================

# cert-manager namespace
resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"

    labels = {
      "name"                         = "cert-manager"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  depends_on = [module.eks]
}

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

# IRSA for cert-manager (기존 모듈 활용)
module "cert_manager_irsa" {
  source = "./modules/irsa"

  name      = "cert-manager"
  namespace = kubernetes_namespace.cert_manager.metadata[0].name
  cluster_oidc_issuer_url   = module.eks.cluster_oidc_issuer_url
  cluster_oidc_provider_arn = module.eks.cluster_oidc_provider_arn
  project_name              = var.project_name
  environment               = var.environment
  hosted_zone_arn           = aws_route53_zone.main.arn
  common_tags               = var.common_tags

  depends_on = [
    module.eks,
    kubernetes_namespace.cert_manager
  ]
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

# cert-manager Helm chart
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.13.3"
  namespace  = kubernetes_namespace.cert_manager.metadata[0].name

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "serviceAccount.create"
    value = "false" # IRSA 모듈에서 생성한 서비스 어카운트 사용
  }

  set {
    name  = "serviceAccount.name"
    value = module.cert_manager_irsa.service_account_name
  }

  set {
    name  = "securityContext.fsGroup"
    value = "1001"
  }

  depends_on = [
    module.cert_manager_irsa,
    kubernetes_namespace.cert_manager
  ]
}

# ALB Controller 배포 후 대기 시간
resource "time_sleep" "wait_for_alb_controller" {
  depends_on = [module.alb]
  
  create_duration = "900s"  # 900초 대기 (ALB Controller 완전 초기화 대기)
}

# ArgoCD Helm chart
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.51.6"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  timeout    = 900  # 15분으로 타임아웃 증가

  # ArgoCD Server 설정
  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "server.extraArgs[0]"
    value = "--insecure" # HTTPS 리다이렉트 비활성화 (ALB에서 처리)
  }

  # ArgoCD Config
  set {
    name  = "configs.params.server\\.insecure"
    value = "true"
  }

  # RBAC 설정 (기본값을 사용하여 에러 방지)
  set {
    name  = "configs.rbac.policy\\.default"
    value = "role:readonly"
  }

  # 리소스 설정 (타임아웃 방지)
  set {
    name  = "server.resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "server.resources.requests.memory"
    value = "128Mi"
  }

  set {
    name  = "server.resources.limits.cpu"
    value = "200m"
  }

  set {
    name  = "server.resources.limits.memory"
    value = "256Mi"
  }

  # 레플리카 수 조정
  set {
    name  = "server.replicaCount"
    value = "1"
  }

  depends_on = [
    module.eks,
    kubernetes_namespace.argocd,
    time_sleep.wait_for_alb_controller
  ]
}

# EKS 클러스터와 Helm 차트는 Terraform으로 자동 배포됩니다
# GitOps 설정만 수동으로 진행하면 됩니다

# Output ArgoCD information
output "argocd_server_url" {
  description = "ArgoCD Server URL (LoadBalancer)"
  value       = "Check LoadBalancer external IP: kubectl get svc argocd-server -n argocd"
}

output "argocd_admin_password" {
  description = "ArgoCD Admin Password Command"
  value       = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
  sensitive   = true
}

output "cert_manager_status" {
  description = "cert-manager installation status"
  value       = "cert-manager installed with Route53 DNS challenge support"
}

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
