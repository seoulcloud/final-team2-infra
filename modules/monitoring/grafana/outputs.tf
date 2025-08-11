output "grafana_release_name" {
  description = "Grafana Helm release name"
  value       = helm_release.grafana.name
}

# ALB DNS 출력 (hostname 우선, 없으면 ip)
output "grafana_alb_dns" {
  description = "Grafana ALB DNS for external access"
  value       = try(
    data.kubernetes_ingress_v1.grafana.status[0].load_balancer[0].ingress[0].hostname,
    null
  )
}