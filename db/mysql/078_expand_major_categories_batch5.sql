-- TechSelectAI catalog expansion: major existing categories batch 5
-- Adds eight recognizable products to existing categories using official first-party evidence reviewed in Sep 2026.
-- Reuses existing taxonomy and preserves Unknown != Unsupported.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('SugarCRM','sugarcrm','https://www.sugarcrm.com/','Customer relationship management software vendor.','active'),
('TOPdesk','topdesk','https://www.topdesk.com/','IT service management and enterprise service management software vendor.','active'),
('Paylocity','paylocity','https://www.paylocity.com/','Human capital management, payroll and workforce software vendor.','active'),
('Acumatica','acumatica','https://www.acumatica.com/','Cloud ERP software vendor for mid-market organizations.','active'),
('Airtable','airtable','https://www.airtable.com/','Collaborative work management and application platform vendor.','active'),
('SAP','sap','https://www.sap.com/','Enterprise applications and analytics software vendor.','active'),
('Trellix','trellix','https://www.trellix.com/','Enterprise cybersecurity software vendor.','active'),
('NAKIVO','nakivo','https://www.nakivo.com/','Backup, replication and disaster recovery software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat78_products;
CREATE TEMPORARY TABLE cat78_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO cat78_products VALUES
('sugarcrm','crm','Sugar Sell','sugar-sell','B2B sales CRM for lead, account, contact, opportunity, pipeline, forecasting, workflow automation, analytics and extensibility.','https://www.sugarcrm.com/solutions/sugar-sell/'),
('topdesk','itsm','TOPdesk','topdesk','IT service management platform for incidents, requests, problems, changes, knowledge, assets, configuration visibility, reporting and integrations.','https://www.topdesk.com/en/solutions/it-service-management/'),
('paylocity','hr-hcm','Paylocity','paylocity','HCM platform for HR, payroll, recruiting, onboarding, performance, learning, time and labor, and employee experience.','https://www.paylocity.com/products/hr/'),
('acumatica','erp','Acumatica Cloud ERP','acumatica-cloud-erp','Cloud ERP platform for financials, distribution, manufacturing, project accounting, inventory and operational reporting.','https://www.acumatica.com/cloud-erp-software/'),
('airtable','project-management','Airtable','airtable','Collaborative project and work management platform with task tracking, timelines, dependencies, automation, reporting and shared workflows.','https://www.airtable.com/solutions/project-management'),
('sap','business-intelligence-analytics','SAP Analytics Cloud','sap-analytics-cloud','Cloud analytics and planning platform for business intelligence, self-service analytics, planning, governed data and AI-assisted insights.','https://www.sap.com/products/cloud-analytics.html'),
('trellix','endpoint-security','Trellix Endpoint Security','trellix-endpoint-security','Enterprise endpoint protection platform with multilayered prevention, exploit protection, centralized management, EDR-related capabilities and remediation.','https://www.trellix.com/products/endpoint-security/'),
('nakivo','backup-disaster-recovery','NAKIVO Backup & Replication','nakivo-backup-replication','Backup, replication and disaster recovery platform for virtual, physical, cloud and SaaS workloads with ransomware-resilience controls.','https://www.nakivo.com/backup-replication.html');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat78_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',x.url,x.title,x.publisher,1,'verified','high',NOW()
FROM products p JOIN (
 SELECT 'sugar-sell' product_slug,'https://www.sugarcrm.com/solutions/sugar-sell/' url,'Sugar Sell' title,'SugarCRM' publisher UNION ALL
 SELECT 'sugar-sell','https://support.sugarcrm.com/documentation/sugar_versions/25.1/sell/application_guide/introduction/','Sugar Sell 25.1 Application Guide Introduction','SugarCRM' UNION ALL
 SELECT 'sugar-sell','https://support.sugarcrm.com/documentation/sugar_versions/25.2/sell/application_guide/sugar_automate/','Sugar Automate','SugarCRM' UNION ALL
 SELECT 'topdesk','https://www.topdesk.com/en/solutions/it-service-management/','TOPdesk IT Service Management','TOPdesk' UNION ALL
 SELECT 'topdesk','https://www.topdesk.com/en/documentation-portal/','TOPdesk Documentation and API Portal','TOPdesk' UNION ALL
 SELECT 'paylocity','https://www.paylocity.com/products/','Paylocity Products','Paylocity' UNION ALL
 SELECT 'paylocity','https://www.paylocity.com/products/hr/','Paylocity HR Solutions','Paylocity' UNION ALL
 SELECT 'paylocity','https://www.paylocity.com/products/hr/talent-management-system/','Paylocity Talent Management System','Paylocity' UNION ALL
 SELECT 'paylocity','https://www.paylocity.com/products/hr/talent-management-system/onboarding/','Paylocity Employee Onboarding Software','Paylocity' UNION ALL
 SELECT 'acumatica-cloud-erp','https://www.acumatica.com/cloud-erp-software/','Acumatica Cloud ERP','Acumatica' UNION ALL
 SELECT 'acumatica-cloud-erp','https://www.acumatica.com/cloud-erp-software/product-editions/','Acumatica Product Editions','Acumatica' UNION ALL
 SELECT 'acumatica-cloud-erp','https://www.acumatica.com/cloud-erp-software/project-accounting/','Acumatica Project Accounting','Acumatica' UNION ALL
 SELECT 'airtable','https://www.airtable.com/solutions/project-management','Airtable for Project Management','Airtable' UNION ALL
 SELECT 'airtable','https://support.airtable.com/articles/1069623552-timeline-view-overview','Airtable Timeline View','Airtable' UNION ALL
 SELECT 'airtable','https://support.airtable.com/articles/1295490370-date-dependencies-in-airtable','Airtable Date Dependencies','Airtable' UNION ALL
 SELECT 'sap-analytics-cloud','https://www.sap.com/products/cloud-analytics.html','SAP Analytics Cloud','SAP' UNION ALL
 SELECT 'sap-analytics-cloud','https://help.sap.com/doc/00f68c2e08b941f081002fd3691d86a7/2023.20/en-US/0ace2c43b92b41099b1cd964b4ff198a.html','SAP Analytics Cloud Planning','SAP' UNION ALL
 SELECT 'trellix-endpoint-security','https://www.trellix.com/products/endpoint-security/','Trellix Endpoint Security','Trellix' UNION ALL
 SELECT 'trellix-endpoint-security','https://www.trellix.com/platform/endpoint-security/','Trellix Modern Endpoint Security','Trellix' UNION ALL
 SELECT 'trellix-endpoint-security','https://www.trellix.com/products/edrf/','Trellix EDR with Forensics','Trellix' UNION ALL
 SELECT 'nakivo-backup-replication','https://helpcenter.nakivo.com/User-Guide/Content/Overview/Overview.htm','NAKIVO Backup & Replication Overview','NAKIVO' UNION ALL
 SELECT 'nakivo-backup-replication','https://helpcenter.nakivo.com/User-Guide/Content/Overview/Microsoft-365-Backup.htm','NAKIVO Microsoft 365 Backup','NAKIVO' UNION ALL
 SELECT 'nakivo-backup-replication','https://helpcenter.nakivo.com/User-Guide/Content/Overview/Disaster-Recovery.htm','NAKIVO Disaster Recovery','NAKIVO' UNION ALL
 SELECT 'nakivo-backup-replication','https://download.nakivo.com/res/files/nakivo-backup-replication-datasheet.pdf','NAKIVO Backup & Replication Datasheet','NAKIVO'
) x ON x.product_slug=p.slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=x.url);

