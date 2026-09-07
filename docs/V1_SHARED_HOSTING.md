# V1 shared-hosting deployment

This V1 targets cPanel-style shared hosting with PHP 8.x, MariaDB/MySQL and Apache mod_rewrite.

## Architecture

- Frontend: React + Vite static build.
- API: PHP + PDO prepared statements.
- Database: MariaDB/MySQL.
- Scoring: deterministic PHP; AI never decides rankings.
- AI: server-side OpenAI Responses API only.
- SEO: `/robots.txt`, database-driven `/sitemap.xml`, canonical metadata and public software/capability/comparison pages.
- Accounts: email/password with verification/reset tokens.
- Admin: role-protected API + audit logging.

## Database import order

Import in phpMyAdmin in this exact order:

1. `db/mysql/001_v1_schema.sql`
2. `db/mysql/002_seed_identity_products.sql`
3. `db/mysql/003_recommendation_runs_and_ai_fields.sql`
4. `db/mysql/004_release_security_and_fit.sql`

The original PostgreSQL migrations remain architecture/history only and are not used by the hosted V1 runtime.

## cPanel release steps

1. Create the MariaDB database and least-privilege database user.
2. Import all four MariaDB migrations above.
3. Copy `app/config.example.php` to `app/config.php` on the server. Never commit the production copy.
4. Configure `DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASS`, `SITE_URL`, `OPENAI_API_KEY`, `OPENAI_MODEL`, and `MAIL_FROM` using the hosting environment where available.
5. Confirm PHP `mail()` sends from the configured domain. If the host disables it, replace the mail helper with the host SMTP transport before enabling public registration.
6. Run `npm install && npm run build` under `frontend/` locally or in CI.
7. Upload `frontend/dist/*`, `.htaccess`, `api/`, `app/`, `account.php`, and `admin.php` to the web root. Keep production config/secrets above the public root when the hosting layout permits.
8. Register the first administrator through `/register`, verify the email, then promote it once in phpMyAdmin:
   `UPDATE users SET role='super_admin', status='active', email_verified_at=COALESCE(email_verified_at,NOW()) WHERE email='YOUR_ADMIN_EMAIL';`
9. Sign in again and confirm `/admin` loads.

## Release security included

- secure/HttpOnly/SameSite session cookie configuration
- password hashing with PHP `password_hash`
- single-use hashed email-verification/password-reset tokens
- generic password-reset response to avoid account enumeration
- same-origin checks on state-changing endpoints
- CSRF token enforcement for authenticated writes
- database-backed IP rate limiting for registration, login, password reset, consultation writes, AI requests and recommendation generation
- RBAC for admin/data-editor/reviewer/super-admin roles
- audit logging for authentication and admin mutations
- CSP, frame protection, referrer policy and MIME-sniffing protection headers

## Recommendation behavior

The MariaDB scorer preserves `unknown` / `not_yet_verified` separately from `not_supported`. Mandatory gaps remain visible. Sponsorship/ownership never adds ranking points.

Functional fit and must-have fit are always evaluated. Integration, deployment and commercial dimensions are added only when the consultation includes those inputs; otherwise their weights are omitted and the remaining weights are renormalized. Evidence confidence remains separate from fit. Refreshing recommendations creates a new `recommendation_runs` record instead of silently replacing history.

## Launch dataset

The initial evidence-led category is Corporate Identity & Digital Business Cards, with CardIQ, Blinq and HiHello. Explicit CardIQ SCIM/native Entra provisioning gaps remain explicit rather than being converted into unknowns.

## Pre-release smoke test

Verify all of the following on the real hosting account before DNS/public launch:

- `/health` returns `php-mariadb`
- `/robots.txt` and `/sitemap.xml` load over HTTPS
- `/software`, CardIQ, Blinq and HiHello pages load
- registration → verification → login → logout works
- password-reset mail works
- anonymous consultation: start → AI message → confirm → recommendations works
- recommendation refresh produces a new run
- `/admin` rejects normal users and allows the promoted administrator
- admin product/evidence changes create audit-log rows
- rate limits return HTTP 429 after the configured threshold
- evidence URLs are re-opened manually and freshness/status updated if needed

## Known V1 boundaries

V1 launches with the first curated category, not the full planned 30–40-product catalog. Regional/security/implementation dimensions remain unscored unless structured product data is added for them. Public pages are React-rendered; server/static rendering can be added later if crawler testing shows it is necessary.
