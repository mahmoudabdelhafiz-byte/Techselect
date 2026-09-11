# AI Visibility Benchmark

TechSelectAI measures whether major AI/search assistants mention or cite TechSelectAI for representative software-buying questions.

## Benchmark set
Migration `053_ai_visibility_benchmark.sql` seeds 50 prompts across category discovery, comparisons, alternatives, company-size/industry/use-case fit, regional requirements, security, integration and deployment questions.

## Observation policy
Each provider observation stores provider, model/version, answer date, prompt, mention/citation flags, cited TechSelectAI URL, source position when observable, other cited sources, response reference and notes.

Observation status is one of:
- `valid`: included in benchmark rates.
- `ambiguous`: retained for audit/troubleshooting but excluded from rates.
- `failed`: retained but excluded from rates.

Runs may be manual, semi-automated, imported, or automated only where the relevant provider workflow/API and terms permit it. The implementation does not bypass provider access controls or assume browser automation is permitted.

## Dashboard
`/ai-visibility` reports mention rate, citation rate, unique TechSelectAI pages cited, competitor/source overlap, provider/query-type/category performance, cited page types, monthly trends, month-over-month rate changes and uncited prompt gaps.

The existing `/ai-referrals` analytics remains a separate inbound-referral signal; it is not treated as a substitute for benchmark observations.

## Import format
POST `/api/ai-visibility/import` with a provider, optional model/run metadata and an `observations` array keyed by seeded `prompt_key`. Failed/ambiguous observations should not be coerced into negative visibility results.
