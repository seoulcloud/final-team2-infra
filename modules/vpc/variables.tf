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

variable "elasticache_private_subnets" {
  description = "Elasticache용 프라이빗 서브넷 목록"
  type        = list(string)
}

# Network Configuration
variable "public_subnet_newbits" {
  description = "Newbits for public subnet CIDR calculation"
  type        = number
  default     = 8
}

variable "internet_cidr" {
  description = "CIDR block for internet access"
  type        = string
  default     = "0.0.0.0/0"
}

variable "https_port" {
  description = "HTTPS port for VPC endpoints"
  type        = number
  default     = 443
}

# SSM Configuration
variable "enable_ssm_endpoints" {
  description = "Enable SSM VPC endpoints for private subnet access"
  type        = bool
  default     = true
}

variable "ssm_actions" {
  description = "List of SSM actions allowed for VPC endpoint policy"
  type        = list(string)
  default = [
    "ssm:StartSession",
    "ssm:SendCommand",
    "ssm:GetCommandInvocation",
    "ssm:DescribeInstanceInformation",
    "ssm:ListCommandInvocations",
    "ssm:ListCommands",
    "ssm:DescribeInstanceAssociationsStatus",
    "ssm:GetConnectionStatus"
  ]
}

# Common Tags
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
} 
variable "eks_node_security_group" {
  description = "EKS node group security group ID to allow inbound in Elasticache SG"
  type        = string
}
variable "eks_node_security_group" {
  type        = string
  description = "The security group ID for EKS node group"
}