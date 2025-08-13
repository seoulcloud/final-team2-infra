resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version
  namespace  = var.namespace
  timeout    = var.timeout
  force_update = true
  reuse_values = false

  # Explicitly set critical ingress fields to avoid schema/merge mismatches
  set {
    name  = "server.ingress.hosts[0]"
    value = "argocd.goteego.store"
  }
  set {
    name  = "server.ingress.paths[0]"
    value = "/"
  }
  set {
    name  = "server.ingress.ingressClassName"
    value = "alb"
  }

  values = [
    templatefile("${path.module}/values.yaml.tpl", {
      alb_security_group_id = var.alb_security_group_id
    })
  ]
} 