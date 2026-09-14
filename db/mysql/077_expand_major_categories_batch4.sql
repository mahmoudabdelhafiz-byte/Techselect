-- TechSelectAI catalog expansion: major existing categories batch 4
-- Adds seven recognizable products to existing categories using official first-party evidence reviewed in Sep 2026.
-- Reuses existing taxonomy and preserves Unknown != Unsupported.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('SAP','sap','https://www.sap.com/','Enterprise application and business software vendor.','active'),
('SolarWinds','solarwinds','https://www.solarwinds.com/','IT operations and service-management software vendor.','active'),
('Dayforce','dayforce','https://www.dayforce.com/','Human capital management, payroll and workforce software vendor.','active'),
('Oracle','oracle','https://www.oracle.com/','Enterprise database, cloud and business application software vendor.','active'),
('Planview','planview','https://www.planview.com/','Portfolio, project and work management software vendor.','active'),
('IBM','ibm','https://www.ibm.com/','Enterprise technology and software vendor.','active'),
('Palo Alto Networks','palo-alto-networks','https://www.paloaltonetworks.com/','Enterprise cybersecurity software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat77_products;
CREATE TEMPORARY TABLE cat77_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO cat77_products VALUES
('sap','crm','SAP Sales Cloud','sap-sales-cloud','Enterprise sales CRM for account, contact, lead and opportunity management with guided selling, forecasting and sales analytics.','https://www.sap.com/products/crm/sales-cloud.html'),
('solarwinds','itsm','SolarWinds Service Desk','solarwinds-service-desk','Cloud IT service management platform for incidents, requests, problems, changes, knowledge, assets, CMDB, automation and reporting.','https://www.solarwinds.com/service-desk'),
('dayforce','hr-hcm','Dayforce','dayforce','Human capital management platform combining HR, payroll, time, talent and workforce analytics on a unified people platform.','https://www.dayforce.com/why-dayforce/dayforce-suite'),
('oracle','erp','Oracle NetSuite ERP','oracle-netsuite-erp','Cloud ERP covering financial management, purchasing, inventory, order operations, projects and business reporting.','https://www.netsuite.com/portal/products/erp.shtml'),
('planview','project-management','Planview AdaptiveWork','planview-adaptivework','Portfolio and work management platform for projects, resources, workflows, collaboration, reporting and portfolio visibility.','https://www.planview.com/products-solutions/products/adaptivework/'),
('ibm','business-intelligence-analytics','IBM Cognos Analytics','ibm-cognos-analytics','Governed business intelligence platform for reporting, dashboards, self-service analytics, visualization, forecasting and AI-assisted exploration.','https://www.ibm.com/products/cognos-analytics'),
('palo-alto-networks','endpoint-security','Cortex XDR','palo-alto-cortex-xdr','Endpoint security and extended detection and response platform combining prevention, behavioral detection, investigation and automated response.','https://www.paloaltonetworks.com/cortex/cortex-xdr');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat77_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',x.url,x.title,x.publisher,1,'verified','high',NOW()
FROM products p JOIN (
 SELECT 'sap-sales-cloud' product_slug,'https://www.sap.com/products/crm/sales-cloud/features.html' url,'SAP Sales Cloud Features' title,'SAP' publisher UNION ALL
 SELECT 'sap-sales-cloud','https://help.sap.com/docs/PRODUCT_ID/d6b1239c62d34c118fd2a59073358496/29cf7874113d4ea2ab0d8dfe599ca281.html','SAP Sales Cloud Version 2 Feature Scope','SAP' UNION ALL
 SELECT 'solarwinds-service-desk','https://www.solarwinds.com/service-desk','SolarWinds Service Desk','SolarWinds' UNION ALL
 SELECT 'solarwinds-service-desk','https://www.solarwinds.com/service-desk/use-cases','SolarWinds Service Desk Features','SolarWinds' UNION ALL
 SELECT 'solarwinds-service-desk','https://documentation.solarwinds.com/en/success_center/swsd/content/completeguidetoswsd/swsd-features.htm','SolarWinds Service Desk Documentation','SolarWinds' UNION ALL
 SELECT 'dayforce','https://www.dayforce.com/why-dayforce/dayforce-suite','Dayforce HCM Suite','Dayforce' UNION ALL
 SELECT 'dayforce','https://www.dayforce.com/how-we-help/dayforce/hrm-software','Dayforce HR Management Software','Dayforce' UNION ALL
 SELECT 'oracle-netsuite-erp','https://docs.oracle.com/en/cloud/saas/netsuite/ns-online-help/section_N129046.html','NetSuite ERP Documentation Summary','Oracle' UNION ALL
 SELECT 'oracle-netsuite-erp','https://docs.oracle.com/en/cloud/saas/netsuite/ns-online-help/chapter_N2399286.html','NetSuite Purchasing','Oracle' UNION ALL
 SELECT 'oracle-netsuite-erp','https://docs.oracle.com/en/cloud/saas/netsuite/ns-online-help/article_161970666917.html','NetSuite Inventory Management Overview','Oracle' UNION ALL
 SELECT 'planview-adaptivework','https://www.planview.com/products-solutions/products/adaptivework/','Planview AdaptiveWork','Planview' UNION ALL
 SELECT 'ibm-cognos-analytics','https://www.ibm.com/products/cognos-analytics/features','IBM Cognos Analytics Features','IBM' UNION ALL
 SELECT 'ibm-cognos-analytics','https://www.ibm.com/products/cognos-analytics','IBM Cognos Analytics','IBM' UNION ALL
 SELECT 'palo-alto-cortex-xdr','https://www.paloaltonetworks.com/cortex/cortex-xdr','Cortex XDR','Palo Alto Networks' UNION ALL
 SELECT 'palo-alto-cortex-xdr','https://www.paloaltonetworks.com/cortex/endpoint-detection-and-response','Cortex XDR Endpoint Detection and Response','Palo Alto Networks' UNION ALL
 SELECT 'palo-alto-cortex-xdr','https://www.paloaltonetworks.com/cortex/endpoint-protection','Cortex XDR Endpoint Protection','Palo Alto Networks'
) x ON x.product_slug=p.slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=x.url);

