output "certificate_arn" {
  description = "ACM certificate ARN"
  value       = aws_acm_certificate.cert.arn
}

output "domain_validation_options" {
  description = "ACM certificate domain validation options"
  value       = aws_acm_certificate.cert.domain_validation_options
}