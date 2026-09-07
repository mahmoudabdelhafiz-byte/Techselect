# V1 shared-hosting deployment

This application layer targets cPanel-style shared hosting with PHP 8.x, MariaDB/MySQL and Apache mod_rewrite while preserving the TechSelectAI product model established in PostgreSQL migrations 001-006.

## Architecture

- Frontend: React + Vite, compiled to static files.
- API: PHP using PDO prepared statements.
- Database: MariaDB/MySQL (`db/mysql/001_v1_schema.sql`).
- Scoring: deterministic PHP (`app/lib/Scoring.php`); AI never ranks products.
- AI: server-side OpenAI Responses API integration (`app/lib/AiExtraction.php`); no browser secret.
- SEO: PHP serves `/robots.txt`, `/sitemap.xml`, public knowledge APIs; React sets canonical/meta/JSON-LD for public pages.

## Shared-hosting release

1. Create a MariaDB database/user in cPanel.
2. Import these files in order using phpMyAdmin:
   - `db/mysql/001_v1_schema.sql`
   - `db/mysql/002_seed_identity_products.sql`
   - `db/mysql/003_recommendation_runs_and_ai_fields.sql`
3. Copy `app/config.example.php` to `app/config.php` on the server and provide the MariaDB credentials. Keep production secrets out of Git.
4. Set `OPENAI_API_KEY` and optionally `OPENAI_MODEL` in the hosting environment. If no API key is configured, the site remains usable for manual requirement confirmation but does not claim AI extraction occurred.
5. Run `npm install && npm run build` under `frontend/` locally or in CI.
6. Upload `frontend/dist/*`, `.htaccess`, `api/`, and `app/` to the hosting document root. When cPanel permits, keep the config file above the public web root and adjust its include path.
7. Confirm `/health`, `/robots.txt`, `/sitemap.xml`, `/software`, a product page, and one complete consultation: start → message → review/confirm → recommendations.

## Compatibility principles

The MariaDB model preserves `unknown` / `not_yet_verified` separately from `not_supported`, evidence remains first-class, ownership/sponsorship never adds ranking points, and mandatory gaps remain visible. PostgreSQL stored recommendation functions are not used by the hosted V1; equivalent deterministic rules live in PHP to keep deployment portable.

Recommendation refreshes create a new `recommendation_runs` record and preserve the prior recommendation snapshot rather than silently rewriting history.

## Implemented V1 launch dataset

The MariaDB seed currently includes the first evidence-led comparison category, Corporate Identity & Digital Business Cards, with CardIQ, Blinq and HiHello. It also preserves explicit CardIQ SCIM and native Entra provisioning gaps from the curated source set rather than converting those gaps to unknowns.

## Remaining public-launch blockers

- Add authentication/account flows and admin RBAC.
- Add CSRF protection and API rate limiting for write/AI endpoints.
- Add production email verification/password reset delivery.
- Verify all seeded evidence URLs/freshness immediately before launch.
- Add deployment/integration/commercial dimensions to the MariaDB scorer instead of the current neutral placeholders where consultation data is absent.
- Add server-rendered/static SEO snapshots for high-value public routes if stronger crawler rendering is required beyond the current React metadata layer.
