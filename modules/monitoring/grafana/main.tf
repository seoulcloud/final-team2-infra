# Grafana Helm 설치
resource "helm_release" "grafana" {
  name       = "grafana"
  namespace  = var.namespace
  chart      = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  version    = var.chart_version

  # values.yaml 설정 적용
  # values.yaml 기본값 + 동적 override
  values = [
    file("${path.module}/values.yaml"),
    yamlencode({
      ingress = {
        annotations = {
          "alb.ingress.kubernetes.io/security-groups" = var.alb_security_group_id
        }
      }
      # datasources = {
      #   "datasources.yaml" = {
      #     apiVersion = 1
      #     datasources = [
      #       {
      #         name      = "Prometheus"
      #         type      = "prometheus"
      #         url       = "http://kube-prometheus-stack-prometheus:9090"
      #         access    = "proxy"
      #         isDefault = true
      #       }
      #     ]
      #   }
      # }
    })
  ]

  # admin 비밀번호는 민감하므로 별도 관리
  set_sensitive {
    name  = "adminPassword"
    value = var.grafana_admin_password
  }

  depends_on = [var.depends_on_module]
}

# ALB -> NodeSG 3000/TCP 허용 (IP 타깃 타입일 때 실제 트래픽은 노드 ENI를 지나감)
resource "aws_security_group_rule" "alb_to_nodes_grafana" {
  type                     = "ingress"
  from_port                = var.grafana_target_port
  to_port                  = var.grafana_target_port
  protocol                 = "tcp"
  source_security_group_id = var.alb_security_group_id
  security_group_id        = var.node_group_security_group_id
  description              = "Allow ALB to reach Grafana"
  
  depends_on = [ var.depends_on_module ]
}

# 1) 잠깐 대기해서 ALB 붙을 시간 주기
resource "time_sleep" "wait_for_alb" {
  depends_on      = [helm_release.grafana]
  create_duration = "90s"
}