-- TechSelectAI catalog expansion: CRM batch 1
-- Adds Salesforce Sales Cloud, Dynamics 365 Sales, HubSpot Sales Hub, Zoho CRM,
-- Freshsales, Pipedrive and Odoo CRM using official vendor documentation reviewed in Sep 2026.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('CRM','crm','Customer relationship management software for lead, account, opportunity, pipeline, sales automation, forecasting, reporting and integrations.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @cat_id=(SELECT id FROM categories WHERE slug='crm' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@cat_id,'Lead & Pipeline Management','crm-lead-pipeline','Lead, contact, account, deal and opportunity pipeline management.',1),
(@cat_id,'Sales Automation & Analytics','crm-automation-analytics','Workflow automation, forecasting, dashboards and sales analytics.',1),
(@cat_id,'Enterprise & Integration','crm-enterprise-integration','Enterprise access, APIs and extensibility.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.security,1
FROM modules m JOIN (
 SELECT 'crm-lead-pipeline' module_slug,'Lead management' name,'crm-lead-management' slug,'Capture, qualify, assign and manage sales leads.' description,0 security UNION ALL
 SELECT 'crm-lead-pipeline','Contact & account management','crm-contact-account-management','Manage customer contacts and company accounts.',0 UNION ALL
 SELECT 'crm-lead-pipeline','Opportunity / deal pipeline','crm-opportunity-pipeline','Track opportunities or deals through configurable sales stages.',0 UNION ALL
 SELECT 'crm-automation-analytics','Sales workflow automation','crm-sales-automation','Automate sales tasks, routing, follow-up or process steps.',0 UNION ALL
 SELECT 'crm-automation-analytics','Sales forecasting','crm-sales-forecasting','Forecast sales pipeline and expected revenue.',0 UNION ALL
 SELECT 'crm-automation-analytics','Reports & dashboards','crm-reports-dashboards','Sales reporting, dashboards and performance analytics.',0 UNION ALL
 SELECT 'crm-enterprise-integration','API access','crm-api-access','Vendor-supported API access for integration and extensibility.',0 UNION ALL
 SELECT 'crm-enterprise-integration','Single sign-on (SSO)','crm-sso','Enterprise single sign-on for CRM users.',1
) x ON x.module_slug=m.slug
WHERE m.category_id=@cat_id
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Salesforce','salesforce','https://www.salesforce.com/','Enterprise CRM and cloud application vendor.','active'),
('Microsoft','microsoft','https://www.microsoft.com/','Enterprise software and cloud platform vendor.','active'),
('HubSpot','hubspot','https://www.hubspot.com/','CRM, marketing, sales and service software vendor.','active'),
('Zoho','zoho','https://www.zoho.com/','Business software and CRM vendor.','active'),
('Freshworks','freshworks','https://www.freshworks.com/','Customer and employee software vendor.','active'),
('Pipedrive','pipedrive','https://www.pipedrive.com/','Sales CRM vendor.','active'),
('Odoo','odoo','https://www.odoo.com/','Open-source business application suite vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,@cat_id,x.name,x.slug,x.description,x.url,'active',NOW()
FROM vendors v JOIN (
 SELECT 'salesforce' vendor_slug,'Salesforce Sales Cloud' name,'salesforce-sales-cloud' slug,'Enterprise sales CRM for lead, opportunity, pipeline, forecasting and sales productivity.' description,'https://www.salesforce.com/sales/cloud/' url UNION ALL
 SELECT 'microsoft','Dynamics 365 Sales','dynamics-365-sales','Microsoft CRM for lead and opportunity management, seller productivity, forecasting and AI-assisted sales execution.','https://www.microsoft.com/en-us/dynamics-365/products/sales' UNION ALL
 SELECT 'hubspot','HubSpot Sales Hub','hubspot-sales-hub','Sales CRM and sales engagement platform built on HubSpot Smart CRM.','https://www.hubspot.com/products/sales' UNION ALL
 SELECT 'zoho','Zoho CRM','zoho-crm','Configurable CRM with lead and pipeline management, automation, analytics and broad integrations.','https://www.zoho.com/crm/' UNION ALL
 SELECT 'freshworks','Freshsales','freshsales','Sales CRM with pipeline management, automation, analytics, roles and API integrations.','https://www.freshworks.com/crm/' UNION ALL
 SELECT 'pipedrive','Pipedrive','pipedrive','Sales-focused CRM with customizable pipelines, reporting, automation, marketplace integrations and API access.','https://www.pipedrive.com/' UNION ALL
 SELECT 'odoo','Odoo CRM','odoo-crm','Open-source CRM application for lead, opportunity, activity, forecasting and integrated sales workflows.','https://www.odoo.com/app/crm'
) x ON x.vendor_slug=v.slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',x.url,x.title,x.publisher,1,'verified','high',NOW()
FROM products p JOIN (
 SELECT 'salesforce-sales-cloud' product_slug,'https://help.salesforce.com/s/articleView?id=000372249&language=en_US&type=3' url,'What is Sales Cloud?' title,'Salesforce' publisher UNION ALL
 SELECT 'dynamics-365-sales','https://www.microsoft.com/en-us/dynamics-365/products/sales','Dynamics 365 Sales','Microsoft' UNION ALL
 SELECT 'dynamics-365-sales','https://learn.microsoft.com/en-us/dynamics365/release-plan/2026wave1/sales/dynamics365-sales/','Dynamics 365 Sales 2026 release wave 1','Microsoft' UNION ALL
 SELECT 'hubspot-sales-hub','https://developers.hubspot.com/docs/api-reference/latest/crm/understanding-the-crm','HubSpot CRM APIs','HubSpot' UNION ALL
 SELECT 'hubspot-sales-hub','https://knowledge.hubspot.com/account-security/set-up-single-sign-on-sso','HubSpot single sign-on','HubSpot' UNION ALL
 SELECT 'zoho-crm','https://www.zoho.com/crm/features.html','Zoho CRM features','Zoho' UNION ALL
 SELECT 'zoho-crm','https://www.zoho.com/crm/developer/api.html','Zoho CRM API and SDK library','Zoho' UNION ALL
 SELECT 'freshsales','https://www.freshworks.com/crm/features/','Freshsales CRM features','Freshworks' UNION ALL
 SELECT 'freshsales','https://developers.freshworks.com/crm/api/','Freshsales API','Freshworks' UNION ALL
 SELECT 'pipedrive','https://www.pipedrive.com/en/crm/features','Pipedrive CRM features','Pipedrive' UNION ALL
 SELECT 'pipedrive','https://www.pipedrive.com/en/features/crm-api','Pipedrive CRM API','Pipedrive' UNION ALL
 SELECT 'pipedrive','https://support.pipedrive.com/en/article/single-sign-on','Pipedrive single sign-on','Pipedrive' UNION ALL
 SELECT 'odoo-crm','https://www.odoo.com/app/crm','Odoo CRM','Odoo' UNION ALL
 SELECT 'odoo-crm','https://www.odoo.com/documentation/19.0/developer/reference/external_api.html','Odoo External JSON-2 API','Odoo'
) x ON x.product_slug=p.slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=x.url);

DROP TEMPORARY TABLE IF EXISTS crm9_facts;
CREATE TEMPORARY TABLE crm9_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO crm9_facts VALUES
('salesforce-sales-cloud','crm-lead-management','supported',0.95,NULL,'https://help.salesforce.com/s/articleView?id=000372249&language=en_US&type=3'),
('salesforce-sales-cloud','crm-opportunity-pipeline','supported',0.98,NULL,'https://help.salesforce.com/s/articleView?id=000372249&language=en_US&type=3'),
('salesforce-sales-cloud','crm-sales-forecasting','supported',0.98,NULL,'https://help.salesforce.com/s/articleView?id=000372249&language=en_US&type=3'),
('salesforce-sales-cloud','crm-contact-account-management','supported',0.90,NULL,'https://help.salesforce.com/s/articleView?id=000372249&language=en_US&type=3'),

('dynamics-365-sales','crm-lead-management','supported',0.98,NULL,'https://learn.microsoft.com/en-us/dynamics365/release-plan/2026wave1/sales/dynamics365-sales/'),
('dynamics-365-sales','crm-opportunity-pipeline','supported',0.98,NULL,'https://www.microsoft.com/en-us/dynamics-365/products/sales'),
('dynamics-365-sales','crm-sales-automation','supported',0.95,'Automation and agent capabilities vary by configuration and release wave.','https://learn.microsoft.com/en-us/dynamics365/release-plan/2026wave1/sales/dynamics365-sales/'),
('dynamics-365-sales','crm-reports-dashboards','supported',0.90,NULL,'https://www.microsoft.com/en-us/dynamics-365/products/sales'),

('hubspot-sales-hub','crm-api-access','supported',0.98,'CRM API access and scopes depend on the app and account configuration.','https://developers.hubspot.com/docs/api-reference/latest/crm/understanding-the-crm'),
('hubspot-sales-hub','crm-sso','supported',0.98,'SSO availability depends on HubSpot subscription tier.','https://knowledge.hubspot.com/account-security/set-up-single-sign-on-sso'),
('hubspot-sales-hub','crm-contact-account-management','supported',0.95,NULL,'https://developers.hubspot.com/docs/api-reference/latest/crm/understanding-the-crm'),
('hubspot-sales-hub','crm-opportunity-pipeline','supported',0.95,'HubSpot CRM APIs include pipelines and deal records.','https://developers.hubspot.com/docs/api-reference/latest/crm/understanding-the-crm'),

('zoho-crm','crm-lead-management','supported',0.95,NULL,'https://www.zoho.com/crm/features.html'),
('zoho-crm','crm-opportunity-pipeline','supported',0.95,NULL,'https://www.zoho.com/crm/features.html'),
('zoho-crm','crm-sales-automation','supported',0.98,'Zoho documents workflow, cadence, Blueprint and journey automation.','https://www.zoho.com/crm/features.html'),
('zoho-crm','crm-reports-dashboards','supported',0.98,NULL,'https://www.zoho.com/crm/features.html'),
('zoho-crm','crm-api-access','supported',0.98,'REST, bulk, notification, query and GraphQL APIs are documented.','https://www.zoho.com/crm/developer/api.html'),

('freshsales','crm-contact-account-management','supported',0.95,NULL,'https://www.freshworks.com/crm/features/'),
('freshsales','crm-opportunity-pipeline','supported',0.95,NULL,'https://www.freshworks.com/crm/features/'),
('freshsales','crm-reports-dashboards','supported',0.90,NULL,'https://www.freshworks.com/crm/features/'),
('freshsales','crm-api-access','supported',0.95,'API access follows Freshworks authentication and user permission scope.','https://developers.freshworks.com/crm/api/'),

('pipedrive','crm-opportunity-pipeline','supported',0.98,NULL,'https://www.pipedrive.com/en/crm/features'),
('pipedrive','crm-sales-automation','supported',0.95,NULL,'https://www.pipedrive.com/en/crm/features'),
('pipedrive','crm-reports-dashboards','supported',0.95,'Pipedrive documents real-time analytics and custom reporting.','https://www.pipedrive.com/en/crm/features'),
('pipedrive','crm-api-access','supported',0.99,'REST API access is documented across plans.','https://www.pipedrive.com/en/features/crm-api'),
('pipedrive','crm-sso','supported',0.98,'Pipedrive documents SAML single sign-on.','https://support.pipedrive.com/en/article/single-sign-on'),

('odoo-crm','crm-lead-management','supported',0.98,NULL,'https://www.odoo.com/app/crm'),
('odoo-crm','crm-opportunity-pipeline','supported',0.98,NULL,'https://www.odoo.com/app/crm'),
('odoo-crm','crm-sales-automation','supported',0.95,'Odoo documents automated lead creation, assignment and scheduled activities.','https://www.odoo.com/app/crm'),
('odoo-crm','crm-sales-forecasting','supported',0.95,NULL,'https://www.odoo.com/app/crm'),
('odoo-crm','crm-reports-dashboards','supported',0.95,NULL,'https://www.odoo.com/app/crm'),
('odoo-crm','crm-api-access','supported',0.95,'External API access is plan-dependent on hosted Odoo and the current JSON-2 API replaces older RPC APIs.','https://www.odoo.com/documentation/19.0/developer/reference/external_api.html');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM crm9_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,c.id,NULL,'not_yet_verified',0
FROM products p CROSS JOIN capabilities c JOIN modules m ON m.id=c.module_id
WHERE p.slug IN('salesforce-sales-cloud','dynamics-365-sales','hubspot-sales-hub','zoho-crm','freshsales','pipedrive','odoo-crm')
AND m.category_id=@cat_id
AND NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,f.limitations
FROM crm9_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.95 FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug IN('salesforce-sales-cloud','dynamics-365-sales','hubspot-sales-hub','zoho-crm','freshsales','pipedrive','odoo-crm')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

-- Odoo can also be self-hosted/on-premise; keep confidence lower because implementation/version details matter.
INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.90 FROM products p JOIN deployment_models d ON d.slug IN('self-hosted','on-premise') WHERE p.slug='odoo-crm'
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

-- API integration-level facts for the integration comparison pages. Unknown remains explicit where not verified in this batch.
INSERT INTO product_integrations(product_id,integration_id,support_status,confidence_score)
SELECT p.id,i.id,
CASE
 WHEN i.slug='api' AND p.slug IN('hubspot-sales-hub','zoho-crm','freshsales','pipedrive','odoo-crm') THEN 'supported'
 WHEN i.slug='microsoft-365' AND p.slug='dynamics-365-sales' THEN 'supported'
 ELSE 'not_yet_verified' END,
CASE
 WHEN i.slug='api' AND p.slug IN('hubspot-sales-hub','zoho-crm','freshsales','pipedrive','odoo-crm') THEN 0.95
 WHEN i.slug='microsoft-365' AND p.slug='dynamics-365-sales' THEN 0.95
 ELSE 0 END
FROM products p JOIN integrations i
WHERE p.slug IN('salesforce-sales-cloud','dynamics-365-sales','hubspot-sales-hub','zoho-crm','freshsales','pipedrive','odoo-crm')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

COMMIT;
