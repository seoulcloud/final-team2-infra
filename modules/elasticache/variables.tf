variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_ids" {
  type = list(string)
}

variable "node_type" {
  description = "Elasticache node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "num_cache_nodes" {
  description = "Number of cache nodes"
  type        = number
  default     = 1
}

variable "tags" {
  type = map(string)
}

# variable "redis_auth_token" {
#   description = "Redis AUTH token (min 16 characters)"
#   type        = string
#   sensitive   = true
# }

# variable "security_group_ids" {
#   description = "List of security group IDs to assign to Elasticache"
#   type        = list(string)
# }