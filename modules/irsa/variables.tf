# IRSA Module Variables

variable "name" {
  description = "Name of the service (cert-manager, argocd, aws-load-balancer-controller)"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for the service account"
  type        = string
}

variable "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL of the EKS cluster"
  type        = string
}

variable "cluster_oidc_provider_arn" {
  description = "ARN of the OIDC provider for the EKS cluster"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "policy_arns" {
  description = "List of IAM policy ARNs to attach to the role"
  type        = list(string)
  default     = []
}

variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default     = {}
}

variable "create_db_role" {
  description = "DB 접근용 IRSA 역할을 생성할지 여부"
  type        = bool
  default     = false
}

variable "create_backend_api_role" {
  description = "Backend API SSM 접근용 IRSA 역할을 생성할지 여부"
  type        = bool
  default     = false
}

variable "hosted_zone_arn" {
  description = "ARN of the Route53 hosted zone (optional, for cert-manager)"
  type        = string
  default     = null
}
