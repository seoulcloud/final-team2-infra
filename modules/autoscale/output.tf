output "hpa_hostname" {
  description = "HPA ALB or service hostname for Route53"
  value       = aws_lb.autoscale_lb.dns_name # 예시: ALB DNS 이름
}