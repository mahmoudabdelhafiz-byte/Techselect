-- TechSelectAI catalog expansion: Corporate Identity & Digital Business Cards batch 3
-- Adds Haystack and Linq using official first-party evidence reviewed in Sep 2026.
-- Reuses the existing identity taxonomy and preserves Unknown != Unsupported.
SET NAMES utf8mb4;
START TRANSACTION;

SET @cat_id=(SELECT id FROM categories WHERE slug='corporate-identity-digital-business-cards' LIMIT 1);

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Haystack','haystack','https://thehaystackapp.com/','Digital business card and enterprise contact-management platform.','active'),
('Linq','linq','https://linqapp.com/','Digital business card, lead capture and mobile CRM platform.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,@cat_id,x.name,x.slug,x.description,x.url,'active',NOW()
FROM vendors v JOIN (
 SELECT 'haystack' vendor_slug,'Haystack' name,'haystack' slug,'Digital business cards for teams and enterprises with centralized templates, automated directory-driven lifecycle management, SSO and engagement analytics.' description,'https://thehaystackapp.com/enterprise' url UNION ALL
 SELECT 'linq','Linq','linq','Digital business card and mobile CRM platform with NFC/QR sharing, lead capture, analytics, CRM integrations and API access.' description,'https://linqapp.com/'
) x ON x.vendor_slug=v.slug
WHERE @cat_id IS NOT NULL
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',x.url,x.title,x.publisher,1,'verified','high',NOW()
FROM products p JOIN (
 SELECT 'haystack' product_slug,'https://thehaystackapp.com/enterprise' url,'Haystack for Enterprise' title,'Haystack' publisher UNION ALL
 SELECT 'haystack','https://thehaystackapp.com/','Haystack Digital Business Cards','Haystack' UNION ALL
 SELECT 'haystack','https://help.thehaystackapp.com/en/articles/4238090-azure-active-directory-azure-ad-integration','Haystack Microsoft Entra ID Integration','Haystack' UNION ALL
 SELECT 'haystack','https://help.thehaystackapp.com/en/articles/9385815-reducing-your-admin-overhead-to-zero','Haystack Automated Card Lifecycle Management','Haystack' UNION ALL
 SELECT 'haystack','https://help.thehaystackapp.com/en/articles/6048665-does-haystack-support-sso','Haystack Single Sign-On','Haystack' UNION ALL
 SELECT 'haystack','https://help.thehaystackapp.com/en/articles/1304873-i-signed-up-for-a-paid-plan-what-s-next','Haystack Admin Dashboard and Templates','Haystack' UNION ALL
 SELECT 'linq','https://help.linqapp.com/en/collections/10106475-general-faq','Linq General FAQ','Linq' UNION ALL
 SELECT 'linq','https://help.linqapp.com/en/articles/9845164-what-is-linq-one','Linq One','Linq' UNION ALL
 SELECT 'linq','https://help.linqapp.com/en/articles/all-about-the-hyper-products-from-linq','Linq Digital Business Card Products','Linq' UNION ALL
 SELECT 'linq','https://docs.linqapp.com/channel/imessage/guides/platform/sso/','Linq Single Sign-On Documentation','Linq'
) x ON x.product_slug=p.slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=x.url);

