output "prometheus_service_url" {
  description = "Internal DNS URL of Prometheus service"
  value       = "http://kube-prometheus-stack-prometheus.${var.namespace}.svc.cluster.local"
}

output "helm_release_id" {
  description = "value"
  value = helm_release.prometheus.id
}