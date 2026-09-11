SET NAMES utf8mb4;
START TRANSACTION;

ALTER TABLE authority_sources
  ADD COLUMN submission_url VARCHAR(1024) NULL AFTER source_url,
  ADD COLUMN route_source_url VARCHAR(1024) NULL AFTER submission_url,
  ADD COLUMN prerequisites TEXT NULL AFTER intended_context,
  ADD COLUMN required_assets TEXT NULL AFTER prerequisites,
  ADD COLUMN readiness_status VARCHAR(30) NOT NULL DEFAULT 'researching' AFTER required_assets,
  ADD COLUMN route_verified_at DATETIME NULL AFTER readiness_status,
  ADD KEY idx_authority_readiness (readiness_status);

-- Execution readiness only. No row below is submitted, accepted, published or an acquired backlink.
UPDATE authority_sources SET
  submission_url='https://www.producthunt.com/posts/new',
  route_source_url='https://help.producthunt.com/en/articles/479557-how-to-post-a-product',
  prerequisites='Personal Product Hunt account; complete account onboarding; product must meet Product Hunt community guidelines.',
  required_assets='Primary product URL; product name; description; maker account; launch media/gallery assets; first comment; optional promo and social link.',
  readiness_status='ready',
  route_verified_at='2026-09-11 00:00:00',
  next_action='Prepare Product Hunt draft and validate TechSelectAI launch positioning; do not request upvotes.'
WHERE domain='producthunt.com' AND source_type='company_profile';

UPDATE authority_sources SET
  submission_url='https://www.crunchbase.com/add-new',
  route_source_url='https://support.crunchbase.com/hc/en-us/articles/115011823988-How-do-I-create-a-Crunchbase-profile',
  prerequisites='Registered Crunchbase user with social authentication; check first that no TechSelectAI profile already exists.',
  required_assets='Company logo; founded date; website and social links; short and long description; headquarters; industries; founders where applicable.',
  readiness_status='ready',
  route_verified_at='2026-09-11 00:00:00',
  next_action='Search Crunchbase for an existing TechSelectAI profile; create or claim only with factual company information.'
WHERE domain='crunchbase.com' AND source_type='company_profile';

UPDATE authority_sources SET
  submission_url='https://www.startupblink.com/organizations/add',
  route_source_url='https://www.startupblink.com/organizations/add',
  prerequisites='Submit as an official organization representative; website required; email-domain verification may be requested.',
  required_assets='Organization name; website; city; 30-350 character organization description; optional logo and social/video links.',
  readiness_status='ready',
  route_verified_at='2026-09-11 00:00:00',
  next_action='Confirm organization classification, then submit TechSelectAI as an organization for review with factual regional positioning.'
WHERE domain='startupblink.com' AND source_type='company_profile';

UPDATE authority_sources SET
  submission_url='https://www.linkedin.com/company/setup/new/',
  route_source_url='https://www.linkedin.com/help/billing/answer/a543852',
  prerequisites='Real personal LinkedIn profile; confirmed email; more than one connection; confirm no existing page; workplace verification may be required.',
  required_assets='Company name; public LinkedIn URL; website; industry; company size; company type; tagline; logo; cover image; company description.',
  readiness_status='ready',
  route_verified_at='2026-09-11 00:00:00',
  next_action='Check whether an official TechSelectAI Page already exists; create or claim it and complete all profile sections.'
WHERE domain='linkedin.com' AND source_type='company_profile';

UPDATE authority_sources SET
  submission_url='https://www.g2.com/products/new',
  route_source_url='https://documentation.g2.com/help/docs/finding-or-listing-a-product-on-g2',
  prerequisites='G2 accepts eligible B2B software products; research team verifies eligibility and categorization; TechSelectAI advisory-platform eligibility is not assumed.',
  required_assets='Product name; website; category justification; factual product description; vendor ownership details if approved.',
  readiness_status='eligibility_check',
  route_verified_at='2026-09-11 00:00:00',
  next_action='Confirm with G2 whether TechSelectAI qualifies as a B2B software/advisory product before submitting.'
WHERE domain='g2.com' AND source_type='directory';

UPDATE authority_sources SET
  submission_url='https://www.capterra.com/vendors/',
  route_source_url='https://www.capterra.com/vendors/',
  prerequisites='Capterra vendor listing is designed for software products; TechSelectAI category eligibility must be confirmed before listing.',
  required_assets='Software/product description; website; vendor/company details; category selection; branding assets if eligibility is approved.',
  readiness_status='eligibility_check',
  route_verified_at='2026-09-11 00:00:00',
  next_action='Confirm whether TechSelectAI qualifies for a Capterra software category before creating a vendor listing.'
WHERE domain='capterra.com' AND source_type='directory';

UPDATE authority_sources SET
  submission_url='https://alternativeto.net/manage-item/',
  route_source_url='https://alternativeto.net/faq/',
  prerequisites='Verified AlternativeTo account email; application must fit the service taxonomy and will enter moderation review.',
  required_assets='Application name; platforms; license; description; tags; official website and supporting factual details.',
  readiness_status='eligibility_check',
  route_verified_at='2026-09-11 00:00:00',
  next_action='Confirm TechSelectAI fits AlternativeTo application criteria, then use Suggest new application if appropriate.'
WHERE domain='alternativeto.net' AND source_type='directory';

UPDATE authority_sources SET
  submission_url='https://www.saashub.com/services/submit',
  route_source_url='https://www.saashub.com/services/submit',
  prerequisites='Released English-language product/service with its own domain; all submissions are reviewed; domain-email verification improves priority.',
  required_assets='Website URL; relevant categories; competitors/alternatives; product description; domain email for verification if available.',
  readiness_status='eligibility_check',
  route_verified_at='2026-09-11 00:00:00',
  next_action='Confirm TechSelectAI qualifies as a software/service listing before submission; do not force-fit into a SaaS category.'
WHERE domain='saashub.com' AND source_type='directory';

UPDATE authority_sources SET
  submission_url='mailto:editor@wamda.com',
  route_source_url='https://www.wamda.com/faq',
  prerequisites='Editorial contribution should be relevant to the startup ecosystem; send a short brief stating the arguments; opinion pieces are generally 800-1000 words.',
  required_assets='Short pitch brief; author bio; proposed article angle; evidence-backed MENA software-buying or AI-assisted procurement topic; full draft only when requested.',
  readiness_status='ready',
  route_verified_at='2026-09-11 00:00:00',
  next_action='Prepare a concise editorial pitch to Wamda on evidence-backed enterprise software buying in MENA; do not ask for a backlink.'
WHERE domain='wamda.com' AND source_type='industry_publication';

-- Precise current execution routes were not sufficiently verified in this phase.
UPDATE authority_sources SET readiness_status='researching',route_verified_at=NULL
WHERE (domain='f6s.com' AND source_type='company_profile')
   OR (domain='magnitt.com' AND source_type='company_profile')
   OR (domain='entrepreneur.com' AND source_type='industry_publication');

-- Safety invariant for this phase: execution metadata must never imply acquisition.
UPDATE authority_sources
SET outreach_status=CASE WHEN outreach_status IN ('published','accepted','contacted','follow_up') THEN 'researching' ELSE outreach_status END,
    backlink_status='not_published',
    published_url=NULL,
    first_verified_at=NULL
WHERE domain IN ('producthunt.com','crunchbase.com','f6s.com','startupblink.com','magnitt.com','linkedin.com','g2.com','capterra.com','alternativeto.net','saashub.com','wamda.com','entrepreneur.com');

COMMIT;
