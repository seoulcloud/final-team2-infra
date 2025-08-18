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

# Output important values
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "eks_cluster_endpoint" {
  description = "EKS Cluster Endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_name" {
  description = "EKS Cluster Name"
  value       = module.eks.cluster_name
}

output "ssm_session_manager_url" {
  description = "SSM Session Manager Connection Guide"
  value       = "Use 'aws ssm start-session --target <instance-id> --profile default' to connect"
}

output "backend_api_irsa_role_arn" {
  description = "Backend API IRSA Role ARN"
<<<<<<< HEAD
  value       = module.backend_api_irsa.iam_role_arn
=======
  value       = module.backend_api_irsa.backend_api_iam_role_arn
>>>>>>> 5121c9c09cb4a9aee65111cafa45948bea01d5e1
}

output "kubernetes_secrets_status" {
  description = "Kubernetes Secrets creation status"
  sensitive   = true
  value = {
    dev_namespace    = module.kubernetes_secrets_dev.namespace_name
    prod_namespace   = module.kubernetes_secrets_prod.namespace_name
    dev_secret       = module.kubernetes_secrets_dev.secret_name
    prod_secret      = module.kubernetes_secrets_prod.secret_name
    dev_secret_keys  = module.kubernetes_secrets_dev.secret_data_keys
    prod_secret_keys = module.kubernetes_secrets_prod.secret_data_keys
  }
}

# ALB Module Outputs
output "alb_controller_role_arn" {
  description = "AWS Load Balancer Controller IAM Role ARN"
  value       = module.alb.aws_load_balancer_controller_role_arn
}

output "alb_security_group_id" {
  description = "ALB Security Group ID"
  value       = module.alb.alb_security_group_id
}

output "alb_controller_status" {
  description = "AWS Load Balancer Controller installation status"
  value       = "AWS Load Balancer Controller installed with IRSA support"
}