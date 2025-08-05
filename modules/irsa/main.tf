data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    principals {
      type        = "Federated"
      identifiers = [var.cluster_oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(var.cluster_oidc_issuer_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.name}"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.name}-irsa-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags = {
    Name = "${var.name}-irsa-role"
  }
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = toset(var.policy_arns)
  role     = aws_iam_role.this.name
  policy_arn = each.value
}

resource "kubernetes_service_account" "this" {
  metadata {
    name      = var.name
    namespace = var.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.this.arn
    }
  }
} 
# DB =============================================

# DB SSM 접근 전용 Role
resource "aws_iam_role" "db_irsa" {
  name = "db-irsa-role"

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
          "${replace(var.cluster_oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:${var.namespace}:db-reader-sa"
        }
      }
    }]
  })
}

# DB 전용 정책 붙이기
resource "aws_iam_role_policy" "ssm_read_policy" {
  name = "ssm-read-db-password"
  role = aws_iam_role.db_irsa.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath"]
        Resource = "arn:aws:ssm:ap-northeast-2:${data.aws_caller_identity.current.account_id}:parameter/${var.project_name}/${var.environment}/db_password_mongodb"  # 수정필요함
      }
    ]
  })
}

data "aws_caller_identity" "current" {}

# DB 전용 SA 생성 (DB 종류 별로 필요한 권한이 다르기 때문에.. 별로도 생성 필요)
resource "kubernetes_service_account" "db_reader_sa" {
  metadata {
    name      = "db-reader-sa"
    namespace = var.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.db_irsa.arn
    }
  }
}

resource "aws_iam_role" "postgres_irsa" {
  name = "eks-irsa-postgres"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:your-namespace:postgres-sa"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "postgres_ssm_policy" {
  role       = aws_iam_role.postgres_irsa.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess" # 또는 커스텀
}

resource "kubernetes_service_account" "postgres_sa" {
  metadata {
    name      = "postgres-sa"
    namespace = "your-namespace"

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.postgres_irsa.arn
    }
  }
}