# Evidence-led Catalog Expansion Planner

Issue: #96

## Why this phase exists

TechSelectAI already contains two substantial evidence-led catalog batches:

- `038_catalog_expansion_batch2.sql`: Endpoint Security, Backup & Disaster Recovery, Business Intelligence & Analytics, Project & Work Management.
- `039_catalog_expansion_batch3.sql`: AI Platforms, Healthcare & EHR, Retail POS, CAD & Engineering.

The remaining #96 process gap is deciding **what to research next** without expanding the catalog arbitrarily or outrunning evidence-review capacity.

## Admin workspace

`/catalog-expansion`

The planner combines four first-party demand signals:

1. `taxonomy_expansion_queue` occurrences and editorial priority.
2. Buyer intent events tied to an existing category.
3. Consultations tied to an existing category.
4. Google Search Console query/page impressions and clicks when imported.

The dashboard supports 30, 90, 180 and 365-day windows.

If Search Console data has not been imported, Search Console contribution is zero. The planner does not infer or fabricate search demand.

## Two independent decisions

### Demand priority

Demand signals determine research order only. A high priority score means a category/topic deserves investigation sooner; it does not improve any software score, Fit Score, evaluation, ranking or recommendation.

### Publication readiness

For an existing category, the planner's conservative readiness indicator requires at least:

- 4 active products
- 3 products meeting the current catalog publication baseline
- 4 verified evidence sources
- 12 known capability facts

`not_yet_verified` capability facts do not count as known facts. **Unknown != Unsupported.**

This dashboard readiness indicator does not replace existing product publication rules, sitemap evidence gates, evaluation review, or programmatic SEO quality gates. Those remain separate safety boundaries.

## New category candidates

Uncovered taxonomy topics are displayed as research candidates. The planner does not automatically create categories, vendors, products or capability claims. Before a new category is added, it must go through the normal evidence-led catalog process using official/permitted sources and conservative structured facts.

Topics that exactly normalize to an existing active category name/slug are excluded from the new-category queue. Broader semantic alias consolidation remains a human taxonomy-review task.

## Guardrails

- No automated catalog creation or publication.
- No unsupported pricing, compliance, regional availability or partner claims.
- No demand-based changes to deterministic scoring.
- No G2/Capterra content or ratings are used by this planner.
- Evidence completeness can block publication even when demand is high.
- Existing catalog batches are not duplicated simply to increase product counts.

## Deployment

No new database migration is required for this phase. It reuses the taxonomy, buyer-intent, consultation, Search Console, catalog and evidence tables already present.

After deployment, use `/catalog-expansion` to decide the next evidence-research batch, then implement that batch separately with its own source review and validation.
