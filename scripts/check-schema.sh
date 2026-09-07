#!/usr/bin/env bash
set -euo pipefail

schema=db/migrations/001_consultation_analytics.sql
test -f "$schema"
test "$(head -n 1 "$schema")" = "BEGIN;"
test "$(tail -n 1 "$schema")" = "COMMIT;"

required_tables=(users visitor_sessions companies consultations consultation_requirements \
  consultation_integrations consultation_deployment_preferences \
  consultation_compliance_requirements consultation_countries consultation_languages \
  consultation_messages consultation_recommendations recommendation_gaps analytics_events \
  search_logs sensitive_record_access_logs)

for table in "${required_tables[@]}"; do
  grep -Eq "^CREATE TABLE ${table} \(" "$schema" || {
    echo "missing table: $table" >&2
    exit 1
  }
done

grep -q "CREATE FUNCTION link_visitor_session_to_user" "$schema"
grep -q "CREATE VIEW analytics_overview_daily" "$schema"
grep -q "CREATE VIEW consultation_funnel_daily" "$schema"
echo "schema structure checks passed"
