variable "domain_name" {
  description = "The root domain name (e.g. goteego.store)"
  type        = string
}

variable "subject_alternative_names" {
  description = "Additional domain names for the certificate"
  type        = list(string)
  default     = []
}