DROP TEMPORARY TABLE IF EXISTS cat77_facts;
CREATE TEMPORARY TABLE cat77_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat77_facts VALUES
-- SAP Sales Cloud
('sap-sales-cloud','crm-lead-management','supported',0.99,'SAP documents lead capture, qualification and conversion to opportunities.','https://help.sap.com/docs/PRODUCT_ID/d6b1239c62d34c118fd2a59073358496/29cf7874113d4ea2ab0d8dfe599ca281.html'),
('sap-sales-cloud','crm-contact-account-management','supported',0.99,'Accounts and contacts are explicitly included in the current feature scope.','https://help.sap.com/docs/PRODUCT_ID/d6b1239c62d34c118fd2a59073358496/29cf7874113d4ea2ab0d8dfe599ca281.html'),
('sap-sales-cloud','crm-opportunity-pipeline','supported',0.99,'SAP documents opportunity management and pipeline intelligence.','https://www.sap.com/products/crm/sales-cloud/features.html'),
('sap-sales-cloud','crm-sales-automation','supported',0.95,'Guided selling and AI-assisted next-best actions automate parts of sales execution.','https://www.sap.com/products/crm/sales-cloud/features.html'),
('sap-sales-cloud','crm-sales-forecasting','supported',0.99,'Pipeline and forecast intelligence are explicitly documented.','https://www.sap.com/products/crm/sales-cloud/features.html'),
('sap-sales-cloud','crm-reports-dashboards','supported',0.98,'Digital sales performance dashboards and pipeline intelligence are documented.','https://www.sap.com/products/crm/sales-cloud/features.html'),

