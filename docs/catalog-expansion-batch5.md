# Catalog expansion batch 5

Issue: #259

Batch 5 adds five strategic enterprise software categories with four research-seed products each (20 products total): Observability & APM, Network Monitoring, Transportation Management Systems, Document Management, and E-signature.

## Publication policy

All new products are inserted directly as `draft`. The migration does not bypass TechSelectAI's current publication-readiness rules. Products may become active only after reviewer/admin approval and sufficient evidence, pricing/deployment/integration coverage, community intelligence where available, and a fresh TechSelectAI evaluation.

## Evidence boundaries

Initial facts use official vendor-owned product/documentation sources only. Broad capabilities that are clearly supported are recorded with confidence and linked to the official evidence record. Everything else remains `not_yet_verified` rather than being interpreted as unsupported.

This seed does not import third-party marketplace reviews/ratings and does not fabricate pricing, compliance, regional availability, integrations or partner relationships.

## Migration

Run `db/mysql/061_catalog_expansion_batch5.sql` after the preceding migrations.

Merging this change does not execute the migration or deploy the catalog to production.

## Validation

Run `php scripts/catalog_expansion_batch5_check.php`.

The contract checks the five categories, 20 canonical product slugs, draft publication state, restricted-source exclusion, `Unknown != Unsupported`, and the absence of fabricated pricing/regional/partner facts.

## Research-enrichment priority

After seeding, enrich products in this order where buyer demand warrants it: additional official evidence, deployments, integrations, pricing evidence, permitted community intelligence, TechSelectAI evaluation, then publication-readiness review. MENA implementation/partner evidence should be added only when independently verified rather than inferred from global vendor presence.
