SET NAMES utf8mb4;
START TRANSACTION;

-- Research/prospect seeds only. These rows do NOT assert that TechSelectAI is listed,
-- mentioned, endorsed, or linked by any external source.
SET @authority_seed_actor := (
  SELECT id FROM users
  WHERE role IN ('super_admin','admin')
  ORDER BY CASE role WHEN 'super_admin' THEN 0 ELSE 1 END,id
  LIMIT 1
);

INSERT INTO authority_sources
(source_name,domain,source_url,source_type,geography_code,relevance_score,authority_tier,outreach_status,next_action,techselect_asset_path,intended_context,mention_requires_approval,mention_approved,published_url,link_type,backlink_status,first_verified_at,last_checked_at,notes,created_by,updated_by)
SELECT s.source_name,s.domain,s.source_url,s.source_type,s.geography_code,s.relevance_score,s.authority_tier,'researching',s.next_action,s.techselect_asset_path,s.intended_context,0,0,NULL,NULL,'not_published',NULL,NULL,s.notes,@authority_seed_actor,@authority_seed_actor
FROM (
  SELECT 'Product Hunt' source_name,'producthunt.com' domain,'https://www.producthunt.com/' source_url,'company_profile' source_type,'GLOBAL' geography_code,5 relevance_score,'high' authority_tier,'Check launch/profile eligibility and prepare factual product positioning' next_action,'/about-techselectai' techselect_asset_path,'Technology discovery profile/launch; do not claim launch until published' intended_context,'Strong technology discovery channel; profile/launch eligibility must be confirmed before outreach.' notes
  UNION ALL SELECT 'Crunchbase','crunchbase.com','https://www.crunchbase.com/','company_profile','GLOBAL',5,'high','Check company-profile creation/claim process and required business evidence','/about-techselectai','Factual company profile and ownership context','Company-discovery target; create or claim only with accurate public company information.'
  UNION ALL SELECT 'F6S','f6s.com','https://www.f6s.com/','company_profile','GLOBAL',4,'medium','Check company/profile eligibility and relevant startup ecosystem programs','/about-techselectai','Company/startup ecosystem profile','Research eligibility before creating any profile or applying to programs.'
  UNION ALL SELECT 'StartupBlink','startupblink.com','https://www.startupblink.com/','company_profile','MENA',4,'medium','Check startup/company listing eligibility for Egypt and MENA visibility','/about-techselectai','Regional startup ecosystem visibility','Research-only target; no listing or ranking claim is implied.'
  UNION ALL SELECT 'MAGNiTT','magnitt.com','https://magnitt.com/','company_profile','MENA',5,'high','Check company/startup profile eligibility and MENA discovery options','/about-techselectai','MENA technology/startup company profile','High regional relevance; verify eligibility and any commercial terms before proceeding.'
  UNION ALL SELECT 'LinkedIn Company Page','linkedin.com','https://www.linkedin.com/','company_profile','GLOBAL',5,'high','Create or optimize official TechSelectAI company presence with canonical links','/about-techselectai','Official factual company profile','Use only official TechSelectAI/Barmageyat facts; no fabricated endorsements or customer claims.'
  UNION ALL SELECT 'G2','g2.com','https://www.g2.com/','directory','GLOBAL',5,'high','Check whether TechSelectAI qualifies for a software/advisory category before any listing request','/about-techselectai','Eligibility research for software discovery','TechSelectAI is an advisory platform, so category eligibility must be confirmed rather than assumed.'
  UNION ALL SELECT 'Capterra','capterra.com','https://www.capterra.com/','directory','GLOBAL',5,'high','Check product/category eligibility and provider listing requirements','/about-techselectai','Eligibility research for software discovery','Do not create a misleading software-vendor listing if the platform does not meet current eligibility rules.'
  UNION ALL SELECT 'AlternativeTo','alternativeto.net','https://alternativeto.net/','directory','GLOBAL',4,'medium','Check whether TechSelectAI is eligible as a technology advisory/discovery product','/about-techselectai','Technology discovery listing research','Eligibility must be validated; no listing is asserted by this seed.'
  UNION ALL SELECT 'SaaSHub','saashub.com','https://www.saashub.com/','directory','GLOBAL',4,'medium','Check software-directory eligibility and appropriate category','/about-techselectai','Software discovery listing research','Research-only target; do not force-fit TechSelectAI into an inaccurate SaaS category.'
  UNION ALL SELECT 'Wamda','wamda.com','https://www.wamda.com/','industry_publication','MENA',5,'high','Research editorial/contact route for evidence-backed MENA software-buying commentary','/methodology','Thought leadership on software selection, AI-assisted procurement and MENA buyer needs','Pitch useful editorial expertise, not a backlink request; publication remains fully editorial.'
  UNION ALL SELECT 'Entrepreneur Middle East','entrepreneur.com','https://www.entrepreneur.com/en-ae','industry_publication','MENA',5,'high','Research contributor/editorial opportunities relevant to enterprise software selection','/methodology','Expert commentary or educational content for regional business buyers','Editorial target only; no endorsement, placement, or link is assumed.'
) s
WHERE @authority_seed_actor IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM authority_sources a
    WHERE a.domain=s.domain AND a.source_type=s.source_type
  );

COMMIT;
