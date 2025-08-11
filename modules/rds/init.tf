variable "namespace" {
  type    = string
  default = "monitoring"
}

# 모니터링 계정 비번 = RDS 메인 비번
resource "kubernetes_secret" "postgres_exporter" {
  metadata {
    name      = "postgres-exporter-secret"
    namespace = var.namespace
  }
  data = {
    EXPORTER_PASSWORD = var.db_password
    RDS_ENDPOINT      = aws_db_instance.this.address
    MASTER_USER       = aws_db_instance.this.username
    MASTER_PASSWORD   = var.db_password
  }
  type = "Opaque"

  # RDS 생성 후 값이 안정적으로 들어가도록
  depends_on = [aws_db_instance.this]
}

# 초기화 SQL ConfigMap
resource "kubernetes_config_map" "rds_init_sql" {
  metadata {
    name      = "rds-db-init-sql"
    namespace = var.namespace
  }
  data = {
    "rds-db-init.sql" = file("${path.module}/rds-db-init.sql")
  }
}

# RDS 초기화 Job
resource "kubernetes_job" "rds_init" {
  metadata {
    name      = "rds-init-postgres-exporter"
    namespace = var.namespace
  }
  spec {
    ttl_seconds_after_finished = 300
    template {
      metadata {}
      spec {
        restart_policy = "Never"
        container {
          name  = "psql"
          image = "postgres:15-alpine"
          command = ["/bin/sh", "-c"]
          args = [<<EOT
            export PGPASSWORD=$(cat /secrets/MASTER_PASSWORD);
            psql "host=$(cat /secrets/RDS_ENDPOINT) port=5432 dbname=postgres user=$(cat /secrets/MASTER_USER) sslmode=require" \
            -v EXPORTER_PASSWORD=$(cat /secrets/EXPORTER_PASSWORD) \
            -f /sql/rds-db-init.sql
            EOT
          ]

          volume_mount {
            name       = "sql"
            mount_path = "/sql"
            read_only  = true
          }
          volume_mount {
            name       = "secret"
            mount_path = "/secrets"
            read_only  = true
          }
        }
        volume {
          name = "sql"
          config_map {
            name = kubernetes_config_map.rds_init_sql.metadata[0].name
          }
        }
        volume {
          name = "secret"
          secret {
            secret_name = kubernetes_secret.postgres_exporter.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [
    aws_db_instance.this
  ]
}