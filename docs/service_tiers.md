# TechSelectAI service tiers

TechSelectAI uses three product tiers that are separate from administrative roles.

## Public / no login
Public research remains crawlable and should not be hidden behind authentication. This includes software search/browse, public product profiles, evaluations, comparisons, methodology, partner discovery and a limited AI consultant.

## Free registered
Registration adds persistence and workspace features such as saved products/comparisons, shortlists, selection projects, requirements capture, saved partner options, consultation resume, basic decision matrix, limited exports and project tracking.

## Pro
Pro applies TechSelectAI knowledge to the buyer's organization and unlocks advanced requirements discovery, contextual fit scoring, weighted decision matrices, advanced shortlists, full business cases, ROI/TCO models, RFP generation, management decision packs and richer exports.

## Enforcement
- The canonical feature matrix lives in `app/lib/Entitlements.php`.
- Product-plan access is enforced server-side with `Entitlements::requireFeature()`.
- Administrative `role` is not a paid-plan entitlement.
- Existing authenticated accounts default to `free_registered` through migration 033.
- Unknown/missing plan assignments fail safely to `free_registered`, never Pro.
- Public features do not require a database plan row.
- Pro access requires an active `pro` assignment that is not expired.

## Product boundary
TechSelectAI stops at software decision support and decision-pack generation. Procurement execution, purchase requisitions, approval workflows, purchase orders, contract execution and invoicing remain outside scope.
