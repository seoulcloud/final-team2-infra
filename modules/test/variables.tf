variable "vpc_id" {
  description = "VPC ID for ALB and Target Group"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB"
  type        = list(string)
}

variable "domain_name" {
  description = "Domain name for ACM certificate and Route53"
  type        = string
  default     = "goteego.store"
}