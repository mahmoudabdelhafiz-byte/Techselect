# AI-friendly factual summaries

TechSelectAI public software and comparison pages expose a concise, visible factual summary generated only from recorded product data. The summary is intended for both human readers and retrieval systems; there is no crawler-only variant.

Software summaries may include recorded category, supported/conditional/unknown/not-supported capability counts, integration/deployment counts, known-fact confidence, and latest recorded review or verification date. Comparison summaries describe both products neutrally using the same recorded fields.

These summaries are not recommendation scores. They remain separate from buyer-specific Fit Score, Evidence Confidence, TechSelectAI Verified Reviews, and Public Review Intelligence. Unknown / Not Yet Verified is explicitly distinct from Not Supported.

The wrapper also emits JSON-LD TechArticle metadata that points to the existing canonical public URL and SoftwareApplication entities. Missing optional data is omitted rather than invented.
