# Editorial SEO decision-content program — Phase 3

Issue: #137

This phase adds three authored, evidence-aware decision guides:

- `/guides/crm-egypt-b2b`
- `/guides/erp-uae-enterprise`
- `/guides/project-management-construction-mena`

## Editorial principles

1. Each page answers a specific buyer question rather than publishing a generic listicle.
2. Product rows come from the canonical TechSelectAI catalog and are ordered alphabetically.
3. Evidence coverage is shown as a data-quality signal and is not converted into a public ranking.
4. Missing local/regional/language/commercial evidence is explicitly disclosed as not yet verified rather than unsupported.
5. Country or industry context is not treated as proof of local availability, regulatory compliance, Arabic support, pricing or implementation-partner capacity.
6. The construction/engineering guide explicitly distinguishes general project/work management from specialist construction-management capabilities.
7. Every guide links to the relevant category, methodology, trust disclosure and personalized consultation flow.

## Scope boundary

This work is authored editorial content only. It does not duplicate:

- #183 programmatic long-tail generation
- #184 programmatic SEO quality gates
- #181 Search Console measurement

Topic selection expands the current editorial footprint into Egypt and UAE and adds a MENA industry scenario where the underlying CRM, ERP and project-management catalogs already contain structured product evidence. Search Console and buyer-intent performance should be used to reprioritize subsequent editorial phases rather than retroactively invent demand claims for these pages.

## Validation

Run:

`php scripts/seo_editorial_phase3_check.php`

The regression contract checks route/discovery registration, canonical-data usage, alphabetical ordering, evidence boundaries, consultation CTA, and scope language.