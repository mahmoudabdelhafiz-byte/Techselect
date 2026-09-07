# TechSelectAI

TechSelectAI is an evidence-backed software and technology advisory platform operated by Barmageyat.

## V1 release candidate stack

- React + Vite frontend
- PHP 8.x API
- MariaDB/MySQL
- Apache/mod_rewrite for cPanel-style shared hosting
- deterministic recommendation scoring in PHP
- server-side OpenAI requirement extraction; AI does not rank products
- evidence-backed product/capability knowledge model
- account verification/password reset, RBAC, CSRF and rate limiting
- SEO sitemap/robots/canonical metadata

## V1 MariaDB setup

Import in order:

1. `db/mysql/001_v1_schema.sql`
2. `db/mysql/002_seed_identity_products.sql`
3. `db/mysql/003_recommendation_runs_and_ai_fields.sql`
4. `db/mysql/004_release_security_and_fit.sql`

Then follow `docs/V1_SHARED_HOSTING.md`.

## Core recommendation rules

- AI may interpret and structure requirements, but final ranking is deterministic.
- `unknown` and `not_yet_verified` are not treated as `not_supported`.
- mandatory gaps remain visible.
- evidence confidence is separate from fit.
- integration, deployment and commercial dimensions are scored only when relevant consultation inputs exist; omitted optional dimensions do not penalize the user.
- ownership or sponsorship never adds ranking points.
- recommendation refreshes create versioned runs rather than silently rewriting old results.

## Initial curated dataset

The first launch category is Corporate Identity & Digital Business Cards with CardIQ, Blinq and HiHello. CardIQ is disclosed as a Barmageyat product and remains subject to the same scoring/evidence rules.

## Architecture history

The repository retains earlier PostgreSQL/FastAPI migrations and documentation as architecture history. They are not used by the shared-hosting V1 runtime.

## Release status

PR #7 is the V1 shared-hosting release candidate. Merging the PR does not mean the application is deployed. Deployment requires the cPanel/MariaDB setup and smoke tests documented in `docs/V1_SHARED_HOSTING.md`.
