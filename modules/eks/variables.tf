# EKS Module Variables

# Basic Configuration
variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

# VPC Configuration
variable "vpc_id" {
  description = "VPC ID where EKS cluster will be created"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block for security group rules"
  type        = string
}

variable "eks_private_subnets" {
  description = "List of private subnet IDs for EKS cluster"
  type        = list(string)
}

# EKS Configuration
variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.33"
}

# Network Configuration
variable "internet_cidr" {
  description = "CIDR block for internet access"
  type        = string
  default     = "0.0.0.0/0"
}

variable "https_port" {
  description = "HTTPS port for security groups"
  type        = number
  default     = 443
}

variable "high_port" {
  description = "High port range for security groups"
  type        = number
  default     = 65535
}

# Node Groups Configuration
variable "node_groups" {
  description = "EKS node groups configuration"
  type = map(object({
    instance_types = list(string)
    min_size       = number
    max_size       = number
    desired_size   = number
    disk_size      = number
    ami_type       = string
    capacity_type  = string
  }))
  default = {}
}

variable "max_unavailable_percentage" {
  description = "Maximum percentage of nodes unavailable during update"
  type        = number
  default     = 25
}

# Launch Template Configuration
variable "instance_metadata_options" {
  description = "Instance metadata service options"
  type = object({
    http_endpoint               = string
    http_tokens                 = string
    http_put_response_hop_limit = number
    instance_metadata_tags      = string
  })
  default = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }
}

variable "monitoring_enabled" {
  description = "Enable detailed monitoring for instances"
  type        = bool
  default     = true
}

# EKS Add-ons Configuration
variable "addon_resolve_conflicts" {
  description = "How to resolve parameter value conflicts for EKS add-ons"
  type        = string
  default     = "OVERWRITE"
  validation {
    condition     = contains(["OVERWRITE", "PRESERVE"], var.addon_resolve_conflicts)
    error_message = "addon_resolve_conflicts must be either OVERWRITE or PRESERVE."
  }
}

variable "cluster_log_types" {
  description = "List of control plane logging types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "cluster_endpoint_config" {
  description = "EKS cluster endpoint configuration"
  type = object({
    private_access      = bool
    public_access       = bool
    public_access_cidrs = list(string)
  })
  default = {
    private_access      = true
    public_access       = true
    public_access_cidrs = ["0.0.0.0/0"] # TODO: Restrict this in production
  }
}

# SSM Configuration
variable "enable_ssm_access" {
  description = "Enable SSM access for EKS nodes"
  type        = bool
  default     = true
}

variable "enable_node_group_limited_admin" {
  description = "Enable limited admin access for EKS node group (for cert-manager installation)"
  type        = bool
  default     = false
}

# Common Tags
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
} 