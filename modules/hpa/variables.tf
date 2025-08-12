variable "deployment_name" {
  type = string
}

variable "namespace" {
  type    = string
  default = "default"
}

variable "min_replicas" {
  type    = number
  default = 1
}

variable "max_replicas" {
  type    = number
  default = 5
}

variable "target_cpu_utilization" {
  type    = number
  default = 50
}



variable "container_image" {
  description = "Deployment 컨테이너 이미지"
  type        = string
  default     = "nginx:latest"
}