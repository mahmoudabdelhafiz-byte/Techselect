# TechSelect data architecture

This repository contains the PostgreSQL foundation for TechSelect's Phase 1
consultation, first-party analytics, and evidence-backed technology knowledge platform.

## Apply the schema

The migrations target PostgreSQL 15 or newer. Apply them in order:

```bash
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 \
  -f db/migrations/001_consultation_analytics.sql

psql "$DATABASE_URL" -v ON_ERROR_STOP=1 \
  -f db/migrations/002_technology_knowledge_graph.sql

psql "$DATABASE_URL" -v ON_ERROR_STOP=1 \
  -f db/migrations/003_fix_product_wide_edition_scope.sql
```

Run the lightweight repository checks with:

```bash
./scripts/check-schema.sh
./scripts/check-knowledge-schema.sh
```

The consultation model intentionally permits anonymous consultations through a
visitor session. `link_visitor_session_to_user` atomically claims that session
and its consultations, analytics events, and searches after account creation.
Raw messages and company-level data remain operational records; dashboards
should use the aggregated views from the first migration.

The technology knowledge graph extends the minimal product dimensions from the
first migration. Products can belong to multiple categories and modules, expose
edition-specific pricing, deployment models, integrations, countries,
languages, industries, compliance frameworks, and capabilities. Capability
support is never reduced to a simple yes/no value: unknown and not-yet-verified
states remain explicit.

Deployment, integration, and compliance facts may be product-wide or scoped to
an edition. Migration 003 replaces primary keys that would otherwise force
`edition_id` to be non-null with NULL-safe unique indexes.

Evidence is first-class. Capability facts can link to multiple evidence sources,
carry confidence and verification timestamps, and retain verification history.
The `product_capability_evidence_summary` and `product_knowledge_coverage` views
provide freshness and coverage signals for the recommendation engine and admin
review workflows.
