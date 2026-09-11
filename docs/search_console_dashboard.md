# Search Console SEO dashboard

Admin route: `/search-console`

This first implementation uses controlled manual or scheduled JSON imports so TechSelectAI can start using real Google Search Console data without requiring OAuth credentials in the application repository.

Supported performance dimensions: date, query, page, country, device and search appearance. Supported metrics: clicks, impressions, CTR and average position.

The dashboard provides 7/28/90-day views, previous-period comparisons, Top 10/20/50 query buckets, quick-win queries in positions 11–30, high-impression/low-CTR pages, gaining pages, declining pages, new queries, country/device/search-appearance breakdowns and CSV export.

Import endpoint: `POST /api/search-console/import`.

Required metadata: `date_from`, `date_to`. Optional metadata: `property_uri`, `source_label`.

Performance rows are supplied under `rows`. Optional Google URL-inspection/index-state rows can be supplied under `index_rows`; those are routed into the separate `IndexationHealth` model with source `google_search_console`. This separation is deliberate: Search Analytics performance data is not proof of index status.

The API is reviewer/admin/super-admin only and uses same-origin, CSRF, rate limiting and audit logging.

A later connector can call the Google Search Console Search Analytics and URL Inspection APIs on a schedule and submit the same normalized row contracts without changing dashboard logic.