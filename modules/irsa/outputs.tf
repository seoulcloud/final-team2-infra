# IRSA Module Outputs

output "iam_role_arn" {
  description = "ARN of the IAM role for the service account"
  value       = aws_iam_role.service_account.arn
}

output "iam_role_name" {
  description = "Name of the IAM role for the service account"
  value       = aws_iam_role.service_account.name
}

output "service_account_name" {
  description = "Name of the Kubernetes service account"
  value       = var.name
}

output "service_account_namespace" {
  description = "Namespace of the Kubernetes service account"
  value       = var.namespace
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