# TechSelectAI Indexation Health Monitoring

## Purpose
This admin capability compares the application’s known public strategic URLs with the live XML sitemap and stores known search-index states when external data is available.

## Admin surface
`/indexation-health`

The dashboard highlights:
- known public URLs
- strategic URLs
- sitemap coverage
- indexed URLs when index-state data has been imported
- discovered/crawled but not indexed URLs
- technical exclusions such as noindex, redirects, canonicalized duplicates, 404s and soft-404s
- URLs needing attention

## Strategic URL policy
Software profiles, category pages and comparison pages are strategic by default. High-value URLs that remain in `discovered_not_indexed` or `crawled_not_indexed` for 14 days after discovery are surfaced for attention.

## Sitemap audit
The Sync action reads the deployed `/sitemap.xml`, inventories known public URLs from the application model, and flags expected URLs missing from the sitemap. A failed or invalid sitemap does not overwrite coverage with false negatives; the sync fails instead.

## External index-state data
Actual search-engine index status must come from an external source such as Google Search Console or another verified inspection process. The initial implementation supports controlled JSON import and records the source plus immutable state history. #181 can later provide direct Search Console ingestion.

Supported states:
- `unknown`
- `indexed`
- `discovered_not_indexed`
- `crawled_not_indexed`
- `excluded_noindex`
- `redirect`
- `duplicate_canonicalized`
- `not_found`
- `soft_404`

Optional imported technical observations include HTTP status, observed canonical URL, meta robots, robots allowance and crawl/index timestamps.

## Separation of concerns
Internal sitemap/canonical checks are not represented as proof that Google or another search engine has indexed a page. Imported external index states always retain a source label.
