output "hpa_test_external_svc_status_hostname" {
  description = "External LoadBalancer hostname of hpa-test-external-svc"
  value       = kubernetes_service.hpa_test_external_svc.status[0].load_balancer[0].ingress[0].hostname
}