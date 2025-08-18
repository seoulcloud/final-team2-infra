locals {
  # SQL에 비밀값(계정/비밀번호) 직접 넣지 말고 Flyway placeholder만 둠
  v1_init_sql = coalesce(
    var.sql_init,
    <<-SQL
    -- Exporter 유저 생성 & 권한 (비밀번호/유저명은 placeholder)
    DO $$
    BEGIN
      IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$${exporter_user}') THEN
        EXECUTE format('CREATE ROLE %I LOGIN PASSWORD %L', '$${exporter_user}', '$${exporter_password}');
      END IF;
    END $$;

    GRANT pg_monitor TO "$${exporter_user}";
    GRANT CONNECT ON DATABASE "$${db_name}" TO "$${exporter_user}";
    SQL
  )

  v2_pgvector_sql = coalesce(
    var.sql_pgvector,
    <<-SQL
    -- pgvector 설치 (idempotent)
    CREATE EXTENSION IF NOT EXISTS vector;
    SQL
  )

  # Job 이름은 환경에 따라 유니크하게
  job_name = var.job_name != "" ? var.job_name : "flyway-init-${var.app_suffix}"
}

# Flyway SQL을 담는 ConfigMap (비밀값 없음)
resource "kubernetes_config_map" "flyway_sql" {
  metadata {
    name      = "${local.job_name}-sql"
    namespace = var.namespace
    labels    = { app = local.job_name }
  }

  data = {
    "V1__init.sql"     = local.v1_init_sql
    "V2__pgvector.sql" = local.v2_pgvector_sql
  }
}

# DB 접속 및 placeholder 값은 Secret로 (민감정보)
resource "kubernetes_secret" "flyway_db" {
  metadata {
    name      = "${local.job_name}-secret"
    namespace = var.namespace
    labels    = { app = local.job_name }
  }

  type = "Opaque"
  data = {
    DB_HOST           = base64encode(var.db_host)
    DB_PORT           = base64encode(var.db_port)
    DB_NAME           = base64encode(var.db_name)
    DB_USER           = base64encode(var.db_user)
    DB_PASSWORD       = base64encode(var.db_password)

    # placeholder 값도 전부 Secret로 주입
    EXPORTER_USER     = base64encode(var.exporter_user)
    EXPORTER_PASSWORD = base64encode(var.exporter_password)
  }
}

# Flyway Kubernetes Job (한번 실행)
resource "kubernetes_manifest" "flyway_job" {
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
                { name = "DB_HOST",           valueFrom = { secretKeyRef = { name = kubernetes_secret.flyway_db.metadata[0].name, key = "DB_HOST" } } },
                { name = "DB_PORT",           valueFrom = { secretKeyRef = { name = kubernetes_secret.flyway_db.metadata[0].name, key = "DB_PORT" } } },
                { name = "DB_NAME",           valueFrom = { secretKeyRef = { name = kubernetes_secret.flyway_db.metadata[0].name, key = "DB_NAME" } } },
                { name = "DB_USER",           valueFrom = { secretKeyRef = { name = kubernetes_secret.flyway_db.metadata[0].name, key = "DB_USER" } } },
                { name = "DB_PASSWORD",       valueFrom = { secretKeyRef = { name = kubernetes_secret.flyway_db.metadata[0].name, key = "DB_PASSWORD" } } },
                { name = "EXPORTER_USER",     valueFrom = { secretKeyRef = { name = kubernetes_secret.flyway_db.metadata[0].name, key = "EXPORTER_USER" } } },
                { name = "EXPORTER_PASSWORD", valueFrom = { secretKeyRef = { name = kubernetes_secret.flyway_db.metadata[0].name, key = "EXPORTER_PASSWORD" } } },
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
                  -url=jdbc:postgresql://$${DB_HOST}:$${DB_PORT}/$${DB_NAME}?sslmode=require \
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
              configMap = { name = kubernetes_config_map.flyway_sql.metadata[0].name }
            }
          ]
        }
      }
    }
  }
  
  # 🔧 서버가 주입하는 동적 라벨로 인한 드리프트 무시
  lifecycle {
    ignore_changes = [
      "object.spec.template.metadata.labels",
      "object.metadata.labels", # 혹시 상위에도 주입되면 함께 무시
    ]
  }
}