-- SolarWinds Service Desk
('solarwinds-service-desk','itsm-incident-management','supported',0.99,NULL,'https://www.solarwinds.com/service-desk'),
('solarwinds-service-desk','itsm-request-service-catalog','supported',0.99,'Service catalog and service request capabilities are explicitly documented.','https://www.solarwinds.com/service-desk/use-cases'),
('solarwinds-service-desk','itsm-sla-management','supported',0.99,'Service level management is explicitly documented.','https://documentation.solarwinds.com/en/success_center/swsd/content/completeguidetoswsd/swsd-features.htm'),
('solarwinds-service-desk','itsm-problem-management','supported',0.99,NULL,'https://www.solarwinds.com/service-desk/use-cases'),
('solarwinds-service-desk','itsm-change-management','supported',0.99,NULL,'https://www.solarwinds.com/service-desk'),
('solarwinds-service-desk','itsm-knowledge-management','supported',0.99,'Knowledge base is listed among current service-management features.','https://www.solarwinds.com/service-desk/use-cases'),
('solarwinds-service-desk','itsm-asset-management','supported',0.99,'Integrated IT asset management is explicitly documented.','https://documentation.solarwinds.com/en/success_center/swsd/content/completeguidetoswsd/swsd-features.htm'),
('solarwinds-service-desk','itsm-cmdb','supported',0.99,'Integrated CMDB is explicitly documented.','https://www.solarwinds.com/service-desk/use-cases'),
('solarwinds-service-desk','itsm-workflow-automation','supported',0.99,'Automation and workflow engines are documented across service processes.','https://www.solarwinds.com/service-desk/use-cases'),
('solarwinds-service-desk','itsm-reports-dashboards','supported',0.98,'Reporting, dashboards and benchmarking are documented.','https://www.solarwinds.com/service-desk/use-cases'),

-- Dayforce
('dayforce','hr-core-employee-records','supported',0.99,'Dayforce HR provides a single reliable employee record and real-time workforce data.','https://www.dayforce.com/why-dayforce/dayforce-suite'),
('dayforce','hr-recruiting','supported',0.90,'Dayforce Talent is documented as helping organizations hire; detailed recruiting module scope should be confirmed.','https://www.dayforce.com/why-dayforce/dayforce-suite'),
('dayforce','hr-time-attendance','supported',0.99,'Time and workforce management are core parts of the Dayforce suite.','https://www.dayforce.com/why-dayforce/dayforce-suite'),
('dayforce','hr-payroll','supported',0.99,'Payroll is a core Dayforce suite capability.','https://www.dayforce.com/why-dayforce/dayforce-suite'),
('dayforce','hr-reports-analytics','supported',0.99,'Reporting and analytics are explicitly part of the unified Dayforce platform.','https://www.dayforce.com/why-dayforce/dayforce-suite'),

-- Oracle NetSuite ERP
('oracle-netsuite-erp','erp-financial-accounting','supported',0.99,'NetSuite ERP documentation covers accounting, financial statements, revenue recognition, tax and fixed assets.','https://docs.oracle.com/en/cloud/saas/netsuite/ns-online-help/section_N129046.html'),
('oracle-netsuite-erp','erp-ap-ar','supported',0.98,'ERP documentation covers billing, vendor bills, payments and accounting processes.','https://docs.oracle.com/en/cloud/saas/netsuite/ns-online-help/section_N129046.html'),
('oracle-netsuite-erp','erp-procurement','supported',0.99,'Purchase orders, vendors, approvals and receiving are explicitly documented.','https://docs.oracle.com/en/cloud/saas/netsuite/ns-online-help/chapter_N2399286.html'),
('oracle-netsuite-erp','erp-inventory-warehouse','supported',0.99,'Inventory management and warehouse processing are included in NetSuite inventory documentation.','https://docs.oracle.com/en/cloud/saas/netsuite/ns-online-help/article_161970666917.html'),
('oracle-netsuite-erp','erp-supply-chain-planning','supported',0.95,'Advanced inventory supports demand planning and replenishment; exact planning scope depends on enabled features.','https://docs.oracle.com/en/cloud/saas/netsuite/ns-online-help/article_161970666917.html'),
('oracle-netsuite-erp','erp-manufacturing','supported',0.90,'ERP documentation includes manufacturing within inventory and item operations; manufacturing depth depends on enabled features.','https://docs.oracle.com/en/cloud/saas/netsuite/ns-online-help/section_N129046.html'),
('oracle-netsuite-erp','erp-project-operations','supported',0.95,'NetSuite ERP documentation includes project management tasks and resources.','https://docs.oracle.com/en/cloud/saas/netsuite/ns-online-help/section_N129046.html'),
('oracle-netsuite-erp','erp-reports-dashboards','supported',0.95,'Financial, inventory and operational reporting are documented across ERP areas.','https://docs.oracle.com/en/cloud/saas/netsuite/ns-online-help/section_N129046.html'),

