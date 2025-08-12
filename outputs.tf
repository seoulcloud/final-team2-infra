output "argocd_ingress_hostname" {
  description = "ArgoCD Ingress ALB hostname (from Kubernetes)"
  value       = try(data.kubernetes_ingress_v1.argocd.status[0].load_balancer[0].ingress[0].hostname, "")
}

output "argocd_admin_password_cmd" {
  description = "How to get ArgoCD admin password"
  value       = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}