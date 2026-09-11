# External authority and backlink playbook

This playbook supports issue #139. It is an operating guide, not evidence that any external profile, article, mention or backlink already exists.

## Principles

1. Prioritize relevance and editorial legitimacy over backlink volume.
2. Never buy ranking links, use link farms, fabricate reviews/citations, or imply endorsements that were not approved.
3. Partner, customer and vendor mentions require explicit approval before being marked published/active.
4. Link to the most relevant TechSelectAI asset rather than forcing every reference to the homepage.
5. Use natural anchor text. Do not require exact-match keyword anchors.
6. Record a backlink as `active` only after a published URL has been checked.

## Priority source groups

### Tier A — highest relevance
- Established software/technology industry publications
- Recognized business technology publications in Egypt, Saudi Arabia and UAE
- Approved customer or partner websites with a legitimate TechSelectAI relationship
- Vendor ecosystem/resource pages where TechSelectAI is genuinely relevant
- Professional associations, accelerators and technology communities with editorial standards

### Tier B — useful profiles and discovery
- Reputable company/startup databases
- Business directories with manual moderation
- Founder/company profiles on established professional networks
- Conference, event and speaker profile pages
- Relevant podcast/newsletter guest pages

### Tier C — selective only
- Niche directories or communities with real human readership
- Curated resource pages with clear editorial ownership

Avoid bulk SEO directories, article farms, automated reciprocal-link networks and low-quality guest-post marketplaces.

## Preferred TechSelectAI link targets

- General factual description: `/about-techselectai`
- Independence/ownership: `/trust`
- Scoring explanation: `/methodology`
- Product evidence: `/software/{slug}`
- Category decision support: `/categories/{slug}`
- Product comparison: `/compare/{a}-vs-{b}`
- High-intent educational content: `/guides/{slug}`
- Verified real-world proof: `/case-studies/{slug}`

## Tracking convention

For outreach-controlled links, use UTM tags so first-party referral measurement works even when browser referrer information is limited.

Recommended pattern:

`https://techselectai.com/<asset>?utm_source=<domain>&utm_medium=referral&utm_campaign=authority_<initiative>`

Examples of campaign names:
- `authority_partner_profile`
- `authority_customer_case_study`
- `authority_directory_profile`
- `authority_guest_article`
- `authority_event_speaker`

Do not put customer names, email addresses, private deal data or other sensitive information in UTM parameters.

## Workflow

1. Add the target to `/authority-admin` as a prospect.
2. Record why the source is relevant and the intended TechSelectAI asset.
3. Confirm approval requirements for partner/customer/vendor mentions.
4. Contact the source manually with factual, non-spammy copy.
5. When published, save the exact published URL.
6. Verify the link before setting backlink status to `active`.
7. Review `/authority-analytics` for tagged referral activity.
8. Recheck active backlinks periodically; mark lost/removed links accurately.

## Recommended outreach value propositions

Offer useful evidence or expertise rather than asking only for a backlink. Examples:
- Data-backed software selection commentary
- Neutral explanation of software evaluation methodology
- Regional buyer guides for Egypt/KSA/UAE
- Expert quotes on enterprise software buying, implementation risk or AI-assisted procurement
- Co-authored educational content with a legitimate partner
- Approved customer outcome/case-study material

## Measurement

Track:
- relevant domains researched
- outreach contacted/follow-up
- approved published references
- verified active/lost backlinks
- UTM-tagged referral sessions
- resulting consultations where measurable
- AI referral traffic separately through the existing AI referral analytics

Backlink count alone is not a success metric. Relevance, legitimacy, referral quality and discoverability matter more.
