-- TechSelectAI catalog expansion: major existing categories batch 2
-- Adds seven recognizable products to existing categories using official first-party evidence reviewed in Sep 2026.
-- Reuses existing taxonomy and preserves Unknown != Unsupported.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('ManageEngine','manageengine','https://www.manageengine.com/','IT management and service-management software vendor.','active'),
('UKG','ukg','https://www.ukg.com/','Human capital and workforce management software vendor.','active'),
('Epicor','epicor','https://www.epicor.com/','Enterprise resource planning and industry software vendor.','active'),
('Teamwork.com','teamwork-com','https://www.teamwork.com/','Project management and client-work software vendor.','active'),
('ThoughtSpot','thoughtspot','https://www.thoughtspot.com/','Business intelligence and analytics software vendor.','active'),
('Trend Micro','trend-micro','https://www.trendmicro.com/','Cybersecurity software vendor.','active'),
('Druva','druva','https://www.druva.com/','SaaS data resilience, backup and cyber recovery vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat74_products;
CREATE TEMPORARY TABLE cat74_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO cat74_products VALUES
('manageengine','itsm','ManageEngine ServiceDesk Plus','manageengine-servicedesk-plus','IT service management platform for incident, request, problem, change, knowledge, asset and configuration management with automation and reporting.','https://www.manageengine.com/products/service-desk/'),
('ukg','hr-hcm','UKG Pro','ukg-pro','Human capital management suite for core HR, payroll, talent, time and attendance, workforce management and analytics.','https://www.ukg.com/products/ukg-pro'),
('epicor','erp','Epicor Kinetic','epicor-kinetic','Manufacturing-focused ERP for financials, supply chain, planning, manufacturing, projects, analytics and workflow automation.','https://www.epicor.com/en-us/products/enterprise-resource-planning-erp/kinetic/'),
('teamwork-com','project-management','Teamwork.com','teamwork-com','Project management platform for client work with tasks, timelines, dependencies, workflows, automations, reporting and collaboration.','https://www.teamwork.com/product/project-management/'),
('thoughtspot','business-intelligence-analytics','ThoughtSpot Analytics','thoughtspot-analytics','Self-service analytics platform with interactive Liveboards, natural-language exploration and governed enterprise analytics.','https://www.thoughtspot.com/product/analytics'),
('trend-micro','endpoint-security','Trend Vision One Endpoint Security','trend-vision-one-endpoint-security','Enterprise endpoint security with broad endpoint protection, EDR/XDR, centralized visibility and threat response.','https://www.trendmicro.com/en_us/business/products/endpoint-security.html'),
('druva','backup-disaster-recovery','Druva Data Resilience Cloud','druva-data-resilience-cloud','SaaS data resilience platform for backup, restore, disaster recovery, ransomware recovery and protection across SaaS, endpoint, cloud and data-center workloads.','https://www.druva.com/products/resilience-cloud/platform-overview');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat74_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',x.url,x.title,x.publisher,1,'verified','high',NOW()
FROM products p JOIN (
 SELECT 'manageengine-servicedesk-plus' product_slug,'https://www.manageengine.com/products/service-desk/cloud/' url,'ServiceDesk Plus Cloud features' title,'ManageEngine' publisher UNION ALL
 SELECT 'manageengine-servicedesk-plus','https://www.manageengine.com/products/service-desk/itsm/configuration-management-database.html','ServiceDesk Plus CMDB','ManageEngine' UNION ALL
 SELECT 'manageengine-servicedesk-plus','https://www.manageengine.com/products/service-desk/it-asset-management/asset-tracking-software.html','ServiceDesk Plus IT Asset Management','ManageEngine' UNION ALL
 SELECT 'ukg-pro','https://www.ukg.com/products/ukg-pro','UKG Pro Human Capital Management','UKG' UNION ALL
 SELECT 'ukg-pro','https://www.ukg.com/products/ukg-pro-workforce-management','UKG Pro Workforce Management','UKG' UNION ALL
 SELECT 'epicor-kinetic','https://www.epicor.com/en-us/products/enterprise-resource-planning-erp/kinetic/','Epicor Kinetic','Epicor' UNION ALL
 SELECT 'epicor-kinetic','https://www.epicor.com/en-us/products/enterprise-resource-planning-erp/kinetic/financial-management/','Epicor Kinetic Financial Management','Epicor' UNION ALL
 SELECT 'epicor-kinetic','https://www.epicor.com/en-us/products/enterprise-resource-planning-erp/kinetic/production-management/','Epicor Kinetic Production Management','Epicor' UNION ALL
 SELECT 'teamwork-com','https://www.teamwork.com/product/project-management/','Teamwork Project Management','Teamwork.com' UNION ALL
 SELECT 'thoughtspot-analytics','https://www.thoughtspot.com/product/analytics','ThoughtSpot Analytics','ThoughtSpot' UNION ALL
 SELECT 'trend-vision-one-endpoint-security','https://www.trendmicro.com/en_us/business/products/endpoint-security.html','Trend Vision One Endpoint Security','Trend Micro' UNION ALL
 SELECT 'trend-vision-one-endpoint-security','https://docs.trendmicro.com/en-us/documentation/trend-vision-one/','Trend Vision One Documentation','Trend Micro' UNION ALL
 SELECT 'druva-data-resilience-cloud','https://www.druva.com/products/resilience-cloud/platform-overview','Druva Data Resilience Cloud Platform Overview','Druva'
) x ON x.product_slug=p.slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=x.url);

