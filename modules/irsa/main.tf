# IRSA Module - IAM Role for Service Account

# Data source for current AWS caller identity
data "aws_caller_identity" "current" {}

# Data source for current AWS region
data "aws_region" "current" {}

# IAM Policy for cert-manager (Route53 DNS challenge)
resource "aws_iam_policy" "cert_manager_route53" {
  count = var.service_name == "cert-manager" ? 1 : 0
  
  name        = "${var.cluster_name}-cert-manager-route53"
  description = "Policy for cert-manager to manage Route53 records"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:GetChange",
          "route53:ListHostedZones",
          "route53:ListHostedZonesByName"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:GetHostedZone",
          "route53:ListResourceRecordSets"
        ]
        Resource = var.hosted_zone_arn != null ? var.hosted_zone_arn : "*"
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for ArgoCD (if needed)
resource "aws_iam_policy" "argocd" {
  count = var.service_name == "argocd" ? 1 : 0
  
  name        = "${var.cluster_name}-argocd"
  description = "Policy for ArgoCD service account"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

# IAM Trust Policy for IRSA
data "aws_iam_policy_document" "trust_policy" {
  statement {
    effect = "Allow"
    
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }
    
    actions = ["sts:AssumeRoleWithWebIdentity"]
    
    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_issuer_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.service_account_name}"]
    }
    
    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_issuer_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

# IAM Role for Service Account
resource "aws_iam_role" "service_account" {
  name               = "${var.cluster_name}-${var.service_name}-irsa"
  assume_role_policy = data.aws_iam_policy_document.trust_policy.json

  tags = merge(var.tags, {
    Name        = "${var.cluster_name}-${var.service_name}-irsa"
    ServiceName = var.service_name
    Type        = "IRSA-Role"
  })
}

# Attach policy to role based on service type
resource "aws_iam_role_policy_attachment" "cert_manager" {
  count = var.service_name == "cert-manager" ? 1 : 0
  
  role       = aws_iam_role.service_account.name
  policy_arn = aws_iam_policy.cert_manager_route53[0].arn
}

resource "aws_iam_role_policy_attachment" "argocd" {
  count = var.service_name == "argocd" ? 1 : 0
  
  role       = aws_iam_role.service_account.name
  policy_arn = aws_iam_policy.argocd[0].arn
}

# Kubernetes Service Account
resource "kubernetes_service_account" "service_account" {
  metadata {
    name      = var.service_account_name
    namespace = var.namespace
    
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.service_account.arn
    }
    
    labels = {
      "app.kubernetes.io/name"       = var.service_name
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
  automount_service_account_token = true
}


# Redis 전용 IRSA 역할 생성===============================
resource "aws_iam_role" "redis_irsa" {
  name = "redis-irsa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.cluster_oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(var.cluster_oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:${var.namespace}:redis-sa"
        }
      }
    }]
  })
}

# Redis용 SSM 파라미터 접근 정책 (예: redis_auth_token)
resource "aws_iam_role_policy" "redis_ssm_policy" {
  name = "ssm-read-redis-auth-token"
  role = aws_iam_role.redis_irsa.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath"]
        Resource = "arn:aws:ssm:ap-northeast-2:${data.aws_caller_identity.current.account_id}:parameter/${var.project_name}/${var.environment}/redis_auth_token"  # 필요시 수정
      }
    ]
  })
}

# Redis 전용 Kubernetes Service Account 생성
resource "kubernetes_service_account" "redis_sa" {
  metadata {
    name      = "redis-sa"
    namespace = var.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.redis_irsa.arn
    }
  }
}

