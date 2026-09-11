# Public conversion and neutral monetization

Issue: #13

## Public → decision journey
Public software, category, capability, integration and comparison pages already expose contextual CTAs into the lightweight TechSelectAI consultation flow. Visitors are not required to register before starting the evaluation journey. Registration remains appropriate when persistence, saved projects or Pro exports are needed.

## Conversion measurement
Migration `057_public_conversion_events.sql` stores aggregate CTA exposure/click events:
- `cta_impression`
- `cta_click`
- source page/type/context
- CTA id and destination path
- one-way session hash when a PHP session exists

The public endpoint is `POST /api/public-conversion`. The shared crawlable public-page wrapper records one impression per page/sessionStorage lifecycle and a click when the primary selection CTA is used.

Authorized admins/data editors can read aggregate metrics with `GET /api/public-conversion?days=30`, including impressions, clicks, CTR, unique clicking sessions, source-type breakdown and top converting pages.

No private consultation text, email address or raw session token is stored.

## Neutrality boundary
Conversion or monetization analytics must never affect:
- TechSelectAI Product Evaluation
- buyer Fit Score
- recommendation order
- shortlist position
- evidence confidence
- Community Intelligence publication

Existing sponsored/affiliate surfaces remain visually separated from independent evidence and recommendation outputs. Sponsorship is not rendered inside AI recommendations or Decision Packs.

## Deployment
Run migration `057_public_conversion_events.sql` before relying on conversion metrics. The public pages remain usable if tracking is unavailable because tracking calls are best-effort only.
