variable "namespace" {
  type        = string
  description = "Namespace to install ArgoCD"
}

variable "chart_version" {
  type        = string
  description = "ArgoCD chart version"
  default     = "8.2.5"
}

variable "timeout" {
  type        = number
  description = "Helm install timeout in seconds"
  default     = 900
}

variable "alb_security_group_id" {
  type        = string
  description = "ALB Security Group ID to be attached to ArgoCD Ingress"
} 