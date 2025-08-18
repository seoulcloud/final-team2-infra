# Data source for current AWS region
data "aws_region" "current" {}

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
    value = data.aws_region.current
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
    target_group_arn       = aws_lb_target_group.backend.arn # 실제 타겟그룹 alb arn 변경 필요. 예시
  }
}

resource "local_file" "helm_values_yaml" {
  content  = data.template_file.autoscale_values.rendered
  filename = "${path.module}/helm/values-generated.yaml"
}
