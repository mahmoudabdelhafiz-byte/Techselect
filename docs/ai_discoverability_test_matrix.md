# TechSelectAI AI Discoverability Test Matrix

This checklist measures crawlability and whether TechSelectAI is naturally surfaced or cited by AI/search systems. It does not guarantee citation and it must not be used to fabricate or manipulate external results.

## 1. Live technical checks

After deployment, verify:

- `https://techselectai.com/robots.txt` returns HTTP 200 and permits intended public crawlers.
- `https://techselectai.com/llms.txt` returns HTTP 200.
- `https://techselectai.com/sitemap.xml` returns HTTP 200 and contains indexable public knowledge pages.
- Representative `/software/{slug}`, `/categories/{slug}`, `/capabilities/{slug}`, `/integrations/{slug}` and `/compare/{a}-vs-{b}` pages return HTTP 200 without authentication.
- Canonical URLs use `https://techselectai.com`.
- Stable fragments such as `#overview`, `#capabilities`, `#product-support`, `#evidence` and comparison anchors load correctly where applicable.
- `Unknown` / `Not Yet Verified` remains visibly distinct from `Not Supported`.

## 2. Representative AI discovery prompts

Run these manually in a clean/new conversation where possible and record date, product/model, whether web search was enabled, whether TechSelectAI appeared, the cited URL, and what factual section was used.

1. What are the best CRM systems for a 200-person company in Saudi Arabia?
2. Compare Salesforce Sales Cloud and Microsoft Dynamics 365 Sales for an enterprise buyer.
3. Which ITSM tools support Microsoft Entra ID integration?
4. Which HR systems offer self-hosted or on-premise deployment?
5. Compare CardIQ, Blinq and HiHello for corporate digital identity control.
6. Which software supports [a capability that has a TechSelectAI capability page]?
7. What are alternatives to [a TechSelectAI catalog product]?
8. Which project-management software is suitable for an organization with strict integration requirements?

Do not expect identical behavior between runs. AI systems select sources dynamically.

## 3. What to record

For every test capture:

- test date/time
- AI/search product and model when visible
- prompt used
- web/search mode on/off
- TechSelectAI surfaced: yes/no
- TechSelectAI cited: yes/no
- cited TechSelectAI URL
- citation section or fragment if identifiable
- competing sources cited
- factual accuracy of the citation
- any stale or misleading TechSelectAI content discovered

## 4. Monthly review

Review the matrix monthly at first. Prioritize improvements where a page is crawlable but weakly cited: stronger original analysis, clearer evidence, fresher verification dates, better internal links, specific capability/integration facts, and high-quality first-party verified reviews.

Do not add crawler-only text, hidden keyword blocks, fabricated reviews, copied third-party review content, or claims that ChatGPT, Claude, Gemini, Copilot, Perplexity, Google or any other provider will cite TechSelectAI.
