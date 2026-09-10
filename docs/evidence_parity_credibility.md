# Evidence parity and recommendation credibility

TechSelectAI deliberately treats missing product capability facts as `not_yet_verified`, not `not_supported`. This protects products from being penalized for research gaps, but sparse products can naturally cluster around similar fit scores because unknown support receives the same conservative partial-credit treatment.

To keep that behavior transparent:

- recommendation responses expose `known_fact_count`, `recorded_fact_count`, `unknown_requirement_count`, `requirement_count`, `evidence_coverage`, and `recorded_coverage`;
- recommendation cards display known evidence coverage for the buyer's requested criteria;
- low-coverage products show an explicit warning that unknown does not mean unsupported;
- products materially less researched than the best-covered option in the same recommendation set receive an asymmetry warning;
- catalog quality auditing measures the full active-product × active-capability matrix, not only rows already present in `product_capabilities`;
- evidence parity should be improved by enriching competitor facts and sources, not by changing deterministic scoring to force different scores.

Current guardrail thresholds:

- High known-evidence coverage: >= 80%
- Moderate: >= 60% and < 80%
- Limited: < 60%
- Material coverage asymmetry warning: >= 25 percentage points below the best-covered product in the recommendation set

These thresholds affect transparency only. They do not alter Fit Score or ranking.
