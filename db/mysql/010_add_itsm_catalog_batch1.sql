-- TechSelectAI catalog expansion: ITSM batch 1
-- Adds ServiceNow ITSM, Jira Service Management, Freshservice, ManageEngine ServiceDesk Plus,
-- Zendesk and SysAid using official vendor documentation reviewed in Sep 2026.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('IT Service Management','itsm','IT service management and service desk software for incidents, requests, problems, changes, knowledge, assets, configuration and service operations.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @cat_id=(SELECT id FROM categories WHERE slug='itsm' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@cat_id,'Service Desk & Requests','itsm-service-desk','Incident, request, service catalog and SLA workflows.',1),
(@cat_id,'Problem, Change & Knowledge','itsm-governance','Problem, change and knowledge management practices.',1),
(@cat_id,'Assets & Configuration','itsm-assets-configuration','Asset lifecycle, CMDB and configuration management.',1),
(@cat_id,'Automation, Analytics & Enterprise','itsm-automation-enterprise','Workflow automation, reporting, APIs and enterprise access.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.security,1
FROM modules m JOIN (
 SELECT 'itsm-service-desk' module_slug,'Incident management' name,'itsm-incident-management' slug,'Log, prioritize, route, investigate and resolve IT incidents.' description,0 security UNION ALL
 SELECT 'itsm-service-desk','Request management / service catalog','itsm-request-service-catalog','Provide a portal or catalog for employee service requests and fulfillment.',0 UNION ALL
 SELECT 'itsm-service-desk','SLA management','itsm-sla-management','Define, monitor and escalate service-level targets.',0 UNION ALL
 SELECT 'itsm-governance','Problem management','itsm-problem-management','Identify root causes and manage recurring or underlying problems.',0 UNION ALL
 SELECT 'itsm-governance','Change management','itsm-change-management','Assess, approve, schedule and govern changes.',0 UNION ALL
 SELECT 'itsm-governance','Knowledge management','itsm-knowledge-management','Create and publish knowledge articles for agents and self-service.',0 UNION ALL
 SELECT 'itsm-assets-configuration','IT asset management','itsm-asset-management','Track IT assets, ownership and lifecycle.',0 UNION ALL
 SELECT 'itsm-assets-configuration','CMDB / configuration management','itsm-cmdb','Track configuration items, relationships and service dependencies.',0 UNION ALL
 SELECT 'itsm-automation-enterprise','Workflow automation','itsm-workflow-automation','Automate routing, approvals, escalations and service workflows.',0 UNION ALL
 SELECT 'itsm-automation-enterprise','Reports & dashboards','itsm-reports-dashboards','Operational reporting, dashboards and service analytics.',0 UNION ALL
 SELECT 'itsm-automation-enterprise','API access','itsm-api-access','Vendor-supported API access for integrations and automation.',0 UNION ALL
 SELECT 'itsm-automation-enterprise','Single sign-on (SSO)','itsm-sso','Enterprise single sign-on for service management users.',1
) x ON x.module_slug=m.slug
WHERE m.category_id=@cat_id
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('ServiceNow','servicenow','https://www.servicenow.com/','Enterprise workflow, IT service management and operations platform vendor.','active'),
('Atlassian','atlassian','https://www.atlassian.com/','Collaboration, development and service management software vendor.','active'),
('Freshworks','freshworks','https://www.freshworks.com/','Customer and employee software vendor.','active'),
('ManageEngine','manageengine','https://www.manageengine.com/','Enterprise IT management software vendor.','active'),
('Zendesk','zendesk','https://www.zendesk.com/','Customer and employee service software vendor.','active'),
('SysAid','sysaid','https://www.sysaid.com/','IT service management and service desk software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,@cat_id,x.name,x.slug,x.description,x.url,'active',NOW()
FROM vendors v JOIN (
 SELECT 'servicenow' vendor_slug,'ServiceNow ITSM' name,'servicenow-itsm' slug,'Enterprise IT service management for incident, request, problem, change, knowledge and service operations on the ServiceNow AI Platform.' description,'https://www.servicenow.com/products/itsm.html' url UNION ALL
 SELECT 'atlassian','Jira Service Management','jira-service-management','Atlassian service management for requests, incidents, problems, changes, knowledge, assets and configuration management.','https://www.atlassian.com/software/jira/service-management' UNION ALL
 SELECT 'freshworks','Freshservice','freshservice','Cloud IT service management with incident, problem, change, knowledge, asset, CMDB, automation and analytics capabilities.','https://www.freshworks.com/freshservice/' UNION ALL
 SELECT 'manageengine','ManageEngine ServiceDesk Plus','manageengine-servicedesk-plus','IT and enterprise service management with incident, request, problem, change, asset, CMDB and service catalog capabilities.','https://www.manageengine.com/products/service-desk/' UNION ALL
 SELECT 'zendesk','Zendesk','zendesk','Service and support platform with ticketing, knowledge, workflow automation, APIs and IT asset management capabilities for employee service use cases.','https://www.zendesk.com/' UNION ALL
 SELECT 'sysaid','SysAid','sysaid','IT service management platform with incidents, requests, problems, changes, assets, automation and API extensibility.','https://www.sysaid.com/'
) x ON x.vendor_slug=v.slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

-- Official vendor evidence sources.
INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',x.url,x.title,x.publisher,1,'verified','high',NOW()
FROM products p JOIN (
 SELECT 'servicenow-itsm' product_slug,'https://www.servicenow.com/products/itsm.html' url,'ServiceNow IT Service Management' title,'ServiceNow' publisher UNION ALL
 SELECT 'servicenow-itsm','https://www.servicenow.com/products/itsm/pricing.html','ServiceNow ITSM packages and capabilities','ServiceNow' UNION ALL
 SELECT 'jira-service-management','https://www.atlassian.com/software/jira/service-management/features','Jira Service Management features','Atlassian' UNION ALL
 SELECT 'jira-service-management','https://www.atlassian.com/software/jira/service-management/features/itsm','Jira Service Management ITSM features','Atlassian' UNION ALL
 SELECT 'freshservice','https://www.freshworks.com/freshservice/features/','Freshservice features','Freshworks' UNION ALL
 SELECT 'freshservice','https://www.freshworks.com/freshservice/features/incident-management/','Freshservice incident management','Freshworks' UNION ALL
 SELECT 'manageengine-servicedesk-plus','https://www.manageengine.com/products/service-desk/','ServiceDesk Plus','ManageEngine' UNION ALL
 SELECT 'manageengine-servicedesk-plus','https://www.manageengine.com/products/service-desk/support.html','ServiceDesk Plus features and support','ManageEngine' UNION ALL
 SELECT 'zendesk','https://developer.zendesk.com/api-reference/ticketing/introduction/','Zendesk Ticketing API','Zendesk' UNION ALL
 SELECT 'zendesk','https://developer.zendesk.com/api-reference/it-asset-management/introduction/','Zendesk IT Asset Management API','Zendesk' UNION ALL
 SELECT 'sysaid','https://documentation.sysaid.com/docs/guide-to-sysaid-change-management-and-problem-management','SysAid Change and Problem Management','SysAid' UNION ALL
 SELECT 'sysaid','https://developers.sysaid.com/','SysAid Developers API','SysAid' UNION ALL
 SELECT 'sysaid','https://developers.sysaid.com/reference/assets-1','SysAid Assets API','SysAid'
) x ON x.product_slug=p.slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=x.url);

DROP TEMPORARY TABLE IF EXISTS itsm10_facts;
CREATE TEMPORARY TABLE itsm10_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO itsm10_facts VALUES
-- ServiceNow ITSM
('servicenow-itsm','itsm-incident-management','supported',0.99,NULL,'https://www.servicenow.com/products/itsm.html'),
('servicenow-itsm','itsm-request-service-catalog','supported',0.99,NULL,'https://www.servicenow.com/products/itsm.html'),
('servicenow-itsm','itsm-problem-management','supported',0.99,NULL,'https://www.servicenow.com/products/itsm/pricing.html'),
('servicenow-itsm','itsm-change-management','supported',0.99,NULL,'https://www.servicenow.com/products/itsm/pricing.html'),
('servicenow-itsm','itsm-knowledge-management','supported',0.95,NULL,'https://www.servicenow.com/products/itsm.html'),
('servicenow-itsm','itsm-asset-management','supported',0.95,'Asset Management and CMDB are included in current ITSM package descriptions; exact depth varies by package and adjacent ServiceNow products.','https://www.servicenow.com/products/itsm/pricing.html'),
('servicenow-itsm','itsm-cmdb','supported',0.98,NULL,'https://www.servicenow.com/products/itsm/pricing.html'),
('servicenow-itsm','itsm-workflow-automation','supported',0.98,'Automation depth and autonomous/AI features vary by ITSM package.','https://www.servicenow.com/products/itsm.html'),
('servicenow-itsm','itsm-reports-dashboards','supported',0.90,'Advanced analytics capabilities vary by package.','https://www.servicenow.com/products/itsm/pricing.html'),

-- Jira Service Management
('jira-service-management','itsm-incident-management','supported',0.99,NULL,'https://www.atlassian.com/software/jira/service-management/features'),
('jira-service-management','itsm-request-service-catalog','supported',0.98,NULL,'https://www.atlassian.com/software/jira/service-management/features'),
('jira-service-management','itsm-problem-management','supported',0.99,NULL,'https://www.atlassian.com/software/jira/service-management/features/itsm'),
('jira-service-management','itsm-change-management','supported',0.99,NULL,'https://www.atlassian.com/software/jira/service-management/features/itsm'),
('jira-service-management','itsm-knowledge-management','supported',0.98,'Knowledge workflows are integrated with Atlassian knowledge capabilities and may depend on plan/configuration.','https://www.atlassian.com/software/jira/service-management/features'),
('jira-service-management','itsm-asset-management','supported',0.99,NULL,'https://www.atlassian.com/software/jira/service-management/features/itsm'),
('jira-service-management','itsm-cmdb','supported',0.98,'Atlassian Assets provides asset and configuration management; availability depends on plan.','https://www.atlassian.com/software/jira/service-management/features/itsm'),
('jira-service-management','itsm-workflow-automation','supported',0.98,NULL,'https://www.atlassian.com/software/jira/service-management/features'),
('jira-service-management','itsm-api-access','supported',0.98,'Jira Service Management provides REST APIs and an open platform; specific API availability depends on feature and deployment.','https://www.atlassian.com/software/jira/service-management/features'),

-- Freshservice
('freshservice','itsm-incident-management','supported',0.99,NULL,'https://www.freshworks.com/freshservice/features/'),
('freshservice','itsm-request-service-catalog','supported',0.99,NULL,'https://www.freshworks.com/freshservice/features/'),
('freshservice','itsm-problem-management','supported',0.99,NULL,'https://www.freshworks.com/freshservice/features/'),
('freshservice','itsm-change-management','supported',0.99,NULL,'https://www.freshworks.com/freshservice/features/'),
('freshservice','itsm-knowledge-management','supported',0.98,NULL,'https://www.freshworks.com/freshservice/features/'),
('freshservice','itsm-asset-management','supported',0.99,NULL,'https://www.freshworks.com/freshservice/features/'),
('freshservice','itsm-cmdb','supported',0.98,'Freshservice documents an integrated CMDB with discovery and dependency mapping; depth may vary by plan.','https://www.freshworks.com/freshservice/features/'),
('freshservice','itsm-workflow-automation','supported',0.99,NULL,'https://www.freshworks.com/freshservice/features/'),
('freshservice','itsm-sla-management','supported',0.98,NULL,'https://www.freshworks.com/freshservice/features/'),
('freshservice','itsm-reports-dashboards','supported',0.98,NULL,'https://www.freshworks.com/freshservice/features/'),

-- ManageEngine ServiceDesk Plus
('manageengine-servicedesk-plus','itsm-incident-management','supported',0.99,NULL,'https://www.manageengine.com/products/service-desk/support.html'),
('manageengine-servicedesk-plus','itsm-request-service-catalog','supported',0.98,NULL,'https://www.manageengine.com/products/service-desk/support.html'),
('manageengine-servicedesk-plus','itsm-problem-management','supported',0.99,'Problem management is available in higher editions; confirm edition requirements.','https://www.manageengine.com/products/service-desk/support.html'),
('manageengine-servicedesk-plus','itsm-change-management','supported',0.99,'Change enablement is available in higher editions; confirm edition requirements.','https://www.manageengine.com/products/service-desk/support.html'),
('manageengine-servicedesk-plus','itsm-knowledge-management','supported',0.95,NULL,'https://www.manageengine.com/products/service-desk/'),
('manageengine-servicedesk-plus','itsm-asset-management','supported',0.99,'IT asset management availability varies by edition.','https://www.manageengine.com/products/service-desk/support.html'),
('manageengine-servicedesk-plus','itsm-cmdb','supported',0.98,'CMDB is part of the Enterprise edition in current public packaging.','https://www.manageengine.com/products/service-desk/support.html'),
('manageengine-servicedesk-plus','itsm-reports-dashboards','supported',0.95,NULL,'https://www.manageengine.com/products/service-desk/support.html'),

-- Zendesk: strong service/ticketing, knowledge, API and ITAM evidence; do not infer full ITIL problem/change coverage.
('zendesk','itsm-incident-management','supported',0.90,'TechSelectAI maps Zendesk ticketing to incident/service-ticket handling; this does not imply full ITIL incident-management depth equivalent to dedicated ITSM suites.','https://developer.zendesk.com/api-reference/ticketing/introduction/'),
('zendesk','itsm-request-service-catalog','partially_supported',0.75,'Zendesk supports ticket/request workflows, but a dedicated IT service catalog was not verified in this evidence batch.','https://developer.zendesk.com/api-reference/ticketing/introduction/'),
('zendesk','itsm-knowledge-management','supported',0.95,'Zendesk Help Center provides knowledge-base capabilities; plan/configuration should be confirmed.','https://developer.zendesk.com/api-reference/'),
('zendesk','itsm-asset-management','supported',0.95,'Zendesk IT asset management is plan-dependent and documented for employee services.','https://developer.zendesk.com/api-reference/it-asset-management/introduction/'),
('zendesk','itsm-workflow-automation','supported',0.90,'Ticket workflows can be automated through Zendesk ticketing capabilities and APIs.','https://developer.zendesk.com/api-reference/ticketing/introduction/'),
('zendesk','itsm-api-access','supported',0.99,NULL,'https://developer.zendesk.com/api-reference/ticketing/introduction/'),

-- SysAid
('sysaid','itsm-incident-management','supported',0.95,NULL,'https://documentation.sysaid.com/'),
('sysaid','itsm-problem-management','supported',0.99,NULL,'https://documentation.sysaid.com/docs/guide-to-sysaid-change-management-and-problem-management'),
('sysaid','itsm-change-management','supported',0.99,NULL,'https://documentation.sysaid.com/docs/guide-to-sysaid-change-management-and-problem-management'),
('sysaid','itsm-asset-management','supported',0.99,NULL,'https://developers.sysaid.com/reference/assets-1'),
('sysaid','itsm-api-access','supported',0.99,'SysAid Connect API supports integration and custom workflow use cases; endpoint coverage should be checked for the specific requirement.','https://developers.sysaid.com/');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM itsm10_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

-- Explicit unknown rows preserve Unknown != Unsupported for unreviewed capabilities.
INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,c.id,NULL,'not_yet_verified',0
FROM products p CROSS JOIN capabilities c JOIN modules m ON m.id=c.module_id
WHERE p.slug IN('servicenow-itsm','jira-service-management','freshservice','manageengine-servicedesk-plus','zendesk','sysaid')
AND m.category_id=@cat_id
AND NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,f.limitations
FROM itsm10_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Public SaaS deployment for cloud products in this batch.
INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.95 FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug IN('servicenow-itsm','jira-service-management','freshservice','manageengine-servicedesk-plus','zendesk','sysaid')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

-- ServiceDesk Plus also has an officially offered on-premises edition.
INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.98 FROM products p JOIN deployment_models d ON d.slug='on-premise'
WHERE p.slug='manageengine-servicedesk-plus'
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

-- Integration-level facts used by public integration pages and recommendation dimensions.
-- Only mark API where reviewed official documentation in this batch explicitly supports it.
INSERT INTO product_integrations(product_id,integration_id,support_status,confidence_score)
SELECT p.id,i.id,
CASE
 WHEN i.slug='api' AND p.slug IN('jira-service-management','zendesk','sysaid') THEN 'supported'
 ELSE 'not_yet_verified' END,
CASE
 WHEN i.slug='api' AND p.slug='jira-service-management' THEN 0.98
 WHEN i.slug='api' AND p.slug='zendesk' THEN 0.99
 WHEN i.slug='api' AND p.slug='sysaid' THEN 0.99
 ELSE 0 END
FROM products p JOIN integrations i
WHERE p.slug IN('servicenow-itsm','jira-service-management','freshservice','manageengine-servicedesk-plus','zendesk','sysaid')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

COMMIT;
