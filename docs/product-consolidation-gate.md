# Product consolidation gate

TechSelectAI is in a consolidation phase while catalog/evidence depth catches up with product surface area.

## Core rule

Do not add a new major subsystem while fewer than 3 strategic categories are publication-ready according to `CatalogExpansionPlanner`.

The strategic categories are CRM, ITSM, HRMS/HCM, Endpoint Security/EDR, and Backup/Disaster Recovery. The live readiness result is visible in **Admin → Catalog Expansion** and is based on active-product depth, known capability facts, verified/fresh evidence, and unresolved readiness gaps.

This governance rule does **not** alter Fit Score, Product Evaluation, recommendation ranking, sponsorship handling, or evidence confidence.

## Work allowed during a freeze

The following work remains allowed without an exception:

- bug fixes and regression fixes
- security/privacy hardening
- evidence/catalog depth and freshness work
- migration/data integrity fixes
- accessibility and usability corrections
- performance/reliability work
- tests, CI, documentation, observability and deployment safety
- small improvements to existing RFP, ROI/TCO, Decision Pack, vendor self-service, paid-tier, authority/outreach and SEO tooling that do not create a new major subsystem

## What counts as a major-surface candidate

CI treats a newly-added top-level PHP page, a newly-added top-level API endpoint, or a newly-added frontend page/route module as a possible new product surface. This is intentionally conservative: a flagged PR is not automatically bad, but it requires an explicit maintainer exception label while the freeze is active.

Use the label:

`consolidation-exception`

Only apply it when the PR has a documented user-demand reason and the migration/runtime/support impact has been reviewed.

## Primary buyer journey

Keep the core journey prominent:

**Discover → Requirements → Evaluate → Shortlist → Decide**

Advanced tools should remain secondary and feature-gated where appropriate.

## Release checklist

Every substantial PR should answer:

- Is this quality/security/evidence/usability work rather than a new subsystem?
- Does it preserve ranking and evidence neutrality?
- Has migration/runtime impact been reviewed?
- Has the affected buyer/admin flow been regression-checked?
- If it creates a new major surface during the freeze, is `consolidation-exception` justified?

## Exit condition

The freeze may be considered satisfied when the Catalog Expansion dashboard reports at least **3 strategic categories publication-ready**. Reaching that threshold does not require immediately building new subsystems; future major work should still be prioritized by real buyer demand.

For deployment, remember that merged catalog migrations must actually be executed in production before production readiness can change.
