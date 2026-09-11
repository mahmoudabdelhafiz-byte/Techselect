# Community Intelligence source collectors

This layer completes the automated collection boundary for TechSelectAI Community Intelligence without changing the existing analysis, scoring, or human-publication workflow.

## Supported collectors

### Stack Exchange API
- Uses the public Stack Exchange API endpoint configured in the connector.
- `api.stackexchange.com` is the only accepted API host for this collector type.
- Optional environment variable: `TECHSELECT_STACKEXCHANGE_KEY`.
- Captures upstream quota/backoff metadata in the collection run.

### RSS / Atom
- Reads a specific feed URL that has been reviewed and explicitly permitted by a TechSelectAI reviewer.
- This is not a general-purpose webpage scraper.
- XML parsing uses network-disabled XML parsing.

## Source-policy gate

Every connector is created with `policy_status=pending_review` and cannot run until a reviewer explicitly changes it to `permitted` with notes. Restricted or blocked connectors are not scheduled.

Individual collected URLs inherit `permitted` only from that explicitly permitted connector. G2 and Capterra remain blocked by the existing `PublicReviewIngestion` source-policy guard and are not implemented as collectors.

A Reddit collector is intentionally not included in this implementation. Reddit collection should only be added after the relevant API/use-case approval, credentials, and usage rights are confirmed for the intended commercial workflow.

## Product resolution

Collected text must contain the selected product's canonical name or an approved alias from `product_aliases`. This deterministic gate runs before an item is attached to a product. It avoids using AI alone to resolve ambiguous mentions.

## Processing flow

1. Reviewer creates connector.
2. Reviewer reviews source policy and explicitly permits it.
3. Collector fetches API/feed data.
4. Items are product-matched and content-fingerprint deduplicated.
5. Temporary normalized text is retained for at most seven days while pending analysis.
6. `PublicReviewAdminService::analyzeProduct()` runs the existing AI extraction/filtering pipeline.
7. Analysis text is deleted after processing.
8. Existing duplicate/spam/affiliate/vendor-promotion/bot/low-signal filters determine signal eligibility.
9. Existing Community Intelligence approval workflow determines whether aggregated intelligence becomes public.

Collection never publishes Community Intelligence automatically.

## Network safeguards

- HTTP/HTTPS only.
- localhost, private, and reserved IP destinations are rejected.
- Redirects are not followed, preventing a public URL from redirecting the collector into an internal address.
- Connect/read timeouts and response-size caps are enforced.
- RSS/Atom parsing uses `LIBXML_NONET`.

## Scheduler

`php scripts/community_collectors_cron.php`

Optional environment variables:
- `TECHSELECT_COMMUNITY_COLLECTOR_LIMIT` — max due connectors per run; defaults to 10.
- `TECHSELECT_COMMUNITY_AUTO_ANALYZE=1` — optionally run the existing AI analyzer after collection. Default is off.
- `TECHSELECT_STACKEXCHANGE_KEY` — optional Stack Exchange API key.

Keeping automatic analysis off is the conservative default. Even when enabled, publication still requires the existing human approval workflow.

## Admin

- `/community-collectors` manages source collectors and policy decisions.
- `/community-intelligence-admin` reviews derived intelligence before publication.
- `/pri-source-policy` remains the source-policy governance screen.
