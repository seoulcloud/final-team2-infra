# RDS 인스턴스 식별자
output "db_instance_id" {
  description = "The RDS instance ID"
  value       = aws_db_instance.this.id
}

# RDS 엔드포인트 (애플리케이션이 연결할 주소)
output "db_instance_endpoint" {
  description = "The RDS instance endpoint"
  value       = aws_db_instance.this.endpoint
  sensitive = true
}

# RDS 포트 (기본 PostgreSQL: 5432)
output "db_instance_port" {
  description = "The port of the RDS instance"
  value       = aws_db_instance.this.port
}

# RDS 상태 (available, creating, deleting)
output "db_instance_status" {
  description = "The current status of the RDS instance"
  value       = aws_db_instance.this.status
}

# RDS ARN
output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = aws_db_instance.this.arn
}