DROP TEMPORARY TABLE IF EXISTS cat78_facts;
CREATE TEMPORARY TABLE cat78_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat78_facts VALUES
-- Sugar Sell
('sugar-sell','crm-lead-management','supported',0.99,'Sugar documents lead and contact management across the sales lifecycle.','https://support.sugarcrm.com/documentation/sugar_versions/25.1/sell/application_guide/introduction/'),
('sugar-sell','crm-contact-account-management','supported',0.99,'Accounts and contacts are core Sugar CRM record types.','https://support.sugarcrm.com/documentation/sugar_versions/25.1/sell/application_guide/introduction/'),
('sugar-sell','crm-opportunity-pipeline','supported',0.99,'Opportunity and pipeline management are core Sugar Sell capabilities.','https://www.sugarcrm.com/solutions/sugar-sell/'),
('sugar-sell','crm-sales-automation','supported',0.98,'Smart Guides and workflow automation are documented; edition availability varies.','https://support.sugarcrm.com/documentation/sugar_versions/25.2/sell/application_guide/sugar_automate/'),
('sugar-sell','crm-sales-forecasting','supported',0.99,'Sales forecasting is explicitly documented.','https://support.sugarcrm.com/documentation/sugar_versions/25.1/sell/application_guide/introduction/'),
('sugar-sell','crm-reports-dashboards','supported',0.98,'Dashboards, analytics and reporting are documented for Sugar Sell.','https://www.sugarcrm.com/solutions/sugar-sell/'),
('sugar-sell','crm-api-access','supported',0.95,'Sugar Sell publicly documents open REST/SOAP APIs; exact API availability depends on edition and deployment.','https://www.sugarcrm.com/solutions/sugar-sell/'),

