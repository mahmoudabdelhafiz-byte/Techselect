# Catalog expansion batch 4

Issue: #257

## Scope

Batch 4 expands the research catalog into five high-value enterprise categories:

- SIEM & Security Operations
- Identity & Access Management
- Privileged Access Management
- Warehouse Management Systems
- Low-Code & BPM Platforms

Each category is seeded with four established products (20 products total).

## Evidence policy

Initial product facts use vendor-owned official documentation only. The batch intentionally does not import G2/Capterra ratings or reviews and does not invent pricing, compliance, regional availability, integrations, partner relationships or unsupported capabilities.

Known capabilities are linked to their official evidence source. Unresearched category capabilities are stored as `not_yet_verified`; they are never converted to `not_supported` simply because the seed research did not verify them.

## Publication state

The product records are research seeds, not automatically publication-ready listings. Migration `060_catalog_expansion_batch4_readiness_guard.sql` leaves all 20 products in `draft` after the seed migration runs.

They should move to `active` only through the existing reviewer/admin activation workflow after the product meets current readiness expectations, including deeper evidence, pricing/deployment/integration coverage, community intelligence where available, and a fresh TechSelectAI evaluation.

## Migrations

Run in order:

1. `db/mysql/059_catalog_expansion_batch4.sql`
2. `db/mysql/060_catalog_expansion_batch4_readiness_guard.sql`

Neither migration is executed by merging this change.

## Validation

Run:

`php scripts/catalog_expansion_batch4_check.php`

The contract verifies the five categories, all 20 product slugs, draft-state guard, restricted-source exclusion, `Unknown != Unsupported`, and absence of fabricated pricing/compliance/regional facts.

## Next candidate batch

After Batch 4 evidence enrichment, the next catalog wave should cover observability/APM and network monitoring, transportation management systems, and document management/e-signature. Keep the same evidence/readiness discipline rather than bulk-publishing thin listings.
