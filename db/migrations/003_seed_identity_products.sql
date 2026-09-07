BEGIN;

-- Sprint 1.3 initial curated dataset.
-- Scope is intentionally narrow and deep: Corporate Identity / Digital Business Cards.
-- Public vendor facts are seeded only where supported by current official sources.

INSERT INTO categories (name, slug, description)
VALUES ('Corporate Identity & Digital Business Cards', 'corporate-identity-digital-business-cards',
        'Company-controlled digital business cards, employee identity, signatures, meeting identity, lifecycle controls and verification.')
ON CONFLICT (slug) DO UPDATE SET description = EXCLUDED.description;

WITH c AS (
  SELECT id FROM categories WHERE slug = 'corporate-identity-digital-business-cards'
)
INSERT INTO modules (category_id, name, slug, description)
SELECT c.id, v.name, v.slug, v.description
FROM c
CROSS JOIN (VALUES
  ('Digital Business Cards', 'digital-business-cards', 'Company-managed digital business cards and sharing.'),
  ('Brand & Communication', 'brand-communication', 'Email signatures, meeting backgrounds and brand governance.'),
  ('Identity Lifecycle', 'identity-lifecycle', 'Provisioning, deprovisioning, offboarding and identity lifecycle controls.'),
  ('Enterprise Access', 'enterprise-access', 'SSO, SCIM and enterprise directory integrations.'),
  ('Verification & Trust', 'verification-trust', 'Company and employee verification, communication verification and trust controls.'),
  ('Analytics & CRM', 'analytics-crm', 'Engagement analytics, lead capture and CRM integrations.')
) AS v(name, slug, description)
ON CONFLICT (category_id, slug) DO UPDATE SET description = EXCLUDED.description;

INSERT INTO capabilities (module_id, name, slug, description, is_security_related)
SELECT m.id, v.name, v.slug, v.description, v.is_security
FROM modules m
JOIN categories c ON c.id = m.category_id AND c.slug = 'corporate-identity-digital-business-cards'
JOIN (VALUES
  ('digital-business-cards','Company-managed digital business cards','company-managed-digital-business-cards','Admins can issue and manage company business cards.',false),
  ('brand-communication','Email signatures','email-signatures','Company-branded employee email signatures.',false),
  ('brand-communication','Meeting backgrounds','meeting-backgrounds','Company-branded virtual meeting backgrounds.',false),
  ('brand-communication','Central brand templates','central-brand-templates','Centralized brand/template governance.',false),
  ('identity-lifecycle','Automated provisioning','automated-provisioning','Automated employee/account provisioning from connected directories or HR systems.',true),
  ('identity-lifecycle','Automated deprovisioning','automated-deprovisioning','Automated deactivation or removal when an employee leaves or is removed from a source directory.',true),
  ('identity-lifecycle','Manual deactivation / offboarding control','manual-offboarding-control','Admin-controlled employee identity deactivation/offboarding.',true),
  ('enterprise-access','Single sign-on (SSO)','sso','Enterprise single sign-on.',true),
  ('enterprise-access','SCIM provisioning','scim','SCIM-based lifecycle provisioning.',true),
  ('enterprise-access','Microsoft Entra ID integration','entra-id-integration','Microsoft Entra ID directory integration.',true),
  ('verification-trust','Employee identity verification','employee-identity-verification','Public or recipient-facing confirmation of employee identity/status.',true),
  ('verification-trust','Company / domain verification','company-domain-verification','Verification of company or company-controlled domain.',true),
  ('verification-trust','Communication channel verification','communication-channel-verification','Company-scoped verification of approved email, phone, WhatsApp or domain channels.',true),
  ('analytics-crm','Engagement analytics','engagement-analytics','Card/profile engagement analytics.',false),
  ('analytics-crm','Lead capture','lead-capture','Capture visitor/contact details as leads.',false),
  ('analytics-crm','CRM integrations','crm-integrations','Native or supported CRM integrations.',false)
) AS v(module_slug,name,slug,description,is_security)
  ON m.slug = v.module_slug
ON CONFLICT (module_id, slug) DO UPDATE SET description = EXCLUDED.description, is_security_related = EXCLUDED.is_security_related;

INSERT INTO vendors (name, slug, website_url, description)
VALUES
  ('Barmageyat', 'barmageyat', 'https://card-iq.net/', 'Vendor of CardIQ.'),
  ('Blinq', 'blinq', 'https://blinq.me/', 'Digital business card platform vendor.'),
  ('HiHello', 'hihello', 'https://www.hihello.com/', 'Digital business card platform vendor.')