-- TOPdesk
('topdesk','itsm-incident-management','supported',0.99,NULL,'https://www.topdesk.com/en/solutions/it-service-management/'),
('topdesk','itsm-request-service-catalog','supported',0.95,'TOPdesk documents self-service and service-request workflows; exact catalog configuration varies.','https://www.topdesk.com/en/solutions/it-service-management/'),
('topdesk','itsm-problem-management','supported',0.99,NULL,'https://www.topdesk.com/en/solutions/it-service-management/'),
('topdesk','itsm-change-management','supported',0.99,NULL,'https://www.topdesk.com/en/solutions/it-service-management/'),
('topdesk','itsm-knowledge-management','supported',0.98,'Knowledge management and self-service knowledge are documented.','https://www.topdesk.com/en/solutions/it-service-management/'),
('topdesk','itsm-asset-management','supported',0.99,NULL,'https://www.topdesk.com/en/solutions/it-service-management/'),
('topdesk','itsm-workflow-automation','supported',0.95,'TOPdesk documents automation and API-enabled process integration.','https://www.topdesk.com/en/documentation-portal/'),
('topdesk','itsm-reports-dashboards','supported',0.95,'Reporting and dashboards are part of TOPdesk service-management functionality.','https://www.topdesk.com/en/solutions/it-service-management/'),
('topdesk','itsm-api-access','supported',0.99,'TOPdesk provides official API documentation across service-management modules.','https://www.topdesk.com/en/documentation-portal/'),

-- Paylocity
('paylocity','hr-core-employee-records','supported',0.98,'Paylocity positions HR as a unified system for employee data and HR administration.','https://www.paylocity.com/products/hr/'),
('paylocity','hr-onboarding','supported',0.99,NULL,'https://www.paylocity.com/products/hr/talent-management-system/onboarding/'),
('paylocity','hr-recruiting','supported',0.99,NULL,'https://www.paylocity.com/products/hr/talent-management-system/'),
('paylocity','hr-performance-management','supported',0.98,'Performance management is explicitly included in the talent suite.','https://www.paylocity.com/products/hr/talent-management-system/'),
('paylocity','hr-learning-development','supported',0.98,'Learning is explicitly included in the talent suite.','https://www.paylocity.com/products/hr/talent-management-system/'),
('paylocity','hr-time-attendance','supported',0.99,NULL,'https://www.paylocity.com/products/'),
('paylocity','hr-payroll','supported',0.99,NULL,'https://www.paylocity.com/products/'),

