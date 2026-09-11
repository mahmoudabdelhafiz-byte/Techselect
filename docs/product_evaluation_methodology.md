# TechSelectAI Product Evaluation Methodology v1.0

## Purpose

TechSelectAI keeps two scores separate:

1. **Product Evaluation** — a reusable, product-level assessment of the software itself.
2. **Buyer Fit Score** — a project-specific assessment of how well that software fits one buyer's confirmed requirements.

A strong product can be a poor fit for a specific buyer, and a high buyer Fit Score does not automatically mean the product has the strongest general product evaluation.

## Product evaluation dimensions

The initial v1.0 methodology uses these dimensions:

| Dimension | Weight |
| --- | ---: |
| Usability | 12% |
| Implementation complexity | 10% |
| Integration depth | 15% |
| Administration overhead | 8% |
| Value | 10% |
| Support & community | 10% |
| Security & compliance | 15% |
| Enterprise suitability | 10% |
| SMB suitability | 5% |
| Product maturity | 5% |

Scores use a 0–10 scale. Missing dimensions are not silently treated as perfect scores. Published overall scores are calculated only from evaluated dimensions, with available weights re-normalized.

## Evidence and confidence

Every published dimension should have:
- a score or an explicit unavailable state;
- a rationale;
- supporting evidence references where applicable;
- an evidence count;
- an independent confidence score.

Confidence is intentionally separate from the product score. A product may score highly on a dimension while the confidence remains limited if evidence is sparse, stale, conflicting, or mostly vendor-provided.

Suggested confidence labels:
- **High:** 0.85–1.00
- **Moderate:** 0.65–0.84
- **Limited:** 0.40–0.64
- **Insufficient:** below 0.40

## Evidence boundaries

TechSelectAI should distinguish:
- verified or independently corroborated facts;
- vendor-provided facts;
- public community signals;
- TechSelectAI analysis;
- buyer assumptions or estimates.

Unknown means not yet verified. It must not be interpreted as unsupported.

## Public presentation

A published evaluation may appear on the public software profile with:
- the overall TechSelectAI Product Evaluation score;
- evidence confidence;
- best-for guidance;
- dimension-level scores and rationale;
- linked evidence count;
- evaluation date;
- methodology version;
- limitations where applicable.

If a product has no published evaluation, the software profile remains available without inventing or inferring a score. Draft, proposed, stale, or unapproved evaluations are not shown as published scores.

## Publication workflow

Product evaluations are versioned and use controlled publication states. The initial workflow is:

`draft → proposed_change → approved → published`

Additional states may include `stale` and `insufficient_evidence`.

AI may help generate or recalculate proposed scores and rationale, but an AI-generated change must not silently overwrite a published evaluation. Human reviewer approval is required before publication.

## Methodology versioning

Every product evaluation references a methodology version. Material changes to dimensions, weights, confidence policy, or evidence rules require a new methodology version so historical evaluations remain interpretable.

## Independence

Commercial relationships, sponsorships, featured placement, reseller relationships, vendor claims, advertising, or ownership must not directly alter TechSelectAI Product Evaluation scores or buyer Fit Scores.