ON CONFLICT (slug) DO UPDATE SET website_url = EXCLUDED.website_url, description = EXCLUDED.description;

WITH cat AS (SELECT id FROM categories WHERE slug='corporate-identity-digital-business-cards')
INSERT INTO products (vendor_id, category_id, name, slug, short_description, website_url, status, last_reviewed_at)
SELECT v.id, cat.id, p.name, p.slug, p.description, p.url, 'active', now()
FROM cat
JOIN (VALUES
  ('barmageyat','CardIQ','cardiq','Corporate digital identity control platform with company-controlled cards, verification and lifecycle controls.','https://card-iq.net/?lang=en'),
  ('blinq','Blinq','blinq','Digital business card platform for teams and enterprises.','https://blinq.me/enterprise'),
  ('hihello','HiHello','hihello','Digital business card platform with business and enterprise administration.','https://www.hihello.com/enterprise')
) AS p(vendor_slug,name,slug,description,url) ON true
JOIN vendors v ON v.slug = p.vendor_slug
ON CONFLICT (slug) DO UPDATE SET
  vendor_id = EXCLUDED.vendor_id,
  category_id = EXCLUDED.category_id,
  short_description = EXCLUDED.short_description,
  website_url = EXCLUDED.website_url,
  last_reviewed_at = EXCLUDED.last_reviewed_at;

INSERT INTO product_categories (product_id, category_id, is_primary)
SELECT p.id, c.id, true
FROM products p CROSS JOIN categories c
WHERE p.slug IN ('cardiq','blinq','hihello') AND c.slug='corporate-identity-digital-business-cards'
ON CONFLICT (product_id, category_id) DO UPDATE SET is_primary = true;

INSERT INTO product_modules (product_id, module_id, is_core)
SELECT p.id, m.id, true
FROM products p
JOIN modules m ON m.category_id = (SELECT id FROM categories WHERE slug='corporate-identity-digital-business-cards')
WHERE p.slug IN ('cardiq','blinq','hihello')
ON CONFLICT (product_id, module_id) DO NOTHING;

-- Evidence sources: official public vendor pages reviewed during Sprint 1.3.
INSERT INTO evidence_sources (product_id, source_type, source_url, source_title, publisher_name, vendor_owned, verification_status, confidence, checked_at)
SELECT p.id, 'vendor_documentation', e.url, e.title, e.publisher, true, 'verified', 'high', now()
FROM (VALUES
  ('cardiq','https://card-iq.net/?lang=en','CardIQ Corporate Digital Identity Control Platform','CardIQ'),
  ('cardiq','https://card-iq.net/corporate_identity_management.php?lang=en','CardIQ Corporate Digital Identity Control','CardIQ'),
  ('cardiq','https://card-iq.net/how_cardiq_works.php?lang=en','How CardIQ Works','CardIQ'),
  ('blinq','https://blinq.me/enterprise','Blinq Enterprise','Blinq'),
  ('blinq','https://support.blinq.me/en/articles/73643-business-admin-onboarding-guide','Blinq Business Admin Onboarding Guide','Blinq'),
  ('hihello','https://www.hihello.com/enterprise','HiHello Enterprise','HiHello'),
  ('hihello','https://support.hihello.com/hc/en-us/articles/16012981708699-Creating-Cards-With-Microsoft-Entra-ID-Formerly-Known-as-Azure-Active-Directory','HiHello Microsoft Entra ID Integration','HiHello')
) AS e(product_slug,url,title,publisher)
JOIN products p ON p.slug=e.product_slug
WHERE NOT EXISTS (
  SELECT 1 FROM evidence_sources es WHERE es.product_id=p.id AND es.source_url=e.url
);

-- Helper seed table. Facts not listed here remain unknown/not-yet-verified.
CREATE TEMP TABLE seed_capability_facts (
  product_slug text,
  capability_slug text,
  support_status capability_support_status,
  source_url text,
  limitations text
) ON COMMIT DROP;

