# VPC Module Variables

# Basic Configuration
variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

# Subnet Configuration
variable "eks_private_subnets" {
  description = "Private subnets for EKS (2 AZs)"
  type        = list(string)
}

variable "postgresql_private_subnets" {
  description = "Private subnets for PostgreSQL (2 AZs)"
  type        = list(string)
}

variable "mongodb_private_subnets" {
  description = "Private subnets for MongoDB (2 AZs)"
  type        = list(string)
}

# SSM Configuration
variable "enable_ssm_endpoints" {
  description = "Enable SSM VPC endpoints for private subnet access"
  type        = bool
  default     = true
}

# Common Tags
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
} 