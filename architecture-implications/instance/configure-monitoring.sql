GRANT SET ON PARAMETER auto_explain.log_min_duration to "user";
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
GRANT pg_monitor TO "user";