
resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.project_name}-${var.environment}-elasticache-subnet-group"
  subnet_ids = var.subnet_ids

  tags = var.common_tags
}


resource "aws_elasticache_replication_group" "this" {
  replication_group_id          = "${var.project_name}-${var.environment}-redis"
  replicas_per_node_group = var.num_cache_nodes > 1 ? var.num_cache_nodes - 1 : 0  # 마스터 노드 제외한 복제 노드 개수
  description                   = "ElastiCache Redis replication group for ${var.project_name} ${var.environment}"  # 추가
  engine                        = "redis"
  engine_version                = "7.0"
  node_type                     = var.node_type
  parameter_group_name          = "goteego.redis7"
  port                          = 6379
  subnet_group_name             = aws_elasticache_subnet_group.this.name # redis가 배포될 영역
  security_group_ids            = var.security_group_ids

  # Redis AUTH
  auth_token                    = var.redis_auth_token

  # 권장 보안 옵션
  at_rest_encryption_enabled    = true
  transit_encryption_enabled    = true

  tags = var.common_tags
}