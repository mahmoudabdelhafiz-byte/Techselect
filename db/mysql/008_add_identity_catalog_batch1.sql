-- TechSelectAI catalog expansion: Corporate Identity batch 1
-- Adds Popl, Uniqode and Mobilo using official vendor documentation reviewed in Sep 2026.
SET NAMES utf8mb4;
START TRANSACTION;

SET @cat_id=(SELECT id FROM categories WHERE slug='corporate-identity-digital-business-cards' LIMIT 1);

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Popl','popl','https://popl.co/','Digital business card and lead capture platform for teams and enterprises.','active'),
('Uniqode','uniqode','https://www.uniqode.com/','QR code and digital business card platform for teams and enterprises.','active'),
('Mobilo','mobilo','https://www.mobilocard.com/','Digital business card and lead capture platform for teams.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,@cat_id,x.name,x.slug,x.description,x.url,'active',NOW()
FROM vendors v JOIN (
 SELECT 'popl' vendor_slug,'Popl' name,'popl' slug,'Enterprise digital business cards with centralized branding, lead capture, CRM/HR integrations, SSO and team analytics.' description,'https://popl.co/pages/enterprise' url UNION ALL
 SELECT 'uniqode','Uniqode','uniqode','Digital business cards with centralized team controls, lead capture, analytics, CRM integrations and enterprise identity integrations.','https://www.uniqode.com/digital-business-card' UNION ALL
 SELECT 'mobilo','Mobilo','mobilo','Digital business cards for teams with centralized administration, lead capture, CRM automation and enterprise access controls.','https://www.mobilocard.com/'
) x ON x.vendor_slug=v.slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

-- Official vendor evidence sources.
INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',x.url,x.title,x.publisher,1,'verified','high',NOW()
FROM products p JOIN (
 SELECT 'popl' product_slug,'https://popl.co/pages/enterprise' url,'Popl for Enterprise' title,'Popl' publisher UNION ALL
 SELECT 'popl','https://support.popl.co/en/articles/8606349-integrations','Popl Integrations','Popl' UNION ALL
 SELECT 'uniqode','https://www.uniqode.com/digital-business-card','Uniqode Digital Business Cards','Uniqode' UNION ALL
 SELECT 'uniqode','https://docs.uniqode.com/en/collections/4059402-cards-integrations','Uniqode Cards Integrations','Uniqode' UNION ALL
 SELECT 'uniqode','https://docs.uniqode.com/en/articles/10484764-create-digital-business-cards-for-your-employees-using-okta','Uniqode Okta SCIM Integration','Uniqode' UNION ALL
 SELECT 'mobilo','https://www.mobilocard.com/','Mobilo Digital Business Cards for Teams','Mobilo' UNION ALL
 SELECT 'mobilo','https://www.mobilocard.com/support-articles/microsoft-sso','Mobilo Microsoft SSO','Mobilo' UNION ALL
 SELECT 'mobilo','https://www.mobilocard.com/native-integrations/overview','Mobilo Native Integrations Overview','Mobilo' UNION ALL
 SELECT 'mobilo','https://www.mobilocard.com/native-integrations/faq','Mobilo Native Integrations FAQ','Mobilo'
) x ON x.product_slug=p.slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=x.url);

