# Sprint 1.2 — Technology Knowledge Graph

## Goal

Provide TechSelect AI with a structured, evidence-backed catalog that can be queried by the future recommendation engine without relying on LLM memory or guesses.

## Scope

The schema supports:

- vendors and products
- multiple product categories and modules
- editions/plans
- pricing models and billing periods
- deployment models
- integrations
- countries and regional support
- languages
- industries
- compliance frameworks
- capability support facts
- explicit unknown / not-yet-verified states
- multiple evidence sources per capability fact
- confidence and verification freshness
- verification history and dispute/staleness states

## Core rule

Unknown information is not equivalent to unsupported information.

The recommendation engine must preserve the distinction between:

- supported
- partially supported
- add-on
- third-party integration
- enterprise only
- plan dependent
- custom configuration
- not supported
- unknown
- not yet verified

## Evidence rule

Capability claims should be grounded in one or more evidence sources where available. Evidence can be vendor documentation, pricing/security/product documentation, vendor submissions, independent verification, partner documentation, or another explicitly classified source.

## Definition of Done

Sprint 1.2 is complete when the database can represent one real product end-to-end, including vendor, categories, modules, plans, pricing, deployment, integrations, supported regions/languages/industries, compliance, capability statuses, and evidence; and when a query can determine whether a structured requirement is supported, unsupported, conditional, or unknown.

## Next sprint

Sprint 1.3 should seed a small, curated product set and implement the first deterministic matching service against consultation requirements.
