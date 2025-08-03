variable "certificate_arn" {
  description = "ARN of the ACM certificate to validate"
  type        = string
}

variable "zone_id" {
  description = "Route 53 Hosted Zone ID for DNS validation"
  type        = string
}

variable "certificate_domain_validation_options" {
  description = "ACM certificate domain validation options"
  type        = any
  default     = []
}