DROP TEMPORARY TABLE IF EXISTS cat74_facts;
CREATE TEMPORARY TABLE cat74_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat74_facts VALUES
-- ManageEngine ServiceDesk Plus
('manageengine-servicedesk-plus','itsm-incident-management','supported',0.99,NULL,'https://www.manageengine.com/products/service-desk/cloud/'),
('manageengine-servicedesk-plus','itsm-request-service-catalog','supported',0.99,'Service catalog availability depends on edition and deployment.','https://www.manageengine.com/products/service-desk/cloud/'),
('manageengine-servicedesk-plus','itsm-problem-management','supported',0.99,'Problem management is documented as an ITSM capability; edition availability varies.','https://www.manageengine.com/products/service-desk/cloud/'),
('manageengine-servicedesk-plus','itsm-change-management','supported',0.99,'Change enablement is documented; edition availability varies.','https://www.manageengine.com/products/service-desk/cloud/'),
('manageengine-servicedesk-plus','itsm-knowledge-management','supported',0.98,NULL,'https://www.manageengine.com/products/service-desk/itsm/configuration-management-database.html'),
('manageengine-servicedesk-plus','itsm-asset-management','supported',0.99,'IT asset management depth varies by edition.','https://www.manageengine.com/products/service-desk/it-asset-management/asset-tracking-software.html'),
('manageengine-servicedesk-plus','itsm-cmdb','supported',0.99,'CMDB availability varies by edition.','https://www.manageengine.com/products/service-desk/itsm/configuration-management-database.html'),
('manageengine-servicedesk-plus','itsm-reports-dashboards','supported',0.98,NULL,'https://www.manageengine.com/products/service-desk/cloud/'),

-- UKG Pro
('ukg-pro','hr-core-employee-records','supported',0.99,'UKG Pro centralizes workforce people data in its HCM suite.','https://www.ukg.com/products/ukg-pro'),
('ukg-pro','hr-learning-development','supported',0.95,'Talent capabilities include continuous learning and employee development.','https://www.ukg.com/products/ukg-pro'),
('ukg-pro','hr-time-attendance','supported',0.99,NULL,'https://www.ukg.com/products/ukg-pro'),
('ukg-pro','hr-payroll','supported',0.99,'Payroll country and service coverage varies by market and licensed scope.','https://www.ukg.com/products/ukg-pro'),
('ukg-pro','hr-reports-analytics','supported',0.95,'UKG Pro provides AI-driven workforce insights, reporting and analytics capabilities.','https://www.ukg.com/products/ukg-pro'),

-- Epicor Kinetic
('epicor-kinetic','erp-financial-accounting','supported',0.99,NULL,'https://www.epicor.com/en-us/products/enterprise-resource-planning-erp/kinetic/financial-management/'),
('epicor-kinetic','erp-ap-ar','supported',0.99,'Kinetic Financial Management explicitly documents AP and AR.','https://www.epicor.com/en-us/products/enterprise-resource-planning-erp/kinetic/financial-management/'),
('epicor-kinetic','erp-budgeting-planning','supported',0.98,'Budgeting, financial planning and forecasting are documented.','https://www.epicor.com/en-us/products/enterprise-resource-planning-erp/kinetic/financial-management/'),
('epicor-kinetic','erp-procurement','supported',0.92,'Kinetic documents sourcing and supply-chain execution; detailed procurement scope should be confirmed for the licensed configuration.','https://www.epicor.com/en-us/products/enterprise-resource-planning-erp/kinetic/'),
('epicor-kinetic','erp-supply-chain-planning','supported',0.99,'Forecasting, MRP, advanced planning and scheduling are documented.','https://www.epicor.com/en-us/products/enterprise-resource-planning-erp/kinetic/'),
('epicor-kinetic','erp-manufacturing','supported',0.99,NULL,'https://www.epicor.com/en-us/products/enterprise-resource-planning-erp/kinetic/production-management/'),
('epicor-kinetic','erp-project-operations','supported',0.95,'Epicor documents project accounting and project-oriented financial operations.','https://www.epicor.com/en-us/products/enterprise-resource-planning-erp/kinetic/financial-management/'),
('epicor-kinetic','erp-reports-dashboards','supported',0.99,'Built-in dashboards, reports and business intelligence are documented.','https://www.epicor.com/en-us/products/enterprise-resource-planning-erp/kinetic/'),
('epicor-kinetic','erp-workflow-automation','supported',0.95,'Financial and operational workflow automation is documented.','https://www.epicor.com/en-us/products/enterprise-resource-planning-erp/kinetic/financial-management/'),

