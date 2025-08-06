# IRSA Module Variables

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "service_name" {
  description = "Name of the service (cert-manager, argocd, etc.)"
  type        = string
  validation {
    condition     = contains(["cert-manager", "argocd"], var.service_name)
    error_message = "Service name must be one of: cert-manager, argocd."
  }
}

variable "service_account_name" {
  description = "Name of the Kubernetes service account"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for the service account"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider for the EKS cluster"
  type        = string
}

variable "oidc_issuer_url" {
  description = "OIDC issuer URL of the EKS cluster"
  type        = string
}

variable "hosted_zone_arn" {
  description = "ARN of the Route53 hosted zone (optional, for cert-manager)"
  type        = string
  default     = null
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}