-- Acumatica Cloud ERP
('acumatica-cloud-erp','erp-financial-accounting','supported',0.99,'Acumatica documents general ledger and advanced financials across editions.','https://www.acumatica.com/cloud-erp-software/product-editions/'),
('acumatica-cloud-erp','erp-ap-ar','supported',0.99,'Accounts payable and accounts receivable are explicitly included.','https://www.acumatica.com/cloud-erp-software/product-editions/'),
('acumatica-cloud-erp','erp-inventory-warehouse','supported',0.95,'Inventory and distribution capabilities are documented; specialized WMS depth depends on edition and connected applications.','https://www.acumatica.com/cloud-erp-software/'),
('acumatica-cloud-erp','erp-supply-chain-planning','supported',0.95,'MRP and purchasing planning are documented for manufacturing operations.','https://www.acumatica.com/cloud-erp-software/'),
('acumatica-cloud-erp','erp-manufacturing','supported',0.99,'Manufacturing editions cover production management, BOM/routing and MRP.','https://www.acumatica.com/cloud-erp-software/'),
('acumatica-cloud-erp','erp-project-operations','supported',0.99,'Project accounting covers project cost, billing, time, expenses, budgets and profitability.','https://www.acumatica.com/cloud-erp-software/project-accounting/'),
('acumatica-cloud-erp','erp-reports-dashboards','supported',0.98,'Real-time reporting and business visibility are documented.','https://www.acumatica.com/cloud-erp-software/'),

-- Airtable
('airtable','pm-task-project-management','supported',0.98,'Airtable documents project delivery, work management and task automation.','https://www.airtable.com/solutions/project-management'),
('airtable','pm-timeline-schedule','supported',0.99,'Timeline view is an explicit project-management capability.','https://support.airtable.com/articles/1069623552-timeline-view-overview'),
('airtable','pm-dependencies-milestones','supported',0.98,'Date dependencies support predecessor-driven schedule changes; milestone depth should be confirmed for the chosen workflow.','https://support.airtable.com/articles/1295490370-date-dependencies-in-airtable'),
('airtable','pm-workflow-automation','supported',0.99,'Airtable documents AI-powered automation and streamlined project workflows.','https://www.airtable.com/solutions/project-management'),
('airtable','pm-dashboards-reporting','supported',0.95,'Project reporting and shared visibility are documented; advanced portfolio reporting depends on configuration.','https://www.airtable.com/solutions/project-management'),
('airtable','pm-team-collaboration','supported',0.99,'Shared workflows and cross-team collaboration are core documented capabilities.','https://www.airtable.com/solutions/project-management'),

-- SAP Analytics Cloud
('sap-analytics-cloud','bi-dashboards-reports','supported',0.99,'SAP documents business intelligence, reporting and prebuilt analytics content.','https://www.sap.com/products/cloud-analytics.html'),
('sap-analytics-cloud','bi-self-service','supported',0.99,'Self-service analytics across governed business data is explicitly documented.','https://www.sap.com/products/cloud-analytics.html'),
('sap-analytics-cloud','bi-data-visualization','supported',0.95,'Interactive analytics and story-based business intelligence are part of the platform; exact visualization depth varies by use case.','https://www.sap.com/products/cloud-analytics.html'),
('sap-analytics-cloud','bi-data-connectivity','supported',0.98,'SAP documents native connectivity to SAP data plus third-party data for analytics and planning.','https://www.sap.com/products/cloud-analytics.html'),
('sap-analytics-cloud','bi-sharing-collaboration','supported',0.95,'Collaborative planning and aligned team workflows are documented in SAP Analytics Cloud.','https://help.sap.com/doc/00f68c2e08b941f081002fd3691d86a7/2023.20/en-US/0ace2c43b92b41099b1cd964b4ff198a.html'),
('sap-analytics-cloud','bi-governance','supported',0.98,'SAP describes analytics on a governed data foundation preserving business semantics.','https://www.sap.com/products/cloud-analytics.html'),

