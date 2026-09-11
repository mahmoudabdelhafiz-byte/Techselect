# ROI / TCO model

TechSelectAI ROI/TCO modeling extends the software-selection project and Business Case journey without turning estimated benefits into verified facts.

## Source boundaries
- Buyer-entered costs and benefits are stored in `assumptions_json`.
- Missing inputs remain `null`/unknown and are listed in the result; they are not guessed.
- Catalog pricing is returned separately as `verified_pricing_json` reference evidence and is never silently inserted into buyer assumptions.
- Saved models freeze the project version, latest decision-matrix run/scoring version and shortlist state when available.
- Benefits and savings are always labeled as buyer assumptions/model outputs, not guaranteed outcomes.

## Outputs
Base calculations include Year 1 cost, selected-horizon TCO, explicit 3-year and 5-year TCO, cost/user/month, annual and total benefit, net benefit, ROI %, payback months, break-even year and input completeness.

## Scenarios
Pro models save conservative, base and optimistic sensitivity scenarios. The current deterministic sensitivity multipliers are: conservative +10% costs / -25% benefits; base unchanged; optimistic -5% costs / +20% benefits. These are sensitivity scenarios, not forecasts.

## Tiering
Registered users can run a temporary preview against an owned selection project. Pro users can persist models, scenarios and Business Case linkage through the existing `roi_tco_model` entitlement.

## Business Case integration
When a saved Pro ROI/TCO model is linked to an owned Business Case, a concise modeled summary is written into the Business Case `roi_assumptions` field. It remains explicitly categorized as an assumption, so the Business Case generator cannot mistake it for verified vendor evidence.
