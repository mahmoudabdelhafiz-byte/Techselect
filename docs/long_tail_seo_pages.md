# TechSelectAI long-tail SEO pages

This module creates evidence-backed buyer-intent landing pages without mass-producing keyword permutations.

## Controlled templates

- `category_for_industry` — best [category] for [industry]
- `category_for_company_size` — best [category] for [company size]
- `category_for_use_case` — best [category] for [use case]
- `category_with_requirement` — best [category] with [requirement]
- `comparison_for_context` — [product A] vs [product B] for [context]
- `alternatives_for_context` — [product] alternatives for [context]

Public URLs use the stable `/software-selection/{slug}` family so intent variants do not create multiple route families.

## Evidence rules

Generation uses only active products with a published TechSelectAI Product Evaluation under a published methodology. Category pages require at least two evaluated products. Comparison pages require a published evaluation for both products. Alternatives pages require a published evaluation for the primary product and at least one evaluated alternative in the same category.

The page does not invent a buyer-specific Fit Score from the context phrase. Context frames the buyer question; product evaluation and buyer Fit Score remain separate analytical layers.

## Publication flow

1. Reviewer/admin chooses one controlled template and context.
2. `LongTailSeoGenerator` builds the page from published evaluation data and linked evidence.
3. The page is registered in `seo_generated_pages` and `seo_long_tail_pages`.
4. #184 `ProgrammaticSeoQualityGate` runs automatically.
5. `indexable` and `published_noindex` pages may render publicly; `not_generated` remains non-public.
6. Only `published + indexable` generated pages enter `sitemap.xml`.
7. Relevant software/category/comparison pages link only to long-tail pages that are `published + indexable`.

## Measurement

All pages are under `/software-selection/`, so Search Console performance can be segmented by page URL prefix. This lets #181 report impressions, clicks, CTR, position, quick wins and declining visibility for the generated family independently from normal software pages.

## Anti-doorway rule

Do not generate trivial variants that differ only by wording or a nearby employee-count number. #184 checks normalized intent, evidence fingerprints and body similarity; overlapping weaker pages become `noindex`/canonicalized or blocked.
