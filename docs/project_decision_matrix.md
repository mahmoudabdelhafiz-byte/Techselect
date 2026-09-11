# Project contextual decision matrix

Issue: #206

The matrix consumes confirmed requirements from a saved `selection_project` and produces a buyer-specific project fit score. It never overwrites or substitutes a public TechSelectAI evaluation score.

## Access
- Registered: saved shortlist, default approved weights, shortlist states.
- Pro: weight overrides, sensitivity analysis, contextual matrix export.

## Deterministic rules
- Uses the existing `Scoring` support mappings, so `unknown` / `not_yet_verified` are not treated as unsupported.
- Mandatory requirements are evaluated separately and unresolved mandatory gaps sort before weighted fit.
- Missing optional dimensions are omitted and remaining evaluated weights are renormalized; missing data is never silently scored as 100%.
- Historical runs save scoring version, weights and an input snapshot.
- Project fit and baseline public evaluation are stored as separate fields.

## Current dimensions
Functional, mandatory, integrations, deployment, commercial/budget, regional availability, security/compliance where canonical evidence can be resolved, and implementation when evidence becomes available.

Verified local implementation-partner coverage is intentionally not fabricated. The result exposes an empty partner set until the separate partner-marketplace data model provides verified territory relationships.

## Workflow
1. Create and confirm a selection project and its requirements.
2. Open `/decision-matrix?project_id={id}`.
3. Generate the contextual shortlist.
4. Review contribution by criterion and mandatory gaps.
5. Mark products researching / shortlisted / rejected / preferred.
6. Pro users may change weights, run sensitivity analysis and export the saved matrix.

The saved shortlist is designed to feed Business Case, ROI/TCO, RFP and Decision Pack modules.