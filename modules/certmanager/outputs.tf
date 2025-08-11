output "release_name" {
  description = "Helm release name"
  value       = helm_release.cert_manager.name
}

output "namespace" {
  description = "Namespace where cert-manager is installed"
  value       = helm_release.cert_manager.namespace
} 