# Sprint 1.4 — AI Consultation Contract

## Goal
Turn natural-language business needs into structured, user-confirmed consultation data without allowing the model to invent product facts, pricing, compliance, or rankings.

## Core flow
1. User describes the business problem in free text.
2. AI extracts only structured consultation fields.
3. Extraction is stored as provisional data with confidence.
4. High-risk or ambiguous fields require confirmation.
5. Missing critical information generates focused follow-up questions.
6. Accepted fields are written to canonical consultation tables.
7. `refresh_consultation_ai_state()` determines whether the case is ready for matching.
8. Only the deterministic matching engine creates product scores/ranks.
9. AI explains the persisted recommendation and gaps using database facts/evidence.

## Required extraction JSON contract
The model must return a JSON object with this shape:

```json
{
  "category_slug": "corporate-identity-digital-business-cards",
  "company": {
    "country_code": "SA",
    "employee_count_min": 500,
    "employee_count_max": 500,
    "expected_software_users": 500
  },
  "requirements": [
    {
      "capability_slug": "entra-id-integration",
      "priority": "must_have",
      "is_mandatory": true,
      "source_text": "We need Microsoft Entra integration",
      "confidence": 0.98
    }
  ],
  "integrations": [],
  "deployment_preferences": [],
  "compliance": [],
  "languages": [],
  "budget": {
    "min": null,
    "max": 6,
    "currency": "USD",
    "period": "per_user_month"
  },
  "implementation_timeline": null,
  "uncertainties": []
}
```

The model must use known database slugs supplied by the application. It must not invent capability, category, integration, compliance, deployment, country, or language identifiers.

## Confirmation rules
Always confirm when:
- confidence is below 0.80;
- AI inferred a must-have requirement not explicitly stated;
- budget units/currency are ambiguous;
- deployment restriction could exclude most products;
- compliance requirement is inferred rather than explicitly stated;
- user wording could map to multiple capabilities.

Confirmation is optional when:
- country, company size, or requested user count is stated explicitly;
- capability wording maps unambiguously to one known capability;
- user explicitly says required / mandatory / must have / cannot accept.

## Follow-up question policy
Ask only questions that can materially change the recommendation.

Priority order:
1. Business problem / category if unresolved.
2. Mandatory functional requirements.
3. Deployment restrictions.
4. Required integrations.
5. Security/compliance constraints.
6. Geography/language constraints.
7. Budget.
8. Timeline.

Do not interrogate the user for every optional field. A useful consultation should remain possible with partial data, but unknown data must remain unknown.

## AI boundaries
The model may:
- classify intent;
- extract structured requirements;
- normalize natural language;
- generate concise follow-up questions;
- summarize confirmed requirements;
- explain recommendation output;
- explain verified gaps and evidence.

The model must not:
- create product scores;
- choose winners independently of the matching engine;
- convert `unknown` into `not_supported`;
- invent pricing, integrations, security certifications, deployment options, or capabilities;
- hide mandatory gaps;
- favor CardIQ or a sponsored vendor;
- overwrite verified product facts.

## Chat state
Recommended conversational states:

`collecting_context` → `clarifying` → `requirements_review` → `ready_for_matching` → `recommendation_ready` → `explaining_results`

The database remains authoritative for consultation status. Chat state is orchestration metadata only.

## Example
User:
> We are a logistics company in Saudi Arabia with 600 employees. We want to control employee digital identities. Microsoft Entra is important and we need Arabic. Budget is around $5 per user monthly.

AI should extract company/country/size/budget, map the likely category, identify Entra and Arabic requirements, and ask only genuinely unresolved questions such as whether Entra is mandatory and whether SaaS deployment is acceptable.

Once requirements are confirmed, the application calls the deterministic matching function. If CardIQ has a verified gap against a must-have requirement, the AI must state it clearly even if CardIQ otherwise scores highly.

## API boundary for the next sprint
The future application service should expose operations equivalent to:
- start consultation;
- append user message;
- run extraction;
- accept/reject extracted fields;
- fetch next follow-up question;
- review structured requirements;
- run deterministic matching;
- retrieve recommendation report;
- append AI explanation.

No HTTP framework is selected in this sprint.
