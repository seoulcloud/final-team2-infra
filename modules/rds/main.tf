provider "postgresql" {
  host            = aws_db_instance.this.address
  port            = 5432
  database        = var.db_name
  username        = var.db_username       # RDS 마스터
  password        = var.db_password
  sslmode         = "require"             # RDS는 SSL 권장
  connect_timeout = 15

  # 리소스 생성 순서 보장을 위해 명시적 depends_on
  # (provider 블록에는 depends_on을 직접 못 걸어서 아래 리소스에 걸어둠)
}

resource "aws_db_instance" "this" {
  # RDS 인스턴스 식별자 (AWS 콘솔에 표시되는 이름)
  identifier = "${var.project_name}-${var.environment}-postgres"

  # 데이터베이스 엔진 및 버전
  engine         = "postgres"
  engine_version = var.engine_version

  # 인스턴스 사양
  instance_class = var.instance_class

  # 스토리지 설정
  allocated_storage     = var.allocated_storage     # 초기 스토리지 (GB)
  max_allocated_storage = var.max_allocated_storage # 자동 확장 최대치 (GB)
  storage_type          = var.storage_type          # 스토리지 타입 (gp2/gp3)
  storage_encrypted     = true                      # 스토리지 암호화 활성화

  # DB 이름 및 인증 정보
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password # 민감 값 → Terraform Cloud에서 관리

  # 파라미터 그룹 및 Multi-AZ 설정
  parameter_group_name = var.parameter_group_name
  multi_az             = var.multi_az # 고가용성 여부 (true면 Multi-AZ)

  # 백업 및 스냅샷
  backup_retention_period = var.backup_retention_period # 백업 보존 기간 (일)
  skip_final_snapshot     = true                        # 삭제 시 최종 스냅샷 건너뛰기

  # 모니터링 (CloudWatch Enhanced Monitoring)
  monitoring_interval = 60 # 60초 간격으로 메트릭 수집
  monitoring_role_arn = aws_iam_role.rds_enhanced_monitoring.arn

  # 최신 RDS CA 체인 고정(지역 최신값으로 조정 가능)
  ca_cert_identifier = "rds-ca-rsa4096-g1"

  # 네트워크 설정
  vpc_security_group_ids = var.vpc_security_group_ids # 연결할 SG 리스트
  db_subnet_group_name   = var.db_subnet_group_name   # DB Subnet Group (Private Subnet)

  # 태그
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-postgresql-rds"
    Type = "rds-postgresql"
  })
}

resource "aws_iam_role" "rds_enhanced_monitoring" {
  name = "${var.project_name}-${var.environment}-rds-enhanced-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# resource "postgresql_role" "exporter" {
#   depends_on = [time_sleep.wait_rds_ready]

#   name     = var.db_exporter_username
#   login    = true
#   password = var.db_password

#   # 필요시 패스워드 만료/정책 옵션들 추가 가능
#   # valid_until = "infinity"
# }

# resource "postgresql_grant_role" "exporter_pg_monitor" {
#   depends_on = [postgresql_role.exporter]

#   # 부여받는 쪽(= 우리 사용자/롤)
#   role             = postgresql_role.exporter.name

#   # 부여할 롤
#   grant_role       = "pg_monitor"

#   # ADMIN OPTION 불필요하면 false
#   with_admin_option = false
# }

# resource "time_sleep" "wait_rds_ready" {
#   depends_on      = [aws_db_instance.this]
#   create_duration = "45s"
# }

# pgvector 설치 (CREATE EXTENSION vector)
# resource "postgresql_extension" "pgvector" {
#   name     = "vector"            # pgvector의 실제 extension 이름은 'vector'
#   schema   = "public"
#   database = var.db_name

#   # RDS가 준비된 뒤에 실행
#   depends_on = [
#     time_sleep.wait_rds_ready,
#     aws_db_instance.this
#   ]
# }

# resource "postgresql_grant" "exporter_connect" {
#   depends_on  = [postgresql_role.exporter]
#   database    = var.db_name
#   role        = postgresql_role.exporter.name
#   object_type = "database"
#   privileges  = ["CONNECT"]
# }

resource "aws_security_group_rule" "allow_prometheus_to_rds" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = var.postgresql_security_group_id          # RDS SG
  source_security_group_id = var.node_group_security_group_id  # EKS 노드 SG (Prometheus가 붙는 곳)
}