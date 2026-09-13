-- TechSelectAI catalog expansion: Corporate Identity & Digital Business Cards batch 2
-- Adds Wave Connect, Spreadly and Tapt using official first-party evidence reviewed in Sep 2026.
-- Reuses the existing identity taxonomy and preserves Unknown != Unsupported.
SET NAMES utf8mb4;
START TRANSACTION;

SET @cat_id=(SELECT id FROM categories WHERE slug='corporate-identity-digital-business-cards' LIMIT 1);

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Wave Connect','wave-connect','https://wavecnct.com/','Digital business card platform for teams and enterprises.','active'),
('Spreadly','spreadly','https://spreadly.app/','Digital business card and lead capture platform for teams and enterprises.','active'),
('Tapt','tapt','https://tapt.io/','Digital business card, profile and contact-capture platform for teams.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,@cat_id,x.name,x.slug,x.description,x.url,'active',NOW()
FROM vendors v JOIN (
 SELECT 'wave-connect' vendor_slug,'Wave Connect' name,'wave-connect' slug,'Enterprise digital business cards with centralized brand controls, directory provisioning, SSO/SCIM, CRM integrations, lead capture and usage analytics.' description,'https://wavecnct.com/enterprise' url UNION ALL
 SELECT 'spreadly','Spreadly','spreadly','Centrally managed digital business cards for teams with templates, HR and identity integrations, analytics, lead capture and CRM synchronization.','https://spreadly.app/en/digital-business-card/for-teams' UNION ALL
 SELECT 'tapt','Tapt','tapt','Team digital business card platform with centralized administration, profile templates, lifecycle controls, enterprise access integrations, analytics and CRM connectivity.','https://tapt.io/en-us/pages/features'
) x ON x.vendor_slug=v.slug
WHERE @cat_id IS NOT NULL
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',x.url,x.title,x.publisher,1,'verified','high',NOW()
FROM products p JOIN (
 SELECT 'wave-connect' product_slug,'https://wavecnct.com/enterprise' url,'Wave Connect Enterprise' title,'Wave Connect' publisher UNION ALL
 SELECT 'wave-connect','https://wavecnct.com/pricing','Wave Connect Pricing and Plan Features','Wave Connect' UNION ALL
 SELECT 'spreadly','https://spreadly.app/en/digital-business-card/for-teams','Spreadly Digital Business Cards for Teams','Spreadly' UNION ALL
 SELECT 'spreadly','https://spreadly.app/en/integrations','Spreadly Integrations','Spreadly' UNION ALL
 SELECT 'spreadly','https://spreadly.app/en/digital-business-card','Spreadly Digital Business Card','Spreadly' UNION ALL
 SELECT 'tapt','https://tapt.io/en-us/pages/features','Tapt Features','Tapt' UNION ALL
 SELECT 'tapt','https://tapt.io/en-us/pages/pricing','Tapt Pricing and Business Features','Tapt' UNION ALL
 SELECT 'tapt','https://help.tapt.io/en/articles/16850716-manage-joiners-role-changes-and-departing-employees','Tapt Employee Lifecycle Management','Tapt' UNION ALL
 SELECT 'tapt','https://help.tapt.io/en/articles/16856453-dashboard-navigation-and-account-overview','Tapt Dashboard and Account Overview','Tapt'
) x ON x.product_slug=p.slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=x.url);

DROP TEMPORARY TABLE IF EXISTS cat70_facts;
CREATE TEMPORARY TABLE cat70_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat70_facts VALUES
-- Wave Connect
('wave-connect','company-managed-digital-business-cards','supported',0.99,NULL,'https://wavecnct.com/enterprise'),
('wave-connect','email-signatures','supported',0.95,'Email-signature capabilities vary by plan.','https://wavecnct.com/pricing'),
('wave-connect','central-brand-templates','supported',0.99,'Enterprise documentation describes master templates, locked branding and regional/department controls.','https://wavecnct.com/enterprise'),
('wave-connect','automated-provisioning','supported',0.99,'Directory and SCIM provisioning are documented for enterprise deployments.','https://wavecnct.com/enterprise'),
('wave-connect','automated-deprovisioning','supported',0.99,'Wave documents automatic de-provisioning and card deactivation when employees leave connected directories.','https://wavecnct.com/enterprise'),
('wave-connect','sso','supported',0.99,'SAML-based SSO with providers including Okta and Azure AD is documented.','https://wavecnct.com/enterprise'),
('wave-connect','scim','supported',0.99,'SCIM provisioning and de-provisioning are explicitly documented.','https://wavecnct.com/enterprise'),
('wave-connect','entra-id-integration','supported',0.98,'Azure AD / Active Directory provisioning is explicitly documented; current Microsoft product naming may differ.','https://wavecnct.com/enterprise'),
('wave-connect','engagement-analytics','supported',0.98,'Enterprise usage and adoption analytics are documented.','https://wavecnct.com/enterprise'),
('wave-connect','lead-capture','supported',0.98,'Lead capture is included in current team/enterprise materials.','https://wavecnct.com/pricing'),
('wave-connect','crm-integrations','supported',0.99,'Native integrations with Salesforce, Microsoft Dynamics and HubSpot are documented.','https://wavecnct.com/enterprise'),

