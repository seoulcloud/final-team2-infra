variable "domain_name" {
  description = "The root domain name (e.g. goteego.store)"
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate ARN"
  type        = string
}

variable "zone_id" {
  description = "Route53 Hosted Zone ID"
  type        = string
}

variable "certificate_domain_validation_options" {
  description = "ACM certificate domain validation options"
  type        = any
  default     = []
}