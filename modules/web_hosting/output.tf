output "bucket_name" {
  value = aws_s3_bucket.static_site.bucket
}

# output "website_endpoint" {
#   value = aws_s3_bucket.static_site.website_endpoint
# }

variable "region" {
  type    = string
  default = "ap-northeast-2"
}

locals {
  s3_website_hosted_zone_ids = {
    "us-east-1"      = "Z3AQBSTGFYJSTF"
    "ap-northeast-2" = "Z3OJ8A4GXLOFKF"
    # 기타 리전 추가 가능
  }
}

output "hosted_zone_id" {
  value = local.s3_website_hosted_zone_ids[var.region]
}
