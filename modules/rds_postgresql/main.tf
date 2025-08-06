resource "aws_db_instance" "this" {
  # RDS 인스턴스 식별자 (AWS 콘솔에 표시되는 이름)
  identifier = "${var.project_name}-${var.environment}-postgres"

  # 데이터베이스 엔진 및 버전
  engine         = "postgres"
  engine_version = var.engine_version

  # 인스턴스 사양
  instance_class = var.instance_class

  # 스토리지 설정
  allocated_storage       = var.allocated_storage        # 초기 스토리지 (GB)
  max_allocated_storage   = var.max_allocated_storage    # 자동 확장 최대치 (GB)
  storage_type            = var.storage_type             # 스토리지 타입 (gp2/gp3)
  storage_encrypted       = true                         # 스토리지 암호화 활성화

  # DB 이름 및 인증 정보
  db_name   = var.db_name
  username  = var.db_username
  password  = var.db_password  # 민감 값 → Terraform Cloud에서 관리

  # 파라미터 그룹 및 Multi-AZ 설정
  parameter_group_name = var.parameter_group_name
  multi_az             = var.multi_az                   # 고가용성 여부 (true면 Multi-AZ)

  # 백업 및 스냅샷
  backup_retention_period = var.backup_retention_period # 백업 보존 기간 (일)
  skip_final_snapshot     = true                        # 삭제 시 최종 스냅샷 건너뛰기

  # 모니터링 (CloudWatch Enhanced Monitoring)
  monitoring_interval = 60                              # 60초 간격으로 메트릭 수집

  # 네트워크 설정
  vpc_security_group_ids = var.vpc_security_group_ids   # 연결할 SG 리스트
  db_subnet_group_name   = var.db_subnet_group_name     # DB Subnet Group (Private Subnet)

  # 태그
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-postgresql-rds"
    Type = "rds-postgresql"
  })
}