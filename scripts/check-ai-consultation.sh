#!/usr/bin/env bash
set -euo pipefail

schema=db/migrations/006_ai_consultation_contract.sql
doc=docs/SPRINT_1_4_AI_CONSULTATION_CONTRACT.md

test -f "$schema"
test -f "$doc"
test "$(head -n 1 "$schema")" = "BEGIN;"
test "$(tail -n 1 "$schema")" = "COMMIT;"

for table in ai_extraction_runs ai_extracted_fields ai_follow_up_questions consultation_ai_state; do
  grep -Eq "^CREATE TABLE ${table} \(" "$schema" || { echo "missing table: $table" >&2; exit 1; }
done

grep -q "CREATE OR REPLACE FUNCTION consultation_missing_critical_fields" "$schema"
grep -q "CREATE OR REPLACE FUNCTION refresh_consultation_ai_state" "$schema"
grep -q "The model must not" "$doc"
grep -q "deterministic matching" "$doc"
echo "AI consultation contract checks passed"
