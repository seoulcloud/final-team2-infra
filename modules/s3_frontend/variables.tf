# 1. bucket_name
# 2. cloudfront_oac_id
# 3. tags, acl, versioning


variable "prefix" {
  type        = string
  description = "환경 구분용 prefix (ex: dev, prod)"
}

variable "oac_id" {
  type        = string
  description = "CloudFront OAC ID"
}

variable "bucket_name" {
  type        = string
  description = "S3 버킷 이름"
}

variable "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution"
  type        = string
}