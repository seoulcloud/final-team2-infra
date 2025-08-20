-- Exporter 유저 생성 & 권한 (비밀번호/유저명은 placeholder)
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${exporter_user}') THEN
    EXECUTE format('CREATE ROLE %I LOGIN PASSWORD %L', '${exporter_user}', '${exporter_password}');
  END IF;
END $$;

GRANT pg_monitor TO "${exporter_user}";
GRANT CONNECT ON DATABASE "${db_name}" TO "${exporter_user}";

-- pgvector 설치 (idempotent)
CREATE EXTENSION IF NOT EXISTS vector;