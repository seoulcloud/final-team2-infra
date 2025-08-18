# Kubernetes Secrets Module Outputs

output "namespace_name" {
  description = "Name of the created namespace"
  value       = kubernetes_namespace.namespace.metadata[0].name
}

output "secret_name" {
  description = "Name of the created secret"
  value       = kubernetes_secret.db_secrets.metadata[0].name
}

output "secret_data_keys" {
  description = "Keys in the secret data"
  value       = keys(kubernetes_secret.db_secrets.data)
  sensitive   = true
} 