-- Spreadly
('spreadly','company-managed-digital-business-cards','supported',0.99,NULL,'https://spreadly.app/en/digital-business-card/for-teams'),
('spreadly','email-signatures','supported',0.98,NULL,'https://spreadly.app/en/digital-business-card'),
('spreadly','meeting-backgrounds','supported',0.95,'Spreadly lists virtual backgrounds as a supported sharing/brand surface.','https://spreadly.app/en/digital-business-card'),
('spreadly','central-brand-templates','supported',0.99,'Central templates and group-specific templates are documented.','https://spreadly.app/en/digital-business-card/for-teams'),
('spreadly','automated-provisioning','supported',0.99,'HR and identity integrations automatically create and update employees.','https://spreadly.app/en/integrations'),
('spreadly','automated-deprovisioning','supported',0.99,'Official integration documentation states former employees are automatically removed.','https://spreadly.app/en/integrations'),
('spreadly','manual-offboarding-control','supported',0.98,'Admins can deactivate an employee digital business card immediately.','https://spreadly.app/en/digital-business-card/for-teams'),
('spreadly','sso','supported',0.95,'Enterprise team documentation states SSO integration is supported.','https://spreadly.app/en/digital-business-card/for-teams'),
('spreadly','scim','supported',0.95,'Spreadly documents SCIM-based user management.','https://spreadly.app/en/digital-business-card/for-teams'),
('spreadly','entra-id-integration','supported',0.99,'Microsoft Entra ID integration is explicitly documented for employee synchronization.','https://spreadly.app/en/digital-business-card/for-teams'),
('spreadly','engagement-analytics','supported',0.99,'Team analytics and usage/adoption reporting are documented.','https://spreadly.app/en/digital-business-card/for-teams'),
('spreadly','lead-capture','supported',0.99,'Lead forms and lead capture are documented in professional/team features.','https://spreadly.app/en/digital-business-card'),
('spreadly','crm-integrations','supported',0.99,'Spreadly documents CRM synchronization and major CRM integrations.','https://spreadly.app/en/integrations'),

-- Tapt
('tapt','company-managed-digital-business-cards','supported',0.99,'Organizations manage digital profiles and cards centrally through the Tapt Dashboard.','https://help.tapt.io/en/articles/16856453-dashboard-navigation-and-account-overview'),
('tapt','email-signatures','supported',0.90,'Tapt positions email signatures as part of its team platform; exact controls vary by plan/configuration.','https://tapt.io/'),
('tapt','central-brand-templates','supported',0.99,'Profile templates and team/group management are documented.','https://tapt.io/en-us/pages/features'),
('tapt','automated-provisioning','supported',0.95,'SCIM provisioning with Active Directory is documented.','https://tapt.io/en-us/pages/features'),
('tapt','manual-offboarding-control','supported',0.99,'Admins can clear or delete departing employee profiles and remove management access.','https://help.tapt.io/en/articles/16850716-manage-joiners-role-changes-and-departing-employees'),
('tapt','sso','supported',0.99,'SAML SSO is explicitly documented.','https://tapt.io/en-us/pages/features'),
('tapt','scim','supported',0.99,'SCIM provisioning with Active Directory is explicitly documented.','https://tapt.io/en-us/pages/features'),
('tapt','entra-id-integration','supported',0.95,'Current business features explicitly list SSO and Entra ID connectivity.','https://tapt.io/en-us/pages/pricing'),
('tapt','engagement-analytics','supported',0.98,'Dashboard analytics and usage insights are documented.','https://help.tapt.io/en/articles/16856453-dashboard-navigation-and-account-overview'),
('tapt','lead-capture','supported',0.95,'Centralized lead/contact management is documented as a platform capability.','https://tapt.io/en-us/pages/pricing'),
('tapt','crm-integrations','supported',0.99,'Salesforce, HubSpot and Dynamics integrations are explicitly documented.','https://tapt.io/en-us/pages/features');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat70_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

-- Unreviewed identity capabilities remain explicitly unknown, never inferred unsupported.
INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,c.id,NULL,'not_yet_verified',0
FROM products p CROSS JOIN capabilities c JOIN modules m ON m.id=c.module_id
WHERE p.slug IN('wave-connect','spreadly','tapt') AND m.category_id=@cat_id
AND NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,f.limitations
FROM cat70_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- All three products are first-party documented as hosted online/cloud platforms.
INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.95
FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug IN('wave-connect','spreadly','tapt')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

-- Integration assertions are restricted to integrations explicitly verified above.
INSERT INTO product_integrations(product_id,integration_id,support_status,confidence_score)
SELECT p.id,i.id,
CASE
 WHEN p.slug='wave-connect' AND i.slug IN('microsoft-entra-id','crm') THEN 'supported'
 WHEN p.slug='spreadly' AND i.slug IN('microsoft-entra-id','crm','api') THEN 'supported'
 WHEN p.slug='tapt' AND i.slug IN('microsoft-entra-id','crm') THEN 'supported'
 ELSE 'not_yet_verified' END,
CASE
 WHEN p.slug='wave-connect' AND i.slug='microsoft-entra-id' THEN 0.98
 WHEN p.slug='wave-connect' AND i.slug='crm' THEN 0.99
 WHEN p.slug='spreadly' AND i.slug='microsoft-entra-id' THEN 0.99
 WHEN p.slug='spreadly' AND i.slug='crm' THEN 0.99
 WHEN p.slug='spreadly' AND i.slug='api' THEN 0.95
 WHEN p.slug='tapt' AND i.slug='microsoft-entra-id' THEN 0.95
 WHEN p.slug='tapt' AND i.slug='crm' THEN 0.99
 ELSE 0 END
FROM products p JOIN integrations i
WHERE p.slug IN('wave-connect','spreadly','tapt')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

DROP TEMPORARY TABLE IF EXISTS cat70_facts;
COMMIT;
