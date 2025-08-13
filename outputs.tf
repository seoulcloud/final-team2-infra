output "argocd_ingress_hostname" {
  description = "How to get ArgoCD Ingress ALB hostname"
  value       = "kubectl -n argocd get ingress argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}

output "argocd_admin_password_cmd" {
  description = "How to get ArgoCD admin password"
  value       = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}