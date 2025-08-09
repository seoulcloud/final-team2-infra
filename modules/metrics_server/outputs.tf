# Metrics Server Module - Outputs

output "release_name" {
  value       = helm_release.metrics_server.name
  description = "Helm release name for metrics-server"
}

output "namespace" {
  value       = helm_release.metrics_server.namespace
  description = "Namespace where metrics-server is installed"
} 