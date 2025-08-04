variable "ami_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "security_group_ids" {
  type = list(string)
}

# variable "key_name" {
#   type = string
# }

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "common_tags" {
  type = map(string)
}


variable "db_type" {
  type = string
}


variable "db_password" {
  description = "Password for the database (PostgreSQL or MongoDB)"
  type        = string
  sensitive   = true
}