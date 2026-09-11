# AI / Search Crawler Readiness Checklist

TechSelectAI public knowledge content should remain directly reachable, server-rendered, canonical and indexable. This checklist is the release contract for technical discoverability.

## Public surfaces
- `/software/{slug}`
- `/categories/{slug}`
- `/capabilities/{slug}`
- `/integrations/{slug}`
- `/compare/{a}-vs-{b}`
- `/guides/{slug}`
- `/case-studies/{slug}`
- `/methodology`
- `/trust`
- `/about-techselectai`

These pages must return meaningful HTML without requiring login or client-side interaction.

## robots.txt
- `OAI-SearchBot` explicitly allowed.
- Googlebot and Bingbot explicitly allowed.
- Claude and Perplexity crawler families are not intentionally blocked.
- Public knowledge routes are not disallowed by the wildcard policy.
- Authenticated/admin/API routes remain disallowed.
- Sitemap location is declared.

## Canonical behavior
- HTTP and `www` redirect to `https://techselectai.com`.
- Public software/category/capability/integration/comparison pages emit one canonical URL.
- Trailing-slash variants resolve to the same canonical path.
- Public knowledge pages emit `index,follow` robots directives.
- Authenticated/admin workspaces remain noindex and excluded from robots discovery.

## Sitemap
- Contains indexable active software with sufficient evidence coverage.
- Contains qualified categories, capabilities, integrations and comparisons.
- Contains decision guides and approved case studies.
- Uses content-derived `lastmod` where a reliable timestamp exists.
- Does not include authenticated/admin/API routes.

## Citation/readability
- Important sections are server-rendered HTML.
- Public factual/evaluation sections use stable headings/section IDs where available.
- Product facts expose evidence/confidence/freshness context.
- `llms.txt` points retrieval systems to the canonical knowledge surfaces but does not replace HTML/sitemap content.
- Methodology and ownership/independence disclosures remain public.

## Release verification
Run:

```bash
php scripts/crawlability_contract_check.php
```

For deployed environments also verify representative URLs with a normal browser and crawler-like user agent, checking HTTP 200, one canonical URL, `index,follow`, and no authentication/JS requirement.

## Important limitation
Technical crawlability does not guarantee indexing, ranking, citation, or inclusion in any AI/search product. Those outcomes also depend on relevance, source quality, authority, freshness and each provider's retrieval/ranking systems.
