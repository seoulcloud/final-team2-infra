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

variable "ingress_hosts" {
  type        = list(string)
  description = "List of hostnames for ArgoCD ingress"
  default     = []
}

variable "ingress_hostname" {
  type        = string
  description = "Primary hostname for ArgoCD ingress"
  default     = ""
}

variable "certificate_arn" {
  type        = string
  description = "ACM certificate ARN in ap-northeast-2 for ALB"
  default     = ""
}

variable "ssl_redirect" {
  type        = string
  description = "Port to redirect HTTP to HTTPS"
  default     = "443"
}

variable "insecure" {
  type        = bool
  description = "Run ArgoCD server in insecure mode (HTTP). Should be false for TLS)"
  default     = false
} 