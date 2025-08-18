# Kubernetes Secrets Module Variables

variable "namespace_name" {
  description = "Name of the Kubernetes namespace to create"
  type        = string
}

variable "namespace_labels" {
  description = "Additional labels for the namespace"
  type        = map(string)
  default     = {}
}

variable "secret_name" {
  description = "Name of the Kubernetes secret to create"
  type        = string
  default     = "db-secrets"
}

variable "secret_labels" {
  description = "Additional labels for the secret"
  type        = map(string)
  default     = {}
}

variable "db_password_postgresql" {
  description = "PostgreSQL database password"
  type        = string
  sensitive   = true
}

variable "db_password_mongodb" {
  description = "MongoDB database password"
  type        = string
  sensitive   = true
}

variable "redis_auth_token" {
  description = "Redis authentication token"
  type        = string
  sensitive   = true
}

variable "eks_dependency" {
  description = "EKS cluster dependency to ensure proper creation order"
  type        = any
  default     = null
}

variable "ssm_parameters_dependency" {
  description = "SSM parameters dependency to ensure proper creation order"
  type        = any
  default     = null
} 