DROP TEMPORARY TABLE IF EXISTS batch8_facts;
CREATE TEMPORARY TABLE batch8_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO batch8_facts VALUES
-- Popl
('popl','company-managed-digital-business-cards','supported',0.98,NULL,'https://popl.co/pages/enterprise'),
('popl','email-signatures','supported',0.95,NULL,'https://popl.co/pages/enterprise'),
('popl','meeting-backgrounds','supported',0.95,NULL,'https://popl.co/pages/enterprise'),
('popl','central-brand-templates','supported',0.98,'Enterprise permissions and templates support centralized brand control.','https://popl.co/pages/enterprise'),
('popl','automated-provisioning','supported',0.95,'Official enterprise materials describe HR and directory integrations including Azure Active Directory, Workday and Google.','https://popl.co/pages/enterprise'),
('popl','automated-deprovisioning','supported',0.95,'Official enterprise materials state members can be automatically removed when removed from the connected HR database.','https://popl.co/pages/enterprise'),
('popl','manual-offboarding-control','supported',0.95,'Admins can reassign or deactivate digital business cards.','https://popl.co/pages/enterprise'),
('popl','sso','supported',0.98,'Azure and Okta SAML 2.0 SSO are documented.','https://popl.co/pages/enterprise'),
('popl','scim','supported',0.95,'SCIM Provisioning is listed in official Popl integration documentation.','https://support.popl.co/en/articles/8606349-integrations'),
('popl','entra-id-integration','supported',0.95,'Azure Active Directory member import and Azure SAML are documented.','https://support.popl.co/en/articles/8606349-integrations'),
('popl','engagement-analytics','supported',0.98,NULL,'https://popl.co/pages/enterprise'),
('popl','lead-capture','supported',0.98,NULL,'https://popl.co/pages/enterprise'),
('popl','crm-integrations','supported',0.98,'Official integrations include Salesforce, HubSpot, Dynamics, Pipedrive, Zoho and others.','https://support.popl.co/en/articles/8606349-integrations'),
-- Uniqode
('uniqode','company-managed-digital-business-cards','supported',0.98,NULL,'https://www.uniqode.com/digital-business-card'),
('uniqode','email-signatures','supported',0.95,NULL,'https://www.uniqode.com/digital-business-card'),
('uniqode','meeting-backgrounds','supported',0.95,NULL,'https://www.uniqode.com/digital-business-card'),
('uniqode','central-brand-templates','supported',0.98,'Official Cards documentation describes bulk creation, organization permissions and enforced restrictions.','https://www.uniqode.com/digital-business-card'),
('uniqode','automated-provisioning','supported',0.95,'Official integrations include Microsoft Entra ID, Okta, Rippling and Google Workspace for employee card creation/sync.','https://docs.uniqode.com/en/collections/4059402-cards-integrations'),
('uniqode','automated-deprovisioning','partially_supported',0.85,'Directory synchronization and SCIM are documented, but exact offboarding behavior should be confirmed for the selected directory and plan.','https://docs.uniqode.com/en/collections/4059402-cards-integrations'),
('uniqode','sso','supported',0.95,'Uniqode publicly lists SSO among enterprise security capabilities.','https://www.uniqode.com/digital-business-card'),
('uniqode','scim','supported',0.95,'Official Okta integration documentation uses the SCIM standard for employee card provisioning.','https://docs.uniqode.com/en/articles/10484764-create-digital-business-cards-for-your-employees-using-okta'),
('uniqode','entra-id-integration','supported',0.95,'Microsoft Entra ID integration is listed in official Cards integration documentation.','https://docs.uniqode.com/en/collections/4059402-cards-integrations'),
('uniqode','engagement-analytics','supported',0.95,NULL,'https://www.uniqode.com/digital-business-card'),
('uniqode','lead-capture','supported',0.98,NULL,'https://www.uniqode.com/digital-business-card'),
('uniqode','crm-integrations','supported',0.98,'Official Cards integrations document Salesforce, HubSpot, Pipedrive and Zapier CRM workflows.','https://docs.uniqode.com/en/collections/4059402-cards-integrations'),
-- Mobilo
('mobilo','company-managed-digital-business-cards','supported',0.98,NULL,'https://www.mobilocard.com/'),
('mobilo','central-brand-templates','supported',0.95,'Admins can control branding and lock profile fields from a central dashboard.','https://www.mobilocard.com/'),
('mobilo','automated-provisioning','supported',0.90,'Mobilo documents HRIS connections and automated user provisioning.','https://www.mobilocard.com/'),
('mobilo','automated-deprovisioning','partially_supported',0.80,'Card deactivation and HRIS provisioning are documented; exact automatic removal behavior should be confirmed for the selected HRIS.','https://www.mobilocard.com/'),
('mobilo','manual-offboarding-control','supported',0.95,'Admins can deactivate cards.','https://www.mobilocard.com/'),
('mobilo','sso','supported',0.95,'Mobilo documents SAML SSO and enforced Microsoft SSO for organizations.','https://www.mobilocard.com/support-articles/microsoft-sso'),
('mobilo','entra-id-integration','partially_supported',0.85,'Microsoft SSO is documented; directory provisioning through Microsoft Entra ID is not fully verified in the reviewed source set.','https://www.mobilocard.com/support-articles/microsoft-sso'),
('mobilo','engagement-analytics','supported',0.95,'Team and individual performance insights are documented.','https://www.mobilocard.com/'),
('mobilo','lead-capture','supported',0.98,NULL,'https://www.mobilocard.com/'),
('mobilo','crm-integrations','supported',0.98,'Native and automated CRM integrations are documented, including Salesforce, HubSpot, Zoho, Pipedrive and Microsoft Dynamics.','https://www.mobilocard.com/native-integrations/faq');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM batch8_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

-- Explicit unknown rows preserve Unknown != Unsupported for unreviewed capabilities.
INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,c.id,NULL,'not_yet_verified',0
FROM products p CROSS JOIN capabilities c
JOIN modules m ON m.id=c.module_id
WHERE p.slug IN('popl','uniqode','mobilo') AND m.category_id=@cat_id
AND NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,f.limitations
FROM batch8_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Public SaaS deployment is explicitly documented/implicit for these hosted platforms.
INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.95 FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug IN('popl','uniqode','mobilo')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

-- Integration-level facts used by /integrations pages and recommendation dimensions.
INSERT INTO product_integrations(product_id,integration_id,support_status,confidence_score)
SELECT p.id,i.id,
CASE
 WHEN p.slug='popl' AND i.slug IN('microsoft-entra-id','crm','api') THEN 'supported'
 WHEN p.slug='uniqode' AND i.slug IN('microsoft-entra-id','crm') THEN 'supported'
 WHEN p.slug='mobilo' AND i.slug='crm' THEN 'supported'
 WHEN p.slug='mobilo' AND i.slug IN('microsoft-entra-id','api') THEN 'partially_supported'
 ELSE 'not_yet_verified' END,
CASE
 WHEN p.slug='popl' AND i.slug='microsoft-entra-id' THEN 0.95
 WHEN p.slug='popl' AND i.slug='crm' THEN 0.98
 WHEN p.slug='popl' AND i.slug='api' THEN 0.90
 WHEN p.slug='uniqode' AND i.slug='microsoft-entra-id' THEN 0.95
 WHEN p.slug='uniqode' AND i.slug='crm' THEN 0.98
 WHEN p.slug='mobilo' AND i.slug='crm' THEN 0.98
 WHEN p.slug='mobilo' AND i.slug='microsoft-entra-id' THEN 0.85
 WHEN p.slug='mobilo' AND i.slug='api' THEN 0.75
 ELSE 0 END
FROM products p JOIN integrations i
WHERE p.slug IN('popl','uniqode','mobilo')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

COMMIT;
