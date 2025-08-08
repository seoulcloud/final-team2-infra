

variable "prefix" {
  type        = string
  description = "환경 구분용 prefix (ex: dev, prod)"
}


variable "bucket_name" {
  type        = string
  description = "S3 버킷 이름"
}