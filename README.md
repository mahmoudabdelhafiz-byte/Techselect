# TechSelectAI

TechSelectAI is an evidence-backed software and technology advisory platform. The repository contains both the historical PostgreSQL architecture work and the current shared-hosting V1 application target.

## Current V1 deployment stack

The release target is:

- React + Vite frontend
- PHP 8.x API
- MariaDB/MySQL
- Apache/mod_rewrite on cPanel-style shared hosting
- deterministic PHP scoring
- server-side OpenAI requirement extraction only; AI does not rank products

See `docs/V1_SHARED_HOSTING.md` for deployment steps.

## MariaDB setup

Import in this order:

```text
db/mysql/001_v1_schema.sql
db/mysql/002_seed_identity_products.sql
db/mysql/003_recommendation_runs_and_ai_fields.sql
```

The initial curated dataset covers Corporate Identity & Digital Business Cards with CardIQ, Blinq and HiHello. Unknown/not-yet-verified capability states remain distinct from explicit not-supported facts.

## PostgreSQL architecture reference

The original Phase 1 architecture remains under `db/migrations/`. It documents the consultation/analytics model, technology knowledge graph, deterministic scoring contract and AI extraction boundaries developed in Sprints 1.1-1.5. These PostgreSQL migrations are retained as design/history; they are not the database migrations used by the shared-hosting V1.

## Product rules preserved in both architectures

- AI may extract, normalize and explain requirements, but cannot decide rankings.
- Product recommendations come from deterministic scoring over structured facts.
- `unknown` is not the same as `not_supported`.
- Evidence is first-class and confidence remains separate from fit.
- Mandatory gaps remain visible.
- Ownership or sponsorship must not add ranking points.
- Recommendation refreshes preserve prior run snapshots rather than silently changing an old recommendation.
