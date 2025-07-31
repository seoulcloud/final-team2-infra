variable "name" {
  description = "ServiceAccount 이름"
  type        = string
}

variable "namespace" {
  description = "ServiceAccount 네임스페이스"
  type        = string
  default     = "default"
}

variable "policy_arns" {
  description = "연결할 IAM 정책 ARN 리스트"
  type        = list(string)
  default     = []
}

variable "cluster_oidc_issuer_url" {
  description = "EKS OIDC Provider URL"
  type        = string
}

variable "cluster_oidc_provider_arn" {
  description = "EKS OIDC Provider ARN"
  type        = string
} 