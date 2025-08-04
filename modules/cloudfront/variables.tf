variable "prefix" {
  type        = string
  description = "환경 구분 prefix (예: dev, prod)"
}

variable "oac_id" {
  type        = string
  description = "CloudFront Origin Access Control ID"
}

variable "s3_bucket_domain_name" {
  type        = string
  description = "S3 정적 웹 호스팅용 버킷 도메인 이름"
}

variable "default_root_object" {
  type        = string
  default     = "index.html"
}

variable "viewer_protocol_policy" {
  type        = string
  default     = "redirect-to-https"
}

variable "cloudfront_distribution_arn" {
  description = "CloudFront distribution ARN"
  type        = string
  default     = null # 기본값 추가로 필수 입력 해제
}

variable "acm_certificate_arn" {
  type        = string
  description = "ACM certificate ARN in us-east-1"
}
