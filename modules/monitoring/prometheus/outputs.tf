output "prometheus_service_url" {
  description = "Internal DNS URL of Prometheus service"
  value       = "http://kube-prometheus-stack-prometheus.${var.namespace}.svc.cluster.local"
}