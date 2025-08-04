resource "aws_cloudfront_distribution" "this" {
  provider = aws
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = var.default_root_object  # e.g. "index.html"

  origin {
    domain_name = var.s3_bucket_domain_name      # e.g. "mybucket.s3.ap-northeast-2.amazonaws.com"
    origin_id   = "${var.prefix}-s3-origin"

    # OAC ID (aws_cloudfront_origin_access_control 리소스의 ID)
    origin_access_control_id = var.oac_id
  }

  default_cache_behavior {
    target_origin_id       = "${var.prefix}-s3-origin"
    viewer_protocol_policy = var.viewer_protocol_policy  # e.g. "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

    aliases = [
      "goteego.store",
      "www.goteego.store"
  ]

    viewer_certificate {
    acm_certificate_arn            = var.acm_certificate_arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
    cloudfront_default_certificate = false
    }

  tags = {
    Environment = var.prefix
    Name        = "${var.prefix}-cloudfront"
  }
}