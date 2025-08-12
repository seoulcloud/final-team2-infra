resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.12.1"
  namespace  = "kube-system"

  set_list {
    name  = "args"
    value = ["--kubelet-insecure-tls"]
  }
}


# 외부 DNS(예: GoDaddy, Cloudflare)에서 CNAME 설정

resource "aws_route53_record" "hpa_test_alias" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "hpa-test.${var.domain_name}" 
  type    = "A"

  alias {
    name                   = module.k8s_hpa_test.hpa_test_external_svc_status_hostname
    zone_id                = "Z215JYRZR1TBD5"  # 서울 리전 ALB Hosted Zone ID 예시
    evaluate_target_health = true
  }
}