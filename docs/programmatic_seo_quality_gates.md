# Programmatic SEO quality gates

TechSelectAI favors fewer high-value pages over large volumes of thin keyword permutations.

## Decisions

Every generated SEO page must exist in `seo_generated_pages` and receive one explicit gate decision before publication:

- `indexable` — may be published with `index,follow` and may enter the XML sitemap.
- `published_noindex` — may remain accessible for users/internal navigation but must render `noindex,follow` and is excluded from the sitemap.
- `not_generated` — content is below the minimum publication threshold and should not be exposed as a generated landing page.

A renderer for any generated page family must call `ProgrammaticSeoQualityGate::robotsFor()` and honor `canonical_target_path` when present. The sitemap independently enforces `status='published' AND quality_decision='indexable'` as a second safety boundary.

## Default indexable thresholds

Defaults are stored in `seo_quality_gate_settings` and can be adjusted without changing the evaluator:

- body text: at least 1,400 characters
- evidence items: at least 3
- independent/traceable sources: at least 2
- internal links: at least 2
- recommendation rationale: at least 250 characters
- content freshness: reviewed within 180 days
- sensible title, H1 and meta-description lengths
- no overlapping normalized intent with an existing page
- no near-duplicate body content above the configured Jaccard threshold (default 0.82)

The lower publication floor is 800 body characters and 2 evidence items. Falling below that floor produces `not_generated`; failing only indexability criteria produces `published_noindex`.

## Duplicate and canonical handling

The evaluator compares normalized intent, evidence fingerprint and token overlap against existing generated pages. When a stronger existing page already serves the same intent, the weaker page becomes `published_noindex` and receives `canonical_target_path` pointing to the existing page. Trivial variants such as only changing employee-count wording should share an intent key and therefore consolidate rather than multiplying indexable URLs.

## Required page inputs

Generated-page builders should populate: page type, slug/canonical path, intent key, title, H1, meta description, substantive body text, recommendation rationale, evidence count, source count, stable evidence fingerprint, internal-link count and last-reviewed date.

## Admin workflow

`/seo-quality-gates` lists every generated page, its decision, score, failure reasons and canonical target. Reviewers can rerun one page or all active pages after evidence/content changes. Gate runs are immutable in `seo_quality_gate_runs` and reviewer-triggered runs are audit logged.

## Boundary with editorial content

Curated editorial guides are not automatically treated as programmatic pages. #183 long-tail generated landing pages and future generated page families must use this registry and gate before becoming indexable.