# Monitoring namespace
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"

    labels = {
      "name"                         = "monitoring"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  depends_on = [module.eks]
}

module "prometheus" {
  source            = "./modules/monitoring/prometheus"
  namespace         = "monitoring"
  chart_version     = "56.6.2"

  # Postgres Exporter 추가 설정
  postgres_exporter_chart_version = "6.1.0"
  rds_endpoint                    = module.rds.db_instance_endpoint
  rds_db_name                     = var.project_name
  rds_db_exporter_user            = var.rds_db_exporter_user
  rds_db_exporter_password        = var.db_password_postgresql

  # ServiceMonitor 라벨 (kube-prometheus-stack values.yaml에서 release 값 확인)
  service_monitor_labels = {
    release = "kube-prometheus-stack"
  }

  depends_on_module = [ 
    module.eks,
    kubernetes_namespace.monitoring,
    module.alb
  ]
}

module "grafana" {
  source                 = "./modules/monitoring/grafana"
  namespace              = "monitoring"
  chart_version          = "7.3.9"
  alb_security_group_id    = module.alb.alb_security_group_id
  node_group_security_group_id   = module.eks.node_group_security_group_id
  depends_on_module      = [
    module.prometheus
  ]
  grafana_admin_password = var.grafana_admin_password
}

# RDS CPU 모니터링
module "monitoring_rds_cpu" {
  source          = "./modules/monitoring"
  sns_topic_name  = "${var.project_name}-rds-alerts"
  email_addresses = var.alert_emails

  alarm_name          = "${var.project_name}-RDS-CPU-HIGH"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  action_description  = "RDS PostgreSQL CPU 사용률이 임계치를 초과했습니다. 쿼리 성능을 점검하거나 리소스를 확장하세요."

  dimensions = {
    DBInstanceIdentifier = module.rds.db_instance_id # RDS 인스턴스 ID
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