-- =============================================================================
-- PostgreSQL monitoring user for Prometheus postgres_exporter
-- =============================================================================

-- 1) 계정 생성 (이미 있으면 스킵)
DO $$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'postgres_exporter') THEN
      CREATE USER postgres_exporter WITH PASSWORD :'EXPORTER_PASSWORD';
   END IF;
END
$$;

-- 2) 글로벌 읽기 권한 부여
--    - pg_monitor: 핵심 모니터링 뷰 접근
--    - pg_read_all_stats/pg_read_all_settings: 통계/설정 읽기
GRANT CONNECT ON DATABASE postgres TO postgres_exporter;
GRANT USAGE ON SCHEMA public TO postgres_exporter;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO postgres_exporter;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO postgres_exporter;

-- pg_stat_* 뷰 접근 권한
GRANT pg_monitor TO postgres_exporter;