variable "project_name" { type = string }
variable "environment"  { type = string }
variable "namespace"    { type = string  default = "kube-system" }

# IRSA 입력
variable "cluster_oidc_provider_arn" { type = string }
variable "cluster_oidc_issuer_url"   { type = string }

# 관리할 도메인/Hosted Zone 제한
variable "domain_filters" { type = list(string)  default = [] }     # 예: ["goteego.store"]
variable "hosted_zone_id" { type = string  default = null }         # 예: "Z123ABC..."
variable "hosted_zone_arn"{ type = string  default = null }         # 없으면 id로 계산

# 동작 옵션
variable "sources"      { type = list(string) default = ["ingress"] } # ingress, service 등
variable "policy"       { type = string       default = "upsert-only" }
variable "registry"     { type = string       default = "txt" }
variable "txt_owner_id" { type = string       default = null } # 기본값은 아래에서 생성
variable "chart_version"{ type = string       default = "1.15.0" }

variable "common_tags"  { type = map(string)  default = {} }