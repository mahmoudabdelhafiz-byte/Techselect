# Research-led Authority Outreach Campaigns

Issue: #139

This phase adds an execution layer on top of the existing Authority & Backlinks registry. It does not manufacture external authority and does not close #139 by itself; the parent issue remains open until genuine independent external references/backlinks are obtained and measured.

## Workspace

`/authority-campaigns`

The campaign workspace is designed to promote truthful TechSelectAI assets such as `/research/software-evidence-benchmark` to relevant publications, partners, vendors, customers, directories and thought-leadership channels already governed by the Authority registry.

## Priority model

Targets receive a deterministic 0–100 priority score based on:
- authority tier
- relevance score
- readiness state
- source type
- whether an active backlink already exists

The score prioritizes outreach work only. It must never affect product evaluation, Fit Score, ranking or editorial conclusions.

## Event history

Campaign targets record actual operational events such as contacted, follow-up, reply, accepted, declined, published, backlink verified and backlink lost. This is an audit trail, not an email-sending system.

A backlink cannot be marked verified unless an external published URL exists. Approval-required customer/vendor/partner mentions cannot be verified until their existing authority-source approval gate is satisfied.

## Scope safeguards

- No paid-link or link-farm workflow.
- No fake reviews or fabricated citations.
- No reciprocal-link scoring incentive.
- No ranking benefit for vendors or partners that link to TechSelectAI.
- Authority outcomes stay operationally separate from software evaluation methodology.

## Deployment

1. Apply `db/mysql/056_authority_outreach_campaigns.sql`.
2. Open `/authority-campaigns` from an authorized reviewer/admin account.
3. Create a campaign and add existing governed authority sources.
4. Record outreach and real external outcomes as they occur.
5. Use the existing authority analytics/referral tooling to measure resulting referring domains and traffic.

Static contract: `php scripts/authority_campaigns_check.php`.
