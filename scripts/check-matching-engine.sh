#!/usr/bin/env bash
set -euo pipefail

seed=db/migrations/003_seed_identity_products.sql
engine=db/migrations/004_deterministic_matching_engine.sql

test -f "$seed"
test -f "$engine"
test "$(head -n 1 "$seed")" = "BEGIN;"
test "$(tail -n 1 "$seed")" = "COMMIT;"
test "$(head -n 1 "$engine")" = "BEGIN;"
test "$(tail -n 1 "$engine")" = "COMMIT;"

for product in cardiq blinq hihello; do
  grep -q "'$product'" "$seed" || { echo "missing seed product: $product" >&2; exit 1; }
done

for token in \
  "CREATE TABLE scoring_profiles" \
  "CREATE OR REPLACE FUNCTION capability_support_points" \
  "CREATE OR REPLACE FUNCTION requirement_priority_weight" \
  "CREATE OR REPLACE FUNCTION preview_consultation_scores" \
  "CREATE OR REPLACE FUNCTION generate_consultation_recommendations"; do
  grep -q "$token" "$engine" || { echo "missing engine structure: $token" >&2; exit 1; }
done

grep -q "not_yet_verified" "$seed"
grep -q "Support for this requirement has not yet been verified" "$engine"
grep -q "mandatory_gap_count" "$engine"
grep -q "scoring_version" "$engine"

echo "seed and deterministic matching structure checks passed"
