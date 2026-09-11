# TechSelectAI Community Intelligence Source Policy

## Purpose
TechSelectAI Community Intelligence summarizes derived patterns from permitted public software discussions. It does not republish review bodies and it remains separate from buyer Fit Score, first-party Verified Reviews, and factual Evidence Confidence.

## Permitted-by-review sources
A source must be explicitly reviewed and set to `permitted` before analysis. Suitable source types may include public forums, Reddit discussions, vendor communities, public app/community threads, Stack Exchange-style discussions, independent implementation blogs, and other openly accessible sources where the collection/use method complies with applicable terms, robots/API requirements, rate limits and copyright restrictions.

## Explicitly excluded by default
G2 and Capterra review content/ratings are not ingested by the default pipeline. They may only be enabled later under an explicit license, API agreement, or other documented permission. AI must not be used to bypass access or reuse restrictions.

## Stored data
TechSelectAI stores source attribution and derived signals such as sentiment, concise themes, reviewer context where public, quality/confidence values, source URL/type, publication/retrieval dates, content fingerprint, and analysis version. Long copied review text is not retained as the community intelligence record.

## Quality filtering
Signals can be excluded when duplicate, spam, affiliate/promotional, vendor-promotional, bot-like, low-signal, insufficiently specific, or low-confidence. Excluded signals remain traceable for governance but do not contribute to product-level intelligence.

## Derived themes
The v2 pipeline extracts strengths, weaknesses, implementation experience, support, pricing/value, integrations, reliability, usability, best-fit contexts, and poor-fit contexts.

## Independence
Community Intelligence is an input signal for research and later evaluation workflows. It does not automatically change a published TechSelectAI Product Evaluation or buyer-specific recommendation. Human-controlled evaluation publication is handled separately.
