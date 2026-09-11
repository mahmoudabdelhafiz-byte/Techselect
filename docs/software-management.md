# Software Management

The `/software-management` workspace is the operational catalog-management surface for TechSelectAI.

## Capabilities
- Search/filter products by name, vendor, category and lifecycle state.
- Open a product detail drawer with Overview, Capabilities, Pricing, Integrations, Deployment, Evidence, Community Intelligence, TechSelectAI Evaluation, SEO and Change History tabs.
- Edit factual metadata: name, short description, official website, vendor, category and lifecycle status.
- Open the public software page directly.
- Bulk move selected products to `draft` or `archived`.
- Inspect a publishing-readiness checklist before activation.

## Publishing readiness
The current checklist checks vendor/category assignment, official URL, evidence quantity/health, capability coverage, pricing, deployment, integrations, published community intelligence, fresh published TechSelectAI evaluation, and public SEO basics. Optional modules are handled defensively when their tables are not yet deployed.

A transition from `draft` or `archived` to `active` requires a reviewer/admin/super-admin and must pass the readiness gate. Editing an already-active product does not count as a new activation.

## Audit and authorization
All product mutations use existing server-side role checks, CSRF/same-origin/rate limiting, and `Security::audit`. Safe bulk operations are limited to draft/archive; there is intentionally no bulk activation.
