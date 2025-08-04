output "zone_id" {
  description = "Route53 Hosted Zone ID"
  value       = aws_route53_zone.main.zone_id
}


output "route53_zone_id" {
  description = "Route53 Hosted Zone ID without prefix"
  value       = replace(aws_route53_zone.main.zone_id, "/hostedzone/", "")
}

output "route53_zone_name" {
  value = aws_route53_zone.main.name
}