-- Trellix Endpoint Security
('trellix-endpoint-security','endpoint-malware-ransomware','supported',0.99,'Trellix documents multilayered threat prevention across endpoint attack vectors.','https://www.trellix.com/products/endpoint-security/'),
('trellix-endpoint-security','endpoint-behavior-exploit','supported',0.99,'Machine learning, heuristics and exploit prevention are explicitly documented.','https://www.trellix.com/products/endpoint-security/'),
('trellix-endpoint-security','endpoint-edr','supported',0.95,'Trellix documents EDR delivered through the endpoint agent; specific EDR/forensics functions may depend on licensed components.','https://www.trellix.com/products/endpoint-security/'),
('trellix-endpoint-security','endpoint-central-management','supported',0.99,'ePolicy Orchestrator provides centralized endpoint deployment, policy, event and response management.','https://www.trellix.com/products/endpoint-security/'),
('trellix-endpoint-security','endpoint-automated-response','supported',0.95,'Modern Endpoint Security documents detection, containment and remediation; exact automated actions depend on licensed components.','https://www.trellix.com/platform/endpoint-security/'),

-- NAKIVO Backup & Replication
('nakivo-backup-replication','backup-core','supported',0.99,'NAKIVO documents backup, replication, restore and granular recovery across protected workloads.','https://helpcenter.nakivo.com/User-Guide/Content/Overview/Overview.htm'),
('nakivo-backup-replication','backup-cloud-saas','supported',0.99,'Microsoft 365 backup covers Exchange Online, OneDrive, SharePoint and Teams, with cloud/local repository options.','https://helpcenter.nakivo.com/User-Guide/Content/Overview/Microsoft-365-Backup.htm'),
('nakivo-backup-replication','backup-ransomware-resilience','supported',0.99,'Official datasheet documents immutable, air-gapped and malware-scanned backups.','https://download.nakivo.com/res/files/nakivo-backup-replication-datasheet.pdf'),
('nakivo-backup-replication','backup-disaster-recovery-capability','supported',0.99,'NAKIVO documents automated DR workflows, replication, failover and failback.','https://helpcenter.nakivo.com/User-Guide/Content/Overview/Disaster-Recovery.htm'),
('nakivo-backup-replication','backup-central-management','supported',0.98,'The product provides centralized web-based job, backup and recovery management.','https://helpcenter.nakivo.com/User-Guide/Content/Overview/Overview.htm'),
('nakivo-backup-replication','backup-hybrid-multicloud','supported',0.99,'NAKIVO documents protection for virtual, physical, cloud and SaaS environments.','https://helpcenter.nakivo.com/User-Guide/Content/Overview/Overview.htm');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat78_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat78_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,f.limitations
FROM cat78_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Conservative deployment facts only where the reviewed first-party material is explicit.
INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.95 FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug IN('sugar-sell','topdesk','paylocity','acumatica-cloud-erp','airtable','sap-analytics-cloud')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.95 FROM products p JOIN deployment_models d ON d.slug='on-premise'
WHERE p.slug IN('trellix-endpoint-security','nakivo-backup-replication')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

-- Product-specific integration coverage is intentionally left unknown unless separately reviewed.
INSERT INTO product_integrations(product_id,integration_id,support_status,confidence_score)
SELECT p.id,i.id,'not_yet_verified',0 FROM products p JOIN integrations i
WHERE p.slug IN('sugar-sell','topdesk','paylocity','acumatica-cloud-erp','airtable','sap-analytics-cloud','trellix-endpoint-security','nakivo-backup-replication')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

DROP TEMPORARY TABLE IF EXISTS cat78_facts;
DROP TEMPORARY TABLE IF EXISTS cat78_products;
COMMIT;
