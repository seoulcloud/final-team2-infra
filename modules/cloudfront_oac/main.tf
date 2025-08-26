resource "aws_cloudfront_origin_access_control" "this" {
  name                              = var.name
  description                       = var.description
  signing_protocol                  = "sigv4"
  signing_behavior                  = "always"
  origin_access_control_origin_type = "s3"
}

output "oac_id" {
  value = aws_cloudfront_origin_access_control.this.id
}