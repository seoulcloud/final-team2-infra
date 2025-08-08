output "grafana_release_name" {
  description = "Grafana Helm release name"
  value       = helm_release.grafana.name
}

# output "grafana_loadbalancer_dns" {
#   description = "Grafana LoadBalancer DNS"
#   value = try(
#     data.kubernetes_service.grafana.status.load_balancer.ingress[0].hostname,
#     data.kubernetes_service.grafana.status.load_balancer.ingress[0].ip,
#     null
#   )
# }