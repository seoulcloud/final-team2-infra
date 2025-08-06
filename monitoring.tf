# PostgreSQL CPU 모니터링 (EC2 기반)
module "monitoring_postgresql_cpu" {
  source             = "./modules/monitoring"
  sns_topic_name     = "${var.project_name}-db-alerts"
  email_addresses    = var.alert_emails

  alarm_name          = "${var.project_name}-RDPostgreSQL-CPU-HIGH"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  action_description  = "PostgreSQL 서버 CPU 사용률이 임계치를 초과했습니다. 쿼리 성능을 점검하거나 리소스를 확장하세요."

  dimensions = {
    InstanceId = module.postgresql_server.InstanceId # RDS 인스턴스 ID
  }

  tags = var.common_tags
}

# # EKS CPU 모니터링
# module "monitoring_eks_cpu" {
#   source             = "./modules/monitoring"
#   sns_topic_name     = "${var.project_name}-eks-alerts"
#   email_addresses    = var.alert_emails

#   alarm_name          = "${var.project_name}-EKS-CPU-HIGH"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = 1
#   metric_name         = "CPUUtilization"
#   namespace           = "AWS/EC2"
#   period              = 300
#   statistic           = "Average"
#   threshold           = 80
#   action_description  = "EKS 노드 CPU 사용량이 임계치를 초과했습니다. 워크로드를 확인하거나 노드 그룹을 확장하세요."

#   dimensions = {
#     AutoScalingGroupName = "eks-node-asg" # 실제 값 필요
#   }

#   tags = var.common_tags
# }