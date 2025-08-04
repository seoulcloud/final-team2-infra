
variable "region" {
  type    = string
  default = "ap-northeast-2"
}

locals {
  s3_website_hosted_zone_ids = {
    "us-east-1"      = "Z3AQBSTGFYJSTF"
    "ap-northeast-2" = "Z3OJ8A4GXLOFKF"
  }
}

output "hosted_zone_id" {
  value = local.s3_website_hosted_zone_ids[var.region]
}

output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = var.bucket_name
}