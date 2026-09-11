# Indexation health completion (#182 / #254)

TechSelectAI's indexation health workspace combines three distinct signal families and keeps their meaning separate:

1. **Expected/sitemap coverage** — compares the known strategic URL inventory with `sitemap.xml`, including sitemap `lastmod` freshness where an application update timestamp is known.
2. **Live technical probes** — checks TechSelectAI's own configured canonical URLs for HTTP status, canonical tag, robots meta and basic wildcard `robots.txt` blocking. These probes do **not** infer search-engine indexation.
3. **Index-state observations** — imported from a real external indexation/search source (for example Search Console/manual verified observation) and stored with source metadata/history.

## Operational endpoints

- `GET /api/indexation-health`
- `POST /api/indexation-health/sync`
- `POST /api/indexation-health/probe`
- `POST /api/indexation-health/snapshot`
- `POST /api/indexation-health/import`

All mutation endpoints retain same-origin, CSRF, rate-limit and role controls.

## Safe probe boundary

Live probing is not a generic fetch service. URLs come only from `indexation_url_health`, whose canonical URLs are generated from the configured TechSelectAI `site_url`. Before every request, the host is checked against that configured host. Redirect following is disabled. An observed redirect/canonical is accepted only when it remains on the same host.

The robots parser intentionally implements a conservative basic check for `User-agent: *` plus prefix `Disallow` rules. It is a technical warning signal rather than a complete robots standard implementation.

## Daily snapshots and alerts

Migration `058_indexation_health_alerts.sql` adds daily strategic snapshots and persistent alerts.

Current alert rules:

- **Critical strategic index drop**: previous indexed strategic count is at least 5, and the latest snapshot drops by at least 3 URLs and at least 20%.
- **Technical exclusion spike**: strategic technical exclusions increase by at least 3 versus the prior daily snapshot.

Alerts resolve automatically when their condition clears. The dashboard shows active alerts and the most recent 30 snapshot days.

## Scheduler contract

`scripts/indexation_health_daily.php` can be invoked by the hosting scheduler/cron. It runs up to 100 same-host strategic probes and records the daily snapshot. The repository does not install or activate a production cron schedule automatically.

## Deployment

1. Deploy the merged application code.
2. Run `db/mysql/058_indexation_health_alerts.sql` after the existing indexation migration `048_indexation_health.sql`.
3. Open `/indexation-health` and run **Sync sitemap coverage**.
4. Run **Run live technical probes**.
5. Import real index-state observations when available.
6. Optionally configure the host scheduler to run `php scripts/indexation_health_daily.php` daily.

No code path equates a successful HTTP probe with a Google/Bing indexed state.
