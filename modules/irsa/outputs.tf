# IRSA Module Outputs

output "service_account_name" {
  description = "Name of the created service account"
  value       = kubernetes_service_account.service_account.metadata[0].name
}

output "service_account_namespace" {
  description = "Namespace of the created service account"
  value       = kubernetes_service_account.service_account.metadata[0].namespace
}

output "iam_role_arn" {
  description = "ARN of the created IAM role"
  value       = aws_iam_role.service_account.arn
}

output "iam_role_name" {
  description = "Name of the created IAM role"
  value       = aws_iam_role.service_account.name
}

# Redis IRSA outputs (conditional)
output "redis_iam_role_arn" {
  description = "ARN of the Redis IAM role"
  value       = var.create_db_role ? aws_iam_role.redis_irsa[0].arn : null
}

output "redis_iam_role_name" {
  description = "Name of the Redis IAM role"
  value       = var.create_db_role ? aws_iam_role.redis_irsa[0].name : null
}

output "redis_service_account_name" {
  description = "Name of the Redis Kubernetes service account"
  value       = var.create_db_role ? kubernetes_service_account.redis_sa[0].metadata[0].name : null
}

# Backend API IRSA outputs (conditional)
output "backend_api_iam_role_arn" {
  description = "ARN of the Backend API IAM role"
  value       = var.create_backend_api_role ? aws_iam_role.backend_api_irsa[0].arn : null
}

output "backend_api_iam_role_name" {
  description = "Name of the Backend API IAM role"
  value       = var.create_backend_api_role ? aws_iam_role.backend_api_irsa[0].name : null
} 