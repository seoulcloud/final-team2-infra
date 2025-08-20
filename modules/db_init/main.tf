locals {
  # SQL에 비밀값(계정/비밀번호) 직접 넣지 말고 Flyway placeholder만 둠
    db_init_sql = file("${path.module}/db_init.sql")

  # Job 이름은 환경에 따라 유니크하게
  job_name = var.job_name != "" ? var.job_name : "flyway-init-${var.app_suffix}"
}

# Flyway SQL을 담는 ConfigMap (비밀값 없음)
resource "kubernetes_config_map" "flyway_sql" {
  count = var.enabled ? 1 : 0
  metadata {
    name      = "${local.job_name}-sql"
    namespace = var.namespace
    labels    = { app = local.job_name }
  }

  data = {
    "V1__init.sql"     = local.db_init_sql
  }
}

# DB 접속 및 placeholder 값은 Secret로 (민감정보)
resource "kubernetes_secret" "flyway_db" {
  count = var.enabled ? 1 : 0
  metadata {
    name      = "${local.job_name}-secret"
    namespace = var.namespace
    labels    = { app = local.job_name }
  }

  type = "Opaque"
  data = {
    DB_HOST           = var.db_host
    DB_PORT           = var.db_port
    DB_NAME           = var.db_name
    DB_USER           = var.db_user
    DB_PASSWORD       = var.db_password
    EXPORTER_USER     = var.exporter_user
    EXPORTER_PASSWORD = var.exporter_password
  }
}

# Flyway Kubernetes Job (한번 실행)
resource "kubernetes_manifest" "flyway_job" {
  count = var.enabled ? 1 : 0
  manifest = {
    apiVersion = "batch/v1"
    kind       = "Job"
    metadata = {
      name      = local.job_name
      namespace = var.namespace
      labels    = { app = local.job_name }
    }
    spec = {
      backoffLimit             = var.backoff_limit
      ttlSecondsAfterFinished  = var.ttl_seconds_after_finished
      template = {
        metadata = {}
        spec = {
          restartPolicy = "Never"
          containers = [
            {
              name            = "flyway"
              image           = var.flyway_image
              imagePullPolicy = "IfNotPresent"

              # 논루트 실행 권장
              securityContext = {
                runAsNonRoot = true
                runAsUser    = 1000
              }

              # Secret에서 환경변수 주입 (DB 접속 & placeholders)
              env = [
                { name = "DB_HOST",           valueFrom = { secretKeyRef = { name = kubernetes_secret.flyway_db[count.index].metadata[0].name, key = "DB_HOST" } } },
                { name = "DB_PORT",           valueFrom = { secretKeyRef = { name = kubernetes_secret.flyway_db[count.index].metadata[0].name, key = "DB_PORT" } } },
                { name = "DB_NAME",           valueFrom = { secretKeyRef = { name = kubernetes_secret.flyway_db[count.index].metadata[0].name, key = "DB_NAME" } } },
                { name = "DB_USER",           valueFrom = { secretKeyRef = { name = kubernetes_secret.flyway_db[count.index].metadata[0].name, key = "DB_USER" } } },
                { name = "DB_PASSWORD",       valueFrom = { secretKeyRef = { name = kubernetes_secret.flyway_db[count.index].metadata[0].name, key = "DB_PASSWORD" } } },
                { name = "EXPORTER_USER",     valueFrom = { secretKeyRef = { name = kubernetes_secret.flyway_db[count.index].metadata[0].name, key = "EXPORTER_USER" } } },
                { name = "EXPORTER_PASSWORD", valueFrom = { secretKeyRef = { name = kubernetes_secret.flyway_db[count.index].metadata[0].name, key = "EXPORTER_PASSWORD" } } },
                { name = "CONNECT_RETRIES",   value      = tostring(var.connect_retries) }
              ]

              volumeMounts = [
                { name = "sql", mountPath = "/flyway/sql" }
              ]

              # Flyway placeholders로 런타임 치환
              command = ["sh", "-c"]
              args = [<<-EOT
                set -e
                flyway \
                  -url=jdbc:postgresql://$${DB_HOST}:$${DB_PORT}/$${DB_NAME} \
                  -user=$${DB_USER} -password=$${DB_PASSWORD} \
                  -locations=filesystem:/flyway/sql \
                  -placeholders.exporter_user=$${EXPORTER_USER} \
                  -placeholders.exporter_password=$${EXPORTER_PASSWORD} \
                  -placeholders.db_name=$${DB_NAME} \
                  -baselineOnMigrate=true \
                  -connectRetries=$${CONNECT_RETRIES} \
                  migrate
              EOT
              ]
            }
          ]
          volumes = [
            {
              name      = "sql"
              configMap = { name = kubernetes_config_map.flyway_sql[count.index].metadata[0].name }            }
          ]
        }
      }
    }
  }

  # 🔧 서버가 주입하는 동적 라벨로 인한 드리프트 무시
  lifecycle {
    ignore_changes = [
        object.spec.template.metadata.labels,
        object.metadata.labels, # 혹시 상위에도 주입되면 함께 무시
    ]
  }
}

# resource "null_resource" "wait_for_flyway_job" {
#   count = var.enabled ? 1 : 0

#   provisioner "local-exec" {
#     command = <<EOT
#       #!/bin/bash
#       set -e

#       echo "[INFO] Waiting for Flyway job to complete..."

#       for i in {1..30}; do
#         status=$(kubectl -n ${var.namespace} get job ${local.job_name} -o jsonpath='{.status.succeeded}' || echo "0")
#         if [ "$status" == "1" ]; then
#           echo "[INFO] Flyway job completed successfully."
#           exit 0
#         fi
#         echo "[INFO] Waiting for job... ($i/30)"
#         sleep 10
#       done

#       echo "[ERROR] Timeout waiting for Flyway job to succeed"
#       exit 1
#     EOT
#     interpreter = ["/bin/bash", "-c"]
#   }

#   depends_on = [kubernetes_manifest.flyway_job]
# }