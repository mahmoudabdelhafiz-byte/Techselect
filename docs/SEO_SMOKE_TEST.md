# TechSelectAI SEO smoke-test checklist

Run after each public SEO deployment.

## 1. Crawlability and HTTP
- `/robots.txt` returns 200 text/plain and points to `/sitemap.xml`.
- `/sitemap.xml` returns 200 XML, contains only intended public pages, and excludes login/register/account/admin/API/private consultation URLs.
- Canonical public routes return 200.
- Reversed comparison slugs return 301 to canonical alphabetical order.
- Unknown software/category/capability/integration/comparison slugs return 404, not SPA 200.

## 2. Initial HTML
Use `curl -s https://techselectai.com/<route>` and confirm the first response already contains:
- one descriptive `<title>`
- meta description
- canonical link
- H1 and meaningful page content
- product/capability/integration facts where applicable
- internal links to related public pages

Priority checks:
- `/software/cardiq`
- `/software/blinq`
- one `/categories/{slug}` route
- `/capabilities/sso`
- `/integrations/microsoft-entra-id`
- `/compare/blinq-vs-cardiq` (or the canonical ordering currently generated)

## 3. Structured data and social metadata
- BreadcrumbList JSON-LD parses correctly.
- Product pages include SoftwareApplication JSON-LD.
- Open Graph title, description, URL are present and match the canonical page.
- Do not add FAQ schema unless the visible page genuinely contains the corresponding FAQ.

## 4. Indexability quality
Run from the deployed application root:

```bash
php scripts/seo_audit.php
```

Interpretation:
- `INDEX` means the page meets the current sitemap quality threshold.
- `THIN` means the page can remain accessible, but should not be intentionally promoted for indexing until canonical facts/evidence improve.

Current thresholds:
- Product: at least 3 generic capability facts + at least 1 evidence source.
- Category: enough useful breadth (at least 2 active products; sitemap applies stronger indexable-product checks).
- Capability: at least 2 active products with a canonical fact.
- Integration: at least 2 active products and at least one non-zero-confidence integration fact.
- Comparison: same-category products, both sufficiently documented, with at least 3 overlapping capability facts.

## 5. Data integrity
- `unknown` / `not_yet_verified` must never be presented as `not_supported`.
- CardIQ ownership/sponsorship disclosure must remain separate from rankings/evidence scoring.
- No invented pricing, compliance, integration, deployment, language, or regional claims.
- Evidence links and last-verified dates should be visible where available.

## 6. Search Console after deployment
- Submit/resubmit `/sitemap.xml` when route coverage changes materially.
- Inspect priority URLs for canonical selection and crawlability.
- Monitor `Crawled - currently not indexed`, duplicate/canonical issues, soft 404s, and structured-data errors.
- Do not react to temporary indexing delays by generating thin pages at scale.
