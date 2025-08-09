# Metrics Server Module Variables

variable "release_name" {
  description = "Helm release name for metrics-server"
  type        = string
  default     = "metrics-server"
}

variable "namespace" {
  description = "Namespace to install metrics-server"
  type        = string
  default     = "kube-system"
}

variable "chart_version" {
  description = "Helm chart version for metrics-server"
  type        = string
  default     = "3.12.1"
}

variable "insecure_kubelet_tls" {
  description = "Pass --kubelet-insecure-tls to metrics-server"
  type        = bool
  default     = true
}

variable "host_network" {
  description = "Run metrics-server with hostNetwork"
  type        = bool
  default     = false
}

variable "timeout" {
  description = "Helm install/upgrade timeout in seconds"
  type        = number
  default     = 600
} 