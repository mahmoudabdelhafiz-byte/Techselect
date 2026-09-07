# V1 shared-hosting deployment

This application layer targets cPanel-style shared hosting with PHP 8.x, MariaDB/MySQL and Apache mod_rewrite while preserving the TechSelectAI product model established in PostgreSQL migrations 001-006.

## Architecture

- Frontend: React + Vite, compiled to static files.
- API: PHP using PDO prepared statements.
- Database: MariaDB/MySQL (`db/mysql/001_v1_schema.sql`).
- Scoring: deterministic PHP (`app/lib/Scoring.php`); AI never ranks products.
- AI: server-side OpenAI integration is reserved behind `OPENAI_API_KEY`; no browser secret.
- SEO: PHP serves `/robots.txt`, `/sitemap.xml`, public knowledge APIs; React sets canonical/meta/JSON-LD for public pages.

## Shared-hosting release

1. Create a MariaDB database/user in cPanel.
2. Import `db/mysql/001_v1_schema.sql` in phpMyAdmin.
3. Add the curated launch data. PostgreSQL seed SQL cannot be imported verbatim; port data values, not PostgreSQL syntax.
4. Configure environment variables where supported, or copy `app/config.example.php` to a non-public server config path and load credentials securely. Never commit production passwords/API keys.
5. Run `npm install && npm run build` locally or in CI under `frontend/`.
6. Upload `frontend/dist/*`, `.htaccess`, `api/`, and `app/` to the hosting document root. Keep config/secrets outside public web access when cPanel permits.
7. Confirm `/health`, `/robots.txt`, `/sitemap.xml`, `/software`, and a product page.

## Compatibility principles

The MariaDB model preserves `unknown` / `not_yet_verified` separately from `not_supported`, evidence remains first-class, ownership/sponsorship never adds ranking points, and mandatory gaps remain visible. PostgreSQL stored recommendation functions are not used by the hosted V1; equivalent deterministic rules live in PHP to keep deployment portable.

## Follow-up before public launch

- Port the curated CardIQ/Blinq/HiHello seed into MariaDB and verify source freshness.
- Complete AI extraction/confirmation endpoints in PHP.
- Add authentication/admin RBAC and CSRF/rate-limit controls.
- Persist generated recommendation snapshots and findings (current PHP endpoint calculates the deterministic shortlist but does not yet write every result row).
- Add production mail for account verification/reset.
