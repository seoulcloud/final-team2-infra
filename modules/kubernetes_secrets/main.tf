# Kubernetes Secrets Module
# Namespace와 Secret을 자동으로 생성하는 모듈

# Kubernetes Namespace 생성
resource "kubernetes_namespace" "namespace" {
  metadata {
    name = var.namespace_name
    labels = merge(var.namespace_labels, {
      "name"                         = var.namespace_name
      "app.kubernetes.io/managed-by" = "terraform"
    })
  }

  depends_on = [var.eks_dependency]
}

# Kubernetes Secret 생성
resource "kubernetes_secret" "db_secrets" {
  metadata {
    name      = var.secret_name
    namespace = kubernetes_namespace.namespace.metadata[0].name
    labels = merge(var.secret_labels, {
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/name"       = var.secret_name
    })
  }

  data = {
    DB_PASSWORD    = var.db_password_postgresql
    MONGO_PASSWORD = var.db_password_mongodb
    REDIS_PASSWORD = var.redis_auth_token
  }

  type = "Opaque"

  depends_on = [
    kubernetes_namespace.namespace,
    var.ssm_parameters_dependency
  ]
} 