# Catalog expansion batch 2

Issue: #224 (phase of #96)

## Added categories
- Endpoint Security
- Backup & Disaster Recovery
- Business Intelligence & Analytics
- Project & Work Management

## Added products
16 products, four per category. Each product is linked to an official vendor-owned source and receives a deliberately small set of broad, defensible capability facts. Unresearched category capabilities are inserted as `not_yet_verified`, never `not_supported`.

## SEO / sitemap behavior
The public sitemap remains evidence-gated. A product page is included only when the product is active, has at least three product-capability rows, and has at least one evidence source. Category pages require at least two qualifying products. This batch satisfies those gates for all four categories. Category sitemap entries now use the newest qualifying product `updated_at` as `lastmod`.

Because same-category products have at least three shared capability records, the existing comparison-page sitemap logic can also expose evidence-ready pairwise comparison URLs.

## Boundaries
- No pricing facts are introduced in this batch.
- No compliance certification claims are introduced.
- No rankings or partner relationships are introduced.
- Deployment is asserted only for clearly cloud-delivered BI/work-management products; other deployment modes remain unverified.
- Further product-specific evidence enrichment should be handled by the evidence refresh/review workflow.
