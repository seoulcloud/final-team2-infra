resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version
  namespace  = var.namespace
  timeout    = var.timeout

  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }

  set {
    name  = "server.extraArgs[0]"
    value = "--insecure"
  }

  set {
    name  = "configs.params.server\\.insecure"
    value = "true"
  }

  set {
    name  = "configs.rbac.policy\\.default"
    value = "role:readonly"
  }

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

  set {
    name  = "server.replicaCount"
    value = "1"
  }

  set {
    name  = "server.ingress.enabled"
    value = "true"
  }

  set {
    name  = "server.ingress.ingressClassName"
    value = "alb"
  }

  set {
    name  = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/scheme"
    value = "internet-facing"
  }

  set {
    name  = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/target-type"
    value = "ip"
  }

  set {
    name  = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/listen-ports"
    value = "[{\"HTTP\":80}]"
  }

  set {
    name  = "server.ingress.hosts[0]"
    value = "argocd.goteego.store"
  }

  set {
    name  = "server.ingress.paths[0].path"
    value = "/"
  }

  set {
    name  = "server.ingress.paths[0].pathType"
    value = "Prefix"
  }

  # Git Repository 자동 등록
  set {
    name  = "configs.repositories.team2-manifest"
    value = "url: https://github.com/CLD-3rd/final-team2-manifest.git"
  }

  # Application Set Controller 활성화
  set {
    name  = "applicationSet.enabled"
    value = "true"
  }

  # Repository 접근 설정
  set {
    name  = "configs.params.repo\\.server"
    value = "insecure: true"
  }

  # ALB 권장 어노테이션 (헬스체크/백엔드 프로토콜)
  set {
    name  = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/backend-protocol"
    value = "HTTP"
  }

  set {
    name  = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/healthcheck-path"
    value = "/healthz"
  }

  set {
    name  = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/success-codes"
    value = "200-399"
  }
} 