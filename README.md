# TechSelect data architecture

This repository contains the PostgreSQL foundation for TechSelect's Phase 1
consultation, first-party analytics, evidence-backed technology knowledge, and
deterministic recommendation engine.

## Apply the schema

The migrations target PostgreSQL 15 or newer. Apply them in this order:

```bash
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f db/migrations/001_consultation_analytics.sql
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f db/migrations/002_technology_knowledge_graph.sql
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f db/migrations/003_fix_product_wide_edition_scope.sql
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f db/migrations/003_seed_identity_products.sql
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f db/migrations/004_deterministic_matching_engine.sql
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f db/migrations/005_seed_identity_deployment_and_explicit_gaps.sql
```

`003_seed_identity_products.sql` intentionally runs after the edition-scope fix.
Future migrations should continue at `006` to avoid another shared numeric prefix.

Run the lightweight repository checks with:

```bash
./scripts/check-schema.sh
./scripts/check-knowledge-schema.sh
./scripts/check-matching-engine.sh
```

## Consultation and analytics

The consultation model permits anonymous consultations through a visitor
session. `link_visitor_session_to_user` atomically claims that session and its
consultations, analytics events, and searches after account creation. Raw
messages and company-level data remain operational records; dashboards should
use the aggregated views from the first migration.

## Technology knowledge graph

Products can belong to multiple categories and modules, expose edition-specific
pricing, deployment models, integrations, countries, languages, industries,
compliance frameworks, and capabilities. Capability support is never reduced
to a simple yes/no value: unknown and not-yet-verified states remain explicit.

Deployment, integration, and compliance facts may be product-wide or scoped to
an edition. The edition-scope migration replaces primary keys that would
otherwise force `edition_id` to be non-null with NULL-safe unique indexes.

Evidence is first-class. Capability facts can link to multiple evidence sources,
carry confidence and verification timestamps, and retain verification history.
The `product_capability_evidence_summary` and `product_knowledge_coverage` views
provide freshness and coverage signals for the recommendation engine and admin
review workflows.

## Sprint 1.3 seed dataset

The first curated dataset is intentionally narrow and evidence-led. It covers
Corporate Identity / Digital Business Cards with CardIQ, Blinq and HiHello.
Only current facts supported by official public vendor material are stored as
verified. Missing facts are inserted as `not_yet_verified`; explicit vendor
statements that a capability is unavailable may be stored as `not_supported`.

This seed is for validating the consultation/recommendation workflow. It is not
a complete market comparison and should be expanded category by category.

## Deterministic matching

`preview_consultation_scores(consultation_id, scoring_version)` calculates
explainable product scores from structured requirements and product facts.

`generate_consultation_recommendations(consultation_id, scoring_version)`
persists ranked recommendations and explicit gap records.

The v1 score separates functional fit, mandatory requirements, integrations,
deployment, budget, regional fit and security. Evidence confidence is returned
as a separate signal. A mandatory unknown or unsupported capability prevents a
product from being presented as an unconditional match.

The AI consultation layer may explain these results, ask follow-up questions and
summarize trade-offs, but it must not invent product facts or override the
structured matching result.
