

variable "prefix" {
  type        = string
  description = "환경 구분용 prefix (ex: dev, prod)"
}

variable "cloudfront_distribution_arn" {
  description = "The ARN of the CloudFront distribution"
  type        = string
}

variable "bucket_name" {
  type        = string
  description = "S3 버킷 이름"
}