DROP TEMPORARY TABLE IF EXISTS cat71_facts;
CREATE TEMPORARY TABLE cat71_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat71_facts VALUES
-- Haystack
('haystack','company-managed-digital-business-cards','supported',0.99,'Enterprise and paid plans provide centralized administration of employee cards.','https://thehaystackapp.com/enterprise'),
('haystack','email-signatures','supported',0.98,'Paid-plan administration includes managed smart email signatures.','https://help.thehaystackapp.com/en/articles/1304873-i-signed-up-for-a-paid-plan-what-s-next'),
('haystack','central-brand-templates','supported',0.99,'Admins create templates that control shared company branding and card content.','https://help.thehaystackapp.com/en/articles/1304873-i-signed-up-for-a-paid-plan-what-s-next'),
('haystack','automated-provisioning','supported',0.99,'Entra/Active Directory and HR integrations can automatically create cards for new employees.','https://help.thehaystackapp.com/en/articles/9385815-reducing-your-admin-overhead-to-zero'),
('haystack','automated-deprovisioning','supported',0.99,'Official lifecycle documentation states leaver cards can be automatically deactivated.','https://help.thehaystackapp.com/en/articles/9385815-reducing-your-admin-overhead-to-zero'),
('haystack','manual-offboarding-control','supported',0.95,'Enterprise card management supports administrative card deactivation.','https://thehaystackapp.com/enterprise'),
('haystack','sso','supported',0.99,'Enterprise SSO is documented using OIDC with providers including Microsoft Entra ID and Okta.','https://help.thehaystackapp.com/en/articles/6048665-does-haystack-support-sso'),
('haystack','entra-id-integration','supported',0.99,'Microsoft Entra ID integration is documented for employee filtering, template assignment and synchronized card data.','https://help.thehaystackapp.com/en/articles/4238090-azure-active-directory-azure-ad-integration'),
('haystack','engagement-analytics','supported',0.98,'Official product materials describe team engagement and recipient analytics.','https://thehaystackapp.com/'),
('haystack','lead-capture','supported',0.95,'Haystack supports scanning and saving contacts and digital-card sharing workflows.','https://thehaystackapp.com/'),

-- Linq: keep enterprise lifecycle facts unknown unless card-specific evidence proves them.
('linq','company-managed-digital-business-cards','supported',0.90,'Linq offers team subscriptions and digital business cards; advanced enterprise administration depth should be confirmed for the selected plan.','https://help.linqapp.com/en/collections/10106475-general-faq'),
('linq','central-brand-templates','partially_supported',0.80,'Linq supports branded/custom digital-card products and team use; centralized template-governance depth was not fully verified in this evidence batch.','https://help.linqapp.com/en/articles/all-about-the-hyper-products-from-linq'),
('linq','engagement-analytics','supported',0.98,'Linq One documents advanced analytics.','https://help.linqapp.com/en/articles/9845164-what-is-linq-one'),
('linq','lead-capture','supported',0.99,'Linq documents lead forms, contact capture and mobile CRM workflows.','https://help.linqapp.com/en/articles/9845164-what-is-linq-one'),
('linq','crm-integrations','supported',0.99,'Official FAQ lists Salesforce, HubSpot, GoHighLevel and Zapier-backed CRM connectivity depending on plan.','https://help.linqapp.com/en/collections/10106475-general-faq');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat71_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,c.id,NULL,'not_yet_verified',0
FROM products p CROSS JOIN capabilities c JOIN modules m ON m.id=c.module_id
WHERE p.slug IN('haystack','linq') AND m.category_id=@cat_id
AND NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,f.limitations
FROM cat71_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.95
FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug IN('haystack','linq')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

INSERT INTO product_integrations(product_id,integration_id,support_status,confidence_score)
SELECT p.id,i.id,
CASE
 WHEN p.slug='haystack' AND i.slug='microsoft-entra-id' THEN 'supported'
 WHEN p.slug='haystack' AND i.slug='api' THEN 'supported'
 WHEN p.slug='linq' AND i.slug IN('crm','api') THEN 'supported'
 ELSE 'not_yet_verified' END,
CASE
 WHEN p.slug='haystack' AND i.slug='microsoft-entra-id' THEN 0.99
 WHEN p.slug='haystack' AND i.slug='api' THEN 0.95
 WHEN p.slug='linq' AND i.slug='crm' THEN 0.99
 WHEN p.slug='linq' AND i.slug='api' THEN 0.95
 ELSE 0 END
FROM products p JOIN integrations i
WHERE p.slug IN('haystack','linq')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

DROP TEMPORARY TABLE IF EXISTS cat71_facts;
COMMIT;
