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