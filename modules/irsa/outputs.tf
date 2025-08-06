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
  value       = kubernetes_service_account.service_account.metadata[0].name
}

output "service_account_namespace" {
  description = "Namespace of the Kubernetes service account"
  value       = kubernetes_service_account.service_account.metadata[0].namespace
} 