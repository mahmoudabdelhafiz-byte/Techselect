# Catalog Evidence Parity Audit

TechSelectAI treats evidence completeness as a governance concern separate from product ranking.

The parity audit compares active products only with peers in the same software category. It is identity-blind: there is no house-product, vendor, sponsor, or commercial exception. A product with stronger evidence is never penalized and the audit does not modify Fit Score or recommendation rank.

## Metrics

The v1 composite uses:

- 40% verified capability coverage
- 25% verified capability-to-evidence linkage
- 15% freshness of verified capability facts (365-day window)
- 10% verified mobile-platform coverage
- 10% permitted public-source diversity, capped at three source types

`unknown` and `not_yet_verified` remain distinct from `not_supported` and do not count as verified evidence.

## Category-relative flags

For categories with at least three active products, the audit compares each product with the category median and strongest peer. It raises `watch` or `critical` evidence-remediation flags when coverage is materially below peers. These flags are research backlog signals only; they cannot increase or decrease recommendation scores.

The runtime report is:

```bash
php scripts/catalog_evidence_parity_report.php
```

To use the audit as an operational release gate after production data has been synchronized:

```bash
php scripts/catalog_evidence_parity_report.php --fail-on-critical
```

GitHub CI runs a static contract that ensures the parity engine remains category-relative, identity-blind, conservative about unknown facts, and independent from recommendation scoring.