INSERT INTO seed_capability_facts VALUES
  -- CardIQ: current public claims only.
  ('cardiq','company-managed-digital-business-cards','supported','https://card-iq.net/?lang=en',NULL),
  ('cardiq','email-signatures','supported','https://card-iq.net/?lang=en',NULL),
  ('cardiq','meeting-backgrounds','supported','https://card-iq.net/?lang=en',NULL),
  ('cardiq','central-brand-templates','supported','https://card-iq.net/?lang=en',NULL),
  ('cardiq','manual-offboarding-control','supported','https://card-iq.net/how_cardiq_works.php?lang=en',NULL),
  ('cardiq','employee-identity-verification','supported','https://card-iq.net/corporate_identity_management.php?lang=en',NULL),
  ('cardiq','company-domain-verification','supported','https://card-iq.net/how_cardiq_works.php?lang=en','Domain verification uses a DNS TXT record where enabled.'),
  ('cardiq','engagement-analytics','supported','https://card-iq.net/?lang=en',NULL),
  ('cardiq','lead-capture','supported','https://card-iq.net/?lang=en',NULL),
  -- Blinq enterprise.
  ('blinq','company-managed-digital-business-cards','supported','https://blinq.me/enterprise',NULL),
  ('blinq','email-signatures','supported','https://blinq.me/enterprise',NULL),
  ('blinq','meeting-backgrounds','supported','https://blinq.me/solutions/digital-business-card',NULL),
  ('blinq','central-brand-templates','supported','https://blinq.me/enterprise',NULL),
  ('blinq','automated-provisioning','supported','https://blinq.me/enterprise',NULL),
  ('blinq','automated-deprovisioning','supported','https://blinq.me/enterprise',NULL),
  ('blinq','sso','supported','https://blinq.me/enterprise','Enterprise page describes SAML SSO support.'),
  ('blinq','scim','supported','https://blinq.me/enterprise','Enterprise page describes SCIM provisioning/deprovisioning.'),
  ('blinq','entra-id-integration','supported','https://blinq.me/enterprise',NULL),
  ('blinq','crm-integrations','supported','https://blinq.me/enterprise',NULL),
  -- HiHello enterprise.
  ('hihello','company-managed-digital-business-cards','supported','https://www.hihello.com/enterprise',NULL),
  ('hihello','email-signatures','supported','https://www.hihello.com/enterprise',NULL),
  ('hihello','meeting-backgrounds','supported','https://www.hihello.com/enterprise',NULL),
  ('hihello','central-brand-templates','supported','https://www.hihello.com/enterprise',NULL),
  ('hihello','automated-provisioning','supported','https://www.hihello.com/enterprise',NULL),
  ('hihello','automated-deprovisioning','supported','https://support.hihello.com/hc/en-us/articles/16012981708699-Creating-Cards-With-Microsoft-Entra-ID-Formerly-Known-as-Azure-Active-Directory','Removing employees from connected Entra groups removes them from HiHello and pauses their cards.'),
  ('hihello','sso','supported','https://www.hihello.com/enterprise',NULL),
  ('hihello','scim','supported','https://www.hihello.com/enterprise','HiHello states Okta SAML/SCIM support and enterprise identity integrations.'),
  ('hihello','entra-id-integration','supported','https://support.hihello.com/hc/en-us/articles/16012981708699-Creating-Cards-With-Microsoft-Entra-ID-Formerly-Known-as-Azure-Active-Directory',NULL),
  ('hihello','engagement-analytics','supported','https://www.hihello.com/enterprise',NULL),
  ('hihello','lead-capture','supported','https://www.hihello.com/enterprise',NULL),
  ('hihello','crm-integrations','supported','https://www.hihello.com/enterprise',NULL);

INSERT INTO product_capabilities (product_id, capability_id, support_status, limitations, confidence_score, last_verified_at)
SELECT p.id, c.id, f.support_status, f.limitations, 0.95, now()
FROM seed_capability_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
ON CONFLICT (product_id, capability_id, COALESCE(edition_id, 0)) DO UPDATE SET
  support_status=EXCLUDED.support_status,
  limitations=EXCLUDED.limitations,
  confidence_score=EXCLUDED.confidence_score,
  last_verified_at=EXCLUDED.last_verified_at,
  updated_at=now();

INSERT INTO product_capability_evidence (product_capability_id, evidence_source_id, is_primary)
SELECT pc.id, es.id, true
FROM seed_capability_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources es ON es.product_id=p.id AND es.source_url=f.source_url
ON CONFLICT (product_capability_id, evidence_source_id) DO UPDATE SET is_primary=true;

-- Explicit unknown facts for comparison transparency. This allows UI/scoring to
-- distinguish "not verified" from "not supported".
INSERT INTO product_capabilities (product_id, capability_id, support_status, confidence_score)
SELECT p.id, c.id, 'not_yet_verified', 0.0
FROM products p
CROSS JOIN capabilities c
JOIN modules m ON m.id=c.module_id
JOIN categories cat ON cat.id=m.category_id AND cat.slug='corporate-identity-digital-business-cards'
WHERE p.slug IN ('cardiq','blinq','hihello')
  AND NOT EXISTS (
    SELECT 1 FROM product_capabilities pc
    WHERE pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
  )
ON CONFLICT (product_id, capability_id, COALESCE(edition_id, 0)) DO NOTHING;

COMMIT;