-- Teamwork.com
('teamwork-com','pm-task-project-management','supported',0.99,NULL,'https://www.teamwork.com/product/project-management/'),
('teamwork-com','pm-timeline-schedule','supported',0.99,'Timeline, calendar and Gantt views are documented.','https://www.teamwork.com/product/project-management/'),
('teamwork-com','pm-dependencies-milestones','supported',0.99,NULL,'https://www.teamwork.com/product/project-management/'),
('teamwork-com','pm-workflow-automation','supported',0.99,'Workflows, triggers, automations and reminders are documented.','https://www.teamwork.com/product/project-management/'),
('teamwork-com','pm-dashboards-reporting','supported',0.99,'Project health, utilization and status reports are documented.','https://www.teamwork.com/product/project-management/'),
('teamwork-com','pm-team-collaboration','supported',0.99,'Comments, files, client collaboration and activity logs are documented.','https://www.teamwork.com/product/project-management/'),

-- ThoughtSpot Analytics
('thoughtspot-analytics','bi-dashboards-reports','supported',0.99,'ThoughtSpot Liveboards provide interactive, real-time analytical views.','https://www.thoughtspot.com/product/analytics'),
('thoughtspot-analytics','bi-self-service','supported',0.99,'Self-service analytics is explicitly documented as a core platform capability.','https://www.thoughtspot.com/product/analytics'),
('thoughtspot-analytics','bi-data-visualization','supported',0.98,'Interactive visual analytics and drill-down exploration are documented.','https://www.thoughtspot.com/product/analytics'),
('thoughtspot-analytics','bi-governance','supported',0.90,'ThoughtSpot positions the platform as enterprise-grade and governed; implementation-specific access controls should be verified separately.','https://www.thoughtspot.com/product/analytics'),

-- Trend Vision One Endpoint Security
('trend-vision-one-endpoint-security','endpoint-malware-ransomware','supported',0.95,'Endpoint Security provides layered endpoint protection against threats; exact controls vary by licensed services.','https://www.trendmicro.com/en_us/business/products/endpoint-security.html'),
('trend-vision-one-endpoint-security','endpoint-edr','supported',0.99,'Native EDR and XDR are explicitly documented.','https://www.trendmicro.com/en_us/business/products/endpoint-security.html'),
('trend-vision-one-endpoint-security','endpoint-central-management','supported',0.99,'Trend Vision One provides centralized endpoint visibility and management.','https://www.trendmicro.com/en_us/business/products/endpoint-security.html'),
('trend-vision-one-endpoint-security','endpoint-cross-platform','supported',0.95,'Official materials describe broad endpoint coverage across servers, endpoints, IoT and legacy environments; exact OS support should be checked for deployment.','https://www.trendmicro.com/en_us/business/products/endpoint-security.html'),

-- Druva Data Resilience Cloud
('druva-data-resilience-cloud','backup-core','supported',0.99,'Druva documents backup and restore from a unified SaaS platform.','https://www.druva.com/products/resilience-cloud/platform-overview'),
('druva-data-resilience-cloud','backup-cloud-saas','supported',0.99,'Druva documents protection across SaaS apps, cloud workloads, endpoints and data-center workloads.','https://www.druva.com/products/resilience-cloud/platform-overview'),
('druva-data-resilience-cloud','backup-ransomware-resilience','supported',0.99,'Air-gapped immutable protection and ransomware response/recovery are documented.','https://www.druva.com/products/resilience-cloud/platform-overview'),
('druva-data-resilience-cloud','backup-disaster-recovery-capability','supported',0.99,'Backup, restore and disaster recovery are explicitly documented.','https://www.druva.com/products/resilience-cloud/platform-overview'),
('druva-data-resilience-cloud','backup-central-management','supported',0.99,'Druva documents unified management from a single SaaS platform.','https://www.druva.com/products/resilience-cloud/platform-overview'),
('druva-data-resilience-cloud','backup-hybrid-multicloud','supported',0.99,'Druva documents protection across cloud, on-premises and edge environments.','https://www.druva.com/products/resilience-cloud/platform-overview');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat74_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat74_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,f.limitations
FROM cat74_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Deployment assertions are limited to deployment models directly represented by official product materials.
INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.95
FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug IN('manageengine-servicedesk-plus','ukg-pro','epicor-kinetic','teamwork-com','thoughtspot-analytics','trend-vision-one-endpoint-security','druva-data-resilience-cloud')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.95
FROM products p JOIN deployment_models d ON d.slug='on-premise'
WHERE p.slug IN('manageengine-servicedesk-plus','epicor-kinetic')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

-- No integration support is inferred in this batch; preserve explicit unknowns until product-specific evidence is reviewed.
INSERT INTO product_integrations(product_id,integration_id,support_status,confidence_score)
SELECT p.id,i.id,'not_yet_verified',0
FROM products p JOIN integrations i
WHERE p.slug IN('manageengine-servicedesk-plus','ukg-pro','epicor-kinetic','teamwork-com','thoughtspot-analytics','trend-vision-one-endpoint-security','druva-data-resilience-cloud')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

DROP TEMPORARY TABLE IF EXISTS cat74_facts;
DROP TEMPORARY TABLE IF EXISTS cat74_products;
COMMIT;