-- Planview AdaptiveWork
('planview-adaptivework','pm-task-project-management','supported',0.99,'AdaptiveWork manages projects, tasks and work across portfolios.','https://www.planview.com/products-solutions/products/adaptivework/'),
('planview-adaptivework','pm-project-portfolio','supported',0.99,'Portfolio management across teams, projects, departments and regions is explicitly documented.','https://www.planview.com/products-solutions/products/adaptivework/'),
('planview-adaptivework','pm-resource-workload','supported',0.99,'Capacity planning, resource demand and workload balancing are explicitly documented.','https://www.planview.com/products-solutions/products/adaptivework/'),
('planview-adaptivework','pm-workflow-automation','supported',0.98,'Configurable workflow processes, integrations and dynamic rules are documented.','https://www.planview.com/products-solutions/products/adaptivework/'),
('planview-adaptivework','pm-dashboards-reporting','supported',0.99,'Configurable reports and dashboards are explicitly documented.','https://www.planview.com/products-solutions/products/adaptivework/'),
('planview-adaptivework','pm-team-collaboration','supported',0.95,'Centralized communications and stakeholder collaboration features are documented.','https://www.planview.com/products-solutions/products/adaptivework/'),

-- IBM Cognos Analytics
('ibm-cognos-analytics','bi-dashboards-reports','supported',0.99,'Advanced reporting and interactive dashboards are core Cognos capabilities.','https://www.ibm.com/products/cognos-analytics/features'),
('ibm-cognos-analytics','bi-self-service','supported',0.99,'IBM documents self-service data modeling and exploration.','https://www.ibm.com/products/cognos-analytics/features'),
('ibm-cognos-analytics','bi-data-visualization','supported',0.99,'Interactive visualizations and dashboarding are explicitly documented.','https://www.ibm.com/products/cognos-analytics/features'),
('ibm-cognos-analytics','bi-data-connectivity','partially_supported',0.85,'Cognos supports analysis from selected data sources; connector breadth is not fully reviewed in this batch.','https://www.ibm.com/products/cognos-analytics/features'),
('ibm-cognos-analytics','bi-sharing-collaboration','supported',0.95,'Reports and dashboards can be distributed and shared, including email and Slack workflows.','https://www.ibm.com/products/cognos-analytics/features'),
('ibm-cognos-analytics','bi-governance','supported',0.99,'Centralized governance, audit trails and fine-grained access controls are explicitly documented.','https://www.ibm.com/products/cognos-analytics'),

-- Cortex XDR
('palo-alto-cortex-xdr','endpoint-malware-ransomware','supported',0.99,'Cortex XDR documents malware, zero-day and ransomware prevention.','https://www.paloaltonetworks.com/cortex/endpoint-protection'),
('palo-alto-cortex-xdr','endpoint-behavior-exploit','supported',0.99,'Behavioral threat protection and exploit prevention are explicitly documented.','https://www.paloaltonetworks.com/cortex/endpoint-protection'),
('palo-alto-cortex-xdr','endpoint-edr','supported',0.99,'Endpoint detection and response is a core Cortex XDR capability.','https://www.paloaltonetworks.com/cortex/endpoint-detection-and-response'),
('palo-alto-cortex-xdr','endpoint-central-management','supported',0.99,'A single web-based console centralizes endpoint policy, detection, investigation and response.','https://www.paloaltonetworks.com/cortex/endpoint-detection-and-response'),
('palo-alto-cortex-xdr','endpoint-automated-response','supported',0.99,'Native automation and flexible response actions are explicitly documented.','https://www.paloaltonetworks.com/cortex/cortex-xdr');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat77_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat77_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,f.limitations
FROM cat77_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Conservative deployment facts only where the current first-party product material is explicit.
INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.95 FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug IN('sap-sales-cloud','solarwinds-service-desk','dayforce','oracle-netsuite-erp','planview-adaptivework','ibm-cognos-analytics')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.99 FROM products p JOIN deployment_models d ON d.slug='on-premise'
WHERE p.slug='ibm-cognos-analytics'
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

-- Product-specific integration coverage is not reviewed in this batch; preserve explicit unknowns.
INSERT INTO product_integrations(product_id,integration_id,support_status,confidence_score)
SELECT p.id,i.id,'not_yet_verified',0 FROM products p JOIN integrations i
WHERE p.slug IN('sap-sales-cloud','solarwinds-service-desk','dayforce','oracle-netsuite-erp','planview-adaptivework','ibm-cognos-analytics','palo-alto-cortex-xdr')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

DROP TEMPORARY TABLE IF EXISTS cat77_facts;
DROP TEMPORARY TABLE IF EXISTS cat77_products;
COMMIT;
