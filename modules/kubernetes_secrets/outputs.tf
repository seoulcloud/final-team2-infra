# Kubernetes Secrets Module Outputs

output "namespace_name" {
  description = "Name of the created namespace"
  value       = kubernetes_namespace.namespace.metadata[0].name
}

output "namespace_uid" {
  description = "UID of the created namespace"
  value       = kubernetes_namespace.namespace.metadata[0].uid
}

output "secret_name" {
  description = "Name of the created secret"
  value       = kubernetes_secret.db_secrets.metadata[0].name
}

output "secret_namespace" {
  description = "Namespace of the created secret"
  value       = kubernetes_secret.db_secrets.metadata[0].namespace
}

output "secret_uid" {
  description = "UID of the created secret"
  value       = kubernetes_secret.db_secrets.metadata[0].uid
}

output "secret_data_keys" {
  description = "Keys available in the secret data"
  value       = keys(kubernetes_secret.db_secrets.data)
} 