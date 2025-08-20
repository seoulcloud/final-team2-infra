resource "helm_release" "argocd" {
  name         = "argocd"
  repository   = "https://argoproj.github.io/argo-helm"
  chart        = "argo-cd"
  version      = var.chart_version
  namespace    = var.namespace
  timeout      = var.timeout
  force_update = true
  reuse_values = false

  values = [
    yamlencode({
      server = {
        service = {
          type = "ClusterIP"
        }
        extraArgs    = ["--insecure"]
        replicaCount = 1
        ingress = {
          enabled          = true
          ingressClassName = "alb"
          annotations = {
            "kubernetes.io/ingress.class"                = "alb"
            "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
            "alb.ingress.kubernetes.io/target-type"      = "ip"
            "alb.ingress.kubernetes.io/listen-ports"     = jsonencode([{ HTTP = 80 }, { HTTPS = 443 }])
            # "alb.ingress.kubernetes.io/ssl-redirect"     = "443"
            "alb.ingress.kubernetes.io/certificate-arn"  = var.certificate_arn
            "alb.ingress.kubernetes.io/backend-protocol" = "HTTP"
            "alb.ingress.kubernetes.io/healthcheck-path" = "/healthz"
            "alb.ingress.kubernetes.io/success-codes"    = "200-399"
            "alb.ingress.kubernetes.io/security-groups"  = var.alb_security_group_id
            "external-dns.alpha.kubernetes.io/hostname"  = var.ingress_hostname
          }
          hostname = length(var.ingress_hostname) > 0 ? var.ingress_hostname : null
          hosts    = length(var.ingress_hosts) > 0 ? var.ingress_hosts : null
          paths    = ["/"]
        }
      }
      configs = {
        params = { "server.insecure" = true }
        rbac   = { "policy.default" = "role:readonly" }
        cm     = { url = "https://${var.ingress_hostname}" }
        repositories = [
          { url = "https://github.com/CLD-3rd/final-team2-manifest.git" }
        ]
      }
      applicationSet = { enabled = true }
    })
  ]
}
