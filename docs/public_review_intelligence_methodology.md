# Public Review Intelligence methodology (PRI v1)

Public Review Intelligence is a separate TechSelectAI signal. It does not alter recommendation ranking, Fit Score, Evidence Confidence, or TechSelectAI Verified Review Score.

## Source eligibility
Only sources explicitly marked `permitted` may contribute to PRI. `pending_review`, `restricted`, and `blocked` sources are excluded. AI must not be used to bypass robots, authentication, licensing, API restrictions, contractual terms, or reuse limitations. Restricted review platforms such as G2 or Capterra must not be ingested unless the intended use is explicitly permitted by their terms/API/licence.

## Derived data only
The system stores derived signals such as sentiment, topics, public rating when legitimately available, reviewer context when public, source confidence and fingerprints. It should not republish long copyrighted review text.

## Score
Each usable signal provides a normalized sentiment from -1 to +1. The final 0-5 score is deterministic:

`score_5 = ((weighted_mean_sentiment + 1) / 2) * 5`

Signal weight is:

`source_confidence × recency_weight`

Recency uses a 365-day half-life and a floor of 0.35 so older implementation experience can still contribute. Missing/invalid dates use a neutral 0.70 recency factor.

## Minimum data
A public score is not shown unless there are at least 5 usable signals across at least 2 independent source types. Duplicate- or spam-suspected signals are excluded.

## Confidence
Confidence is separate from the 0-5 score. PRI v1 combines:
- average source confidence: 35%
- usable signal volume with diminishing returns: 25%
- source-type diversity: 25%
- sentiment consistency: 15%

Labels:
- High: >= 0.80
- Medium: >= 0.60
- Low: < 0.60
- Insufficient: minimum data threshold not met

A mixed set of positive and negative feedback can still produce a valid score; disagreement mainly lowers confidence rather than forcing the score toward a predetermined value.

## Positive sentiment
Positive sentiment percentage is the weighted share of usable signals whose sentiment is above +0.15.

## Governance
Every displayed PRI result should expose methodology version, source count, source-type diversity, confidence label, and last analyzed date. Strengths and concerns should be summaries of recurring themes, not copied review passages.

AI may extract and normalize sentiment/topics from permitted public material, but the final PRI score and confidence are calculated deterministically in PHP.