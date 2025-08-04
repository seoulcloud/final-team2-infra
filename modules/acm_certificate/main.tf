terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

#ACM 인증서 요청
provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}

resource "aws_acm_certificate" "cert" {
  provider          = aws
  domain_name       = "goteego.store"
  validation_method = "DNS"

  subject_alternative_names = ["www.goteego.store","goteego.store"]

  lifecycle {
    create_before_destroy = true
  }
}

output "debug_acm_certificate_arn" {
  value = aws_acm_certificate.cert.arn
}