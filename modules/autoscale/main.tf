# Data source for current AWS region
data "aws_region" "current" {}

# Metric Server Helm Chart 설치

resource "helm_release" "metric_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = "5.12.2" # 안정적 최신 버전 선택
  create_namespace = false

  set {
    name  = "args"
    value = "--kubelet-insecure-tls"  # 필요 시 kubelet TLS 검증 비활성화
  }

  set {
    name  = "resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "resources.requests.memory"
    value = "128Mi"
  }

  set {
    name  = "resources.limits.cpu"
    value = "200m"
  }

  set {
    name  = "resources.limits.memory"
    value = "256Mi"
  }

}

# 설치 확인용 output
output "metric_server_status" {
  value = helm_release.metric_server.status
}

resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  namespace  = "kube-system"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = "9.50.1" # EKS 버전에 맞는 최신 Chart 선택

  set {
    name  = "autoDiscovery.clusterName"
    value = var.cluster_name
  }

  set {
    name  = "awsRegion"
    value = data.aws_region.current.name
  }

  # IRSA로 만든 ServiceAccount 사용
  set {
    name  = "rbac.serviceAccount.create"
    value = "false"
  }
  set {
    name  = "rbac.serviceAccount.name"
    value = "cluster-autoscaler"
  }

    depends_on = [
    helm_release.metric_server
  ]
}

# 특정 서비스  Target Group 조회

data "aws_lb_target_group" "my_service_tg" {
  tags = {
    "kubernetes.io/service-name" = "hpa-test-external-svc"
    "kubernetes.io/namespace"    = "autoscale-dev"
  }
}


data "template_file" "autoscale_values" {
  template = file("${path.module}/helm/values.yaml.tpl")

  vars = {
    namespace             = "autoscale-dev"
    deployment_name       = "hpa-test"
    app_label             = "hpa-test"
    container_name        = "hpa-test-container"
    container_image       = "nginx:latest"
    min_replicas          = 2
    max_replicas          = 5
    target_cpu_utilization = 50
    internal_service_name  = "hpa-test-internal-svc"
    external_service_name  = "hpa-test-external-svc"
    # target_group_arn = lookup(data.aws_lb_target_group.my_service_tg.*.arn, 0, "")
    target_group_arn = try(data.aws_lb_target_group.my_service_tg.arn, "")
  }
}

resource "local_file" "helm_values_yaml" {
  content  = data.template_file.autoscale_values.rendered
  filename = "${path.module}/helm/values-generated.yaml"
}
