#!/usr/bin/env bash
set -euo pipefail

schema=db/migrations/002_technology_knowledge_graph.sql
test -f "$schema"
test "$(head -n 1 "$schema")" = "BEGIN;"
test "$(tail -n 1 "$schema")" = "COMMIT;"

required_tables=(vendors product_categories product_modules product_pricing \
  product_deployment_models product_integrations product_countries product_languages \
  product_industries product_compliance_frameworks product_capabilities evidence_sources \
  product_capability_evidence verification_history)

for table in "${required_tables[@]}"; do
  grep -Eq "^CREATE TABLE ${table} \(" "$schema" || {
    echo "missing table: $table" >&2
    exit 1
  }
done

grep -q "CREATE TYPE capability_support_status AS ENUM" "$schema"
grep -q "'not_yet_verified'" "$schema"
grep -q "CREATE VIEW product_capability_evidence_summary" "$schema"
grep -q "CREATE VIEW product_knowledge_coverage" "$schema"
grep -q "product_capabilities_product_capability_edition_unique" "$schema"
grep -q "product_capability_evidence" "$schema"

echo "technology knowledge schema structure checks passed"
