# DocumentDB 클러스터
resource "aws_docdb_cluster" "this" {
  # 기본 설정
  cluster_identifier = "${var.project_name}-${var.environment}-docdb" # 클러스터 식별자
  engine             = "docdb"                                       # DocumentDB 엔진
  engine_version     = "5.0" 

  # 인증 정보
  master_username = var.db_username
  master_password = var.db_password

  # 백업 및 보안
  backup_retention_period         = var.backup_retention_period      # 백업 보존 기간
  skip_final_snapshot             = true                             # 삭제 시 스냅샷 생략
  storage_encrypted               = true                             # 스토리지 암호화

  # 네트워크
  db_subnet_group_name           = var.db_subnet_group_name          # 서브넷 그룹
  vpc_security_group_ids         = var.vpc_security_group_ids        # 보안 그룹
  db_cluster_parameter_group_name   = aws_docdb_cluster_parameter_group.this.name

  # 로깅
  enabled_cloudwatch_logs_exports = ["audit", "profiler"]            # CloudWatch 로그 익스포트

  # 태그
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-documentdb-cluster"
    Type = "documentdb"
  })
}


# DocumentDB 클러스터 인스턴스
resource "aws_docdb_cluster_instance" "this" {
  # 기본 설정
  count              = var.instance_count
  identifier         = "${var.project_name}-${var.environment}-docdb-${count.index}"

  # 클러스터 연결
  cluster_identifier = aws_docdb_cluster.this.id
  instance_class     = var.instance_class
  apply_immediately  = true

  # 태그
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-documentdb-instance-${count.index}"
    Type = "documentdb"
  })
}

# Parameter Group
resource "aws_docdb_cluster_parameter_group" "this" {
  family = "docdb5.0"                                      # DocumentDB 버전 패밀리
  name   = "${var.project_name}-${var.environment}-docdb-params"

  parameter {
    name  = "tls"                                          # TLS 설정
    value = "enabled"
  }
}