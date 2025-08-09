# HPA Module Variables

variable "name" {
  description = "Name of the HorizontalPodAutoscaler"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace where the HPA will be created"
  type        = string
}

variable "target_kind" {
  description = "Target workload kind (e.g., Deployment, StatefulSet, ReplicaSet)"
  type        = string
  validation {
    condition     = contains(["Deployment", "StatefulSet", "ReplicaSet"], var.target_kind)
    error_message = "target_kind must be one of: Deployment, StatefulSet, ReplicaSet."
  }
}

variable "target_name" {
  description = "Name of the target workload to scale"
  type        = string
}

variable "min_replicas" {
  description = "Minimum number of replicas"
  type        = number
  default     = 1
}

variable "max_replicas" {
  description = "Maximum number of replicas"
  type        = number
}

variable "average_cpu_utilization" {
  description = "Target average CPU utilization percentage for scaling (Utilization)"
  type        = number
  default     = 60
}

variable "average_memory_utilization" {
  description = "Optional: Target average memory utilization percentage for scaling (Utilization)"
  type        = number
  default     = null
}

variable "labels" {
  description = "Optional labels to attach to the HPA resource"
  type        = map(string)
  default     = {}
} 