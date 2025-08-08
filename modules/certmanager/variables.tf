variable "namespace" {
  type        = string
  description = "Namespace to install cert-manager"
}

variable "chart_version" {
  type        = string
  description = "cert-manager chart version"
  default     = "v1.13.3"
}

variable "service_account_name" {
  type        = string
  description = "ServiceAccount name provided by IRSA module"
} 