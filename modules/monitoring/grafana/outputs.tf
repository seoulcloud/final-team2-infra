output "grafana_release_name" {
  description = "Grafana Helm release name"
  value       = helm_release.grafana.name
}

# output "grafana_alb_dns" {
#   description = "Grafana ALB DNS for external access"
#   value       = try(data.kubernetes_ingress.grafana.status.load_balancer.ingress[0].hostname, null)
# }