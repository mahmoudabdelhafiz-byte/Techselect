# TechSelectAI access levels

TechSelectAI currently uses two user-facing access levels that are separate from administrative roles. Paid plans are intentionally deferred while the product matures and becomes robust enough for monetization.

## Public / no login
Public research remains crawlable and should not be hidden behind authentication. This includes software search/browse, public product profiles, evaluations, comparisons, methodology, partner discovery and a limited AI consultant.

## Free registered
Registration unlocks the complete current software-selection workspace. This includes saved products/comparisons, persistent shortlists, selection projects, requirements capture, saved partner options, consultation resume, project tracking, advanced requirements discovery, contextual fit scoring, weighted decision matrices, advanced shortlists, full business cases, ROI/TCO models, RFP generation, management decision packs and rich exports.

## Future paid plans
The historical `pro` entitlement identifier and service-plan schema are retained only as dormant scaffolding so monetization can be reintroduced later without redesigning authentication or authorization. No current product capability requires Pro access, and the public plans page must not market or sell a Pro plan during this phase.

## Enforcement
- The canonical feature matrix lives in `app/lib/Entitlements.php`.
- Product access is enforced server-side with `Entitlements::requireFeature()`.
- Administrative `role` is not a paid-plan entitlement.
- Existing authenticated accounts default to `free_registered` through migration 033.
- Unknown/missing plan assignments fail safely to `free_registered`.
- Public features do not require a database plan row.
- Every current non-public product feature must require `free_registered`, not `pro`.

## Product boundary
TechSelectAI stops at software decision support and decision-pack generation. Procurement execution, purchase requisitions, approval workflows, purchase orders, contract execution and invoicing remain outside scope.
