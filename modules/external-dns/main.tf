data "aws_region" "current" {}

# Hosted Zone ARN 계산
locals {
  hosted_zone_arn = coalesce(var.hosted_zone_arn, var.hosted_zone_id != null ? "arn:aws:route53:::hostedzone/${var.hosted_zone_id}" : null)
  sa_name         = "external-dns"
  txt_owner_id    = coalesce(var.txt_owner_id, "${var.project_name}-${var.environment}")
}

# IRSA 신뢰정책
data "aws_iam_policy_document" "trust" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [var.cluster_oidc_provider_arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${replace(var.cluster_oidc_issuer_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${local.sa_name}"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(var.cluster_oidc_issuer_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "externaldns" {
  name               = "${var.project_name}-${var.environment}-externaldns-irsa"
  assume_role_policy = data.aws_iam_policy_document.trust.json
  tags               = var.common_tags
}

# Route53 권한 (Zone 제한 권장)
resource "aws_iam_policy" "externaldns_route53" {
  name        = "${var.project_name}-${var.environment}-externaldns-route53"
  description = "Allow ExternalDNS to manage Route53 records"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["route53:ChangeResourceRecordSets"],
        Resource = local.hosted_zone_arn != null ? local.hosted_zone_arn : "*"
      },
      {
        Effect = "Allow",
        Action = [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets",
          "route53:GetHostedZone",
          "route53:GetChange"
        ],
        Resource = "*"
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.externaldns.name
  policy_arn = aws_iam_policy.externaldns_route53.arn
}

# K8s ServiceAccount (IRSA 연결)
resource "kubernetes_service_account" "externaldns" {
  metadata {
    name      = local.sa_name
    namespace = var.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.externaldns.arn
    }
    labels = {
      "app.kubernetes.io/name"       = "external-dns"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
  automount_service_account_token = true
}

# Helm 설치
resource "helm_release" "external_dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = var.chart_version
  namespace  = var.namespace

  # ServiceAccount: IRSA로 만든 SA 재사용
  set {
    name  = "serviceAccount.create"
    value = "false"
  }
  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.externaldns.metadata[0].name
  }

  # Provider / 동작
  set {
    name  = "provider"
    value = "aws"
  }
  set {
    name  = "policy"
    value = var.policy # 예: "upsert-only"
  }
  set {
    name  = "registry"
    value = var.registry # 예: "txt"
  }
  set {
    name  = "txtOwnerId"
    value = "${var.project_name}-${var.environment}"
  }

  # AWS 옵션
  set {
    name  = "aws.region"
    value = data.aws_region.current.name
  }
  set {
    name  = "aws.zoneType"
    value = "public"
  }

  # 동작 튜닝 (모두 문자열로!)
  set {
    name  = "interval"
    value = "2m"
  }
  set {
    name  = "triggerLoopOnEvent"
    value = tostring(true) # bool 넣지 말고 문자열/ tostring 사용
  }
  set {
    name  = "logLevel"
    value = "info"
  }

  # sources[] 배열
  dynamic "set" {
    for_each = var.sources # 예: ["ingress"]
    content {
      name  = "sources[${set.key}]"
      value = set.value
    }
  }

  # domainFilters[] 배열
  dynamic "set" {
    for_each = var.domain_filters # 예: ["goteego.store"]
    content {
      name  = "domainFilters[${set.key}]"
      value = set.value
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.attach,
    kubernetes_service_account.externaldns
  ]
}