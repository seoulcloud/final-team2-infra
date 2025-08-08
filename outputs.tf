# Output ArgoCD information
output "argocd_server_url" {
  description = "ArgoCD Server URL (LoadBalancer)"
  value       = "Check LoadBalancer external IP: kubectl get svc argocd-server -n argocd"
}

output "argocd_admin_password" {
  description = "ArgoCD Admin Password Command"
  value       = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
  sensitive   = true
}

output "cert_manager_status" {
  description = "cert-manager installation status"
  value       = "cert-manager installed with Route53 DNS challenge support"
} 