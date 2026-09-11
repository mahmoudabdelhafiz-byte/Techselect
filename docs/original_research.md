# TechSelectAI Original Research

Issue: #179

## First report format

`/research/software-evidence-benchmark`

The Software Evidence Coverage Benchmark is generated only from TechSelectAI-owned catalog/evidence records. It measures catalog evidence coverage and verification/freshness signals; it is not a vendor quality score, market-share estimate or third-party review score.

## Reproducibility

1. Apply migration `055_original_research.sql`.
2. Run `php scripts/generate_original_research.php` to create/publish the current dated snapshot.
3. Use `--draft` to generate without publication.
4. A same-day rerun replaces that report/date snapshot deterministically.

Every published snapshot records:
- snapshot date
- methodology version
- active product count
- category count
- evidence-source count
- source-data freshness date
- category-level metrics

## Public citation assets

- HTML report: `/research/software-evidence-benchmark`
- CSV: `/research/software-evidence-benchmark.csv`
- SVG chart: `/research/software-evidence-benchmark.svg`

The HTML report includes Dataset structured data and a suggested citation. The SVG is intended for legitimate editorial embedding with source attribution.

## Authority workflow

External mentions/backlinks to the research page should be tracked in the existing External Authority dashboard (`/authority-admin`). AI retrieval visibility remains measurable through `/ai-visibility`.

## Scope safeguards

- No G2/Capterra or other third-party marketplace ratings are copied into original statistics.
- Unknown capability evidence remains unknown, not unsupported.
- Evidence coverage is a data-quality statistic, not a product ranking.
- Publication is based on a stored snapshot so cited figures remain reproducible for the stated snapshot date.
