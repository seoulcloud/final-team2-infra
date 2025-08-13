resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version
  namespace  = var.namespace
  timeout    = var.timeout
  force_update = true
  reuse_values = false

  values = [
    templatefile("${path.module}/values.yaml.tpl", {
      alb_security_group_id = var.alb_security_group_id
    })
  ]
} 