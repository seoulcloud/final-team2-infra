data "aws_region" "current" {}

# Hosted Zone ARN 계산
locals {
  # hosted_zone_arn = coalesce(var.hosted_zone_arn, var.hosted_zone_id != null ? "arn:aws:route53:::hostedzone/${var.hosted_zone_id}" : null)
  hosted_zone_arn = (
    var.hosted_zone_arn != null
    ? var.hosted_zone_arn
    : (var.hosted_zone_id != null ? "arn:aws:route53:::hostedzone/${var.hosted_zone_id}" : null)
  )
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
  tags               = var.tags
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

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.externaldns.name
  policy_arn = aws_iam_policy.externaldns_route53.arn
}

# K8s ServiceAccount (IRSA 연결)
# resource "kubernetes_service_account" "externaldns" {
#   metadata {
#     name      = local.sa_name
#     namespace = var.namespace
#     annotations = {
#       "eks.amazonaws.com/role-arn" = aws_iam_role.externaldns.arn
#     }
#     labels = {
#       "app.kubernetes.io/name"       = "external-dns"
#       "app.kubernetes.io/managed-by" = "terraform"
#     }
#   }
#   automount_service_account_token = true
# }

# Helm 설치
resource "helm_release" "external_dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = var.chart_version
  namespace  = var.namespace
  create_namespace = false

  # 설치 안정성 강화
  wait       = true
  timeout    = 900
  atomic     = false
  cleanup_on_fail = true
  force_update    = true

  # ServiceAccount: IRSA로 만든 SA 재사용
  # set {
  #   name  = "serviceAccount.create"
  #   value = "false"
  # }
  # set {
  #   name  = "serviceAccount.name"
  #   value = kubernetes_service_account.externaldns.metadata[0].name
  # }

  values = [
    yamlencode({
      provider          = "aws"
      policy            = var.policy
      registry          = var.registry
      txtOwnerId        = local.txt_owner_id
      aws               = { region = data.aws_region.current.name, zoneType = "public" }
      interval          = "2m"
      triggerLoopOnEvent= true
      logLevel          = "debug"

      # 차트가 SA 생성 + IRSA 주석을 차트에 전달
      serviceAccount = {
        create      = true
        name        = "external-dns"
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.externaldns.arn
        }
      }
      rbac = { create = true }  # (기본값이지만 명시)

      # annotationFilter는 values의 정식 키로 안전하게 전달
      annotationFilter  = "external-dns.goteego/enabled in (true, 'true')"
      extraArgs         = [
        "--aws-evaluate-target-health=false"
      ]

      sources           = var.sources          # 예: ["ingress"]
      domainFilters     = var.domain_filters   # 예: ["grafana.goteego.store", "argocd.goteego.store"]
    })
  ]

  depends_on = [
    aws_iam_role_policy_attachment.attach,
    aws_security_group_rule.allow_eks_nodes_to_sts_vpce_443,
    # kubernetes_service_account.externaldns,
  ]

  lifecycle {
    ignore_changes = [ values ]   # provider가 내부적으로 채우는 값으로 인한 플리커 방지
  }
}

# EKS 노드 SG → STS VPCE SG : 443 허용
resource "aws_security_group_rule" "allow_eks_nodes_to_sts_vpce_443" {
  type                     = "ingress"
  description              = "Allow EKS nodes to call STS via VPC Endpoint"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = var.vpce_sts_sg_id
  source_security_group_id = var.node_group_security_group_id
}