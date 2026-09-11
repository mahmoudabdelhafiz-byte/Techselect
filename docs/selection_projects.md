# TechSelectAI Selection Projects

Selection Projects are the reusable buyer-context layer for the decision journey:

`Discover → Requirements → Evaluate → Shortlist → Partners → Business Case → ROI/TCO → RFP → Decision`

## Tiering
- Public: existing lightweight anonymous consultation/assessment remains available.
- Free Registered: create, save, edit and resume selection projects; capture structured requirements and integrations; generate an in-app Requirements Brief.
- Pro: advanced AI-assisted requirement provenance (`ai_suggested`, `inferred`) and richer downstream decision tooling.

## Data boundaries
A selection project can optionally link to a consultation. When linked, buyer context and consultation requirements are imported so the user does not re-enter information. Imported requirements preserve source/confirmation state rather than becoming user-entered facts.

Requirement sources:
- `user_entered`: explicitly provided by the buyer; confirmed by default.
- `ai_suggested`: proposed through guided AI discovery; requires buyer confirmation when not already confirmed upstream.
- `inferred`: derived from context; should remain visibly unconfirmed until accepted by the buyer.

Priority is separate from provenance. Mandatory requirements act as knockout criteria for downstream shortlist logic; important/preferred requirements are weighting inputs.

## Requirements Brief
The API returns a deterministic `requirements_brief` object containing project context, constraints, business objectives, structured requirements and integrations. Downstream modules should consume this object/project ID instead of creating their own parallel requirements store.

## Security
Every project and child record is user-owned. All writes require authentication, the `selection_projects` entitlement, same-origin validation, CSRF protection and rate limiting. Non-user provenance additions additionally require `advanced_requirements_builder` (Pro).