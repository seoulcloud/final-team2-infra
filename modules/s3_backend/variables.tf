# 1. bucket_name
# 2. enable_versioning (옵션)
# 3. tags, lifecycle_rule, server_side_encryption_configuration

variable "prefix" {
  type        = string
  description = "환경 구분용 prefix (ex: dev, prod)"
}

variable "bucket_name" {
  type        = string
  description = "S3 버킷 이름"
}

variable "lifecycle_days" {
  type        = number
  description = "얼마나 지난 뒤에 아카이브 혹은 삭제할지"
  default     = 30
}