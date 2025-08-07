output "grafana_release_name" {
  description = "Grafana Helm release name"
  value       = helm_release.grafana.name
}

output "loadbalancer_dns" {
  description = "Grafana LoadBalancer DNS 이름"
  value = try(
    helm_release.grafana.status[0].load_balancer[0].ingress[0].hostname,
    helm_release.grafana.status[0].load_balancer[0].ingress[0].ip,
    null
  )
}