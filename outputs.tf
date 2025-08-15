output "argocd_ingress_hostname" {
  description = "How to get ArgoCD Ingress ALB hostname"
  value       = "kubectl -n argocd get ingress argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}

output "argocd_admin_password_cmd" {
  description = "How to get ArgoCD admin password"
  value       = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}

# ACM Certificate ARNs for TLS configuration
output "acm_certificate_arn_us_east_1" {
  description = "ACM certificate ARN for CloudFront (us-east-1)"
  value       = module.acm_cert.certificate_arn
}

output "acm_certificate_arn_ap_northeast_2" {
  description = "ACM certificate ARN for ALB/Ingress (ap-northeast-2)"
  value       = module.acm_cert_kor.certificate_arn
}