# RFP Generator

TechSelectAI generates software-selection RFP drafts from a saved selection project and the latest project decision-matrix run.

## Tiering
- Registered: read-only preview/basic template from owned projects.
- Pro: create and edit persisted RFP drafts through server-side `rfp_generator` entitlement enforcement.

## Data rules
- Confirmed project requirements are reused; no re-entry is required.
- AI-suggested/inferred requirements remain identifiable in the generated sections and are listed as assumptions requiring confirmation.
- Evaluation criteria come from the latest saved decision-matrix weights when available.
- Each persisted RFP stores a frozen source snapshot with project version, matrix run/scoring version, and selected product IDs.

## Boundary
RFP preparation is decision support only. Supplier-response portals, bid submission, supplier onboarding, approvals, PO creation, invoice processing, and procurement execution are explicitly outside scope.
