-- TechSelectAI catalog expansion: major existing categories batch 3
-- Adds seven recognizable products to existing categories using official first-party evidence reviewed in Sep 2026.
-- Reuses existing taxonomy and preserves Unknown != Unsupported.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Ivanti','ivanti','https://www.ivanti.com/','IT service management and endpoint-management software vendor.','active'),
('ADP','adp','https://www.adp.com/','Payroll, HR and human capital management software vendor.','active'),
('Infor','infor','https://www.infor.com/','Enterprise ERP and industry cloud software vendor.','active'),
('Adobe','adobe','https://www.adobe.com/','Enterprise software vendor.','active'),
('Sisense','sisense','https://www.sisense.com/','Business intelligence and embedded analytics software vendor.','active'),
('ESET','eset','https://www.eset.com/','Cybersecurity software vendor.','active'),
('Veritas','veritas','https://www.veritas.com/','Enterprise data protection and backup software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat76_products;
CREATE TEMPORARY TABLE cat76_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO cat76_products VALUES
('ivanti','itsm','Ivanti Neurons for ITSM','ivanti-neurons-itsm','AI-enabled IT service management platform for incidents, requests, knowledge, automation and broader service-management workflows.','https://www.ivanti.com/products/ivanti-neurons-for-itsm'),
('adp','hr-hcm','ADP Workforce Now','adp-workforce-now','All-in-one HR and workforce platform for core HR, payroll, time and attendance, talent, benefits and workforce analytics.','https://www.adp.com/what-we-offer/products/adp-workforce-now.aspx'),
('infor','erp','Infor CloudSuite Industrial','infor-cloudsuite-industrial','Industry-focused ERP for manufacturing with finance, procurement, inventory, supply chain, production, projects and analytics.','https://www.infor.com/mea/solutions/erp/industrial-manufacturing'),
('adobe','project-management','Adobe Workfront','adobe-workfront','Enterprise work management platform for projects, tasks, programs, portfolios, workflow automation, approvals and reporting.','https://business.adobe.com/products/workfront.html'),
('sisense','business-intelligence-analytics','Sisense','sisense','AI-powered analytics and embedded BI platform with dashboards, self-service analytics, data connectivity, governance and APIs.','https://www.sisense.com/ai-analytics-platform/'),
('eset','endpoint-security','ESET PROTECT Enterprise','eset-protect-enterprise','Enterprise endpoint security with multilayered protection, XDR, ransomware defense, encryption and centralized management.','https://www.eset.com/us/business/resource-center/solution-overviews/eset-protect-enterprise/'),
('veritas','backup-disaster-recovery','Veritas NetBackup','veritas-netbackup','Enterprise backup and recovery platform for hybrid and cloud workloads with immutable protection, ransomware resilience and centralized recovery operations.','https://www.veritas.com/protection/netbackup');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat76_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',x.url,x.title,x.publisher,1,'verified','high',NOW()
FROM products p JOIN (
 SELECT 'ivanti-neurons-itsm' product_slug,'https://www.ivanti.com/resources/datasheets/ivanti-neurons-for-itsm' url,'Ivanti Neurons for ITSM Datasheet' title,'Ivanti' publisher UNION ALL
 SELECT 'ivanti-neurons-itsm','https://docs.ivanti.com/neurons-for-itsm-release-notes-enu-latest','Ivanti Neurons for ITSM Release Notes','Ivanti' UNION ALL
 SELECT 'adp-workforce-now','https://www.adp.com/what-we-offer/products/adp-workforce-now/capabilities.aspx','ADP Workforce Now Capabilities','ADP' UNION ALL
 SELECT 'adp-workforce-now','https://www.adp.com/what-we-offer/products/adp-workforce-now/compare-options.aspx','ADP Workforce Now Plans and Features','ADP' UNION ALL
 SELECT 'infor-cloudsuite-industrial','https://www.infor.com/en/solutions/erp','Infor ERP Capabilities','Infor' UNION ALL
 SELECT 'infor-cloudsuite-industrial','https://www.infor.com/mea/solutions/erp/industrial-manufacturing','Infor Industrial Manufacturing ERP','Infor' UNION ALL
 SELECT 'infor-cloudsuite-industrial','https://www.infor.com/products/cloud-strategy','Infor CloudSuite Overview','Infor' UNION ALL
 SELECT 'adobe-workfront','https://business.adobe.com/products/workfront/workflow-management.html','Adobe Workfront Workflow Management','Adobe' UNION ALL
 SELECT 'adobe-workfront','https://experienceleague.adobe.com/en/docs/workfront/using/manage-work/manage-work','Adobe Workfront Manage Work','Adobe' UNION ALL
 SELECT 'sisense','https://www.sisense.com/ai-analytics-platform/','Sisense AI Analytics Platform','Sisense' UNION ALL
 SELECT 'sisense','https://www.sisense.com/ai-analytics-platform/data-connectivity-solutions/','Sisense Data Connectivity','Sisense' UNION ALL
 SELECT 'sisense','https://www.sisense.com/ai-analytics-platform/trust-and-security/','Sisense Trust and Security','Sisense' UNION ALL
 SELECT 'eset-protect-enterprise','https://www.eset.com/us/business/resource-center/solution-overviews/eset-protect-enterprise/','ESET PROTECT Enterprise Overview','ESET' UNION ALL
 SELECT 'veritas-netbackup','https://origin-www.veritas.com/content/support/en_US/doc/21733320-172136947-0/v141703949-172136947','NetBackup Immutability and Indelibility','Veritas' UNION ALL
 SELECT 'veritas-netbackup','https://origin-www.veritas.com/content/support/en_US/doc/150074555-159313136-0/v147858157-159313136','NetBackup Cloud Workload Protection','Veritas'
) x ON x.product_slug=p.slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=x.url);

DROP TEMPORARY TABLE IF EXISTS cat76_facts;
CREATE TEMPORARY TABLE cat76_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat76_facts VALUES
-- Ivanti Neurons for ITSM
('ivanti-neurons-itsm','itsm-incident-management','supported',0.99,'Official datasheet documents AI-assisted ticket classification, routing and incident correlation.','https://www.ivanti.com/resources/datasheets/ivanti-neurons-for-itsm'),
('ivanti-neurons-itsm','itsm-knowledge-management','supported',0.98,'Knowledge creation and self-service acceleration are explicitly documented.','https://www.ivanti.com/resources/datasheets/ivanti-neurons-for-itsm'),
('ivanti-neurons-itsm','itsm-workflow-automation','supported',0.99,'Automation is a core Neurons for ITSM capability.','https://www.ivanti.com/resources/datasheets/ivanti-neurons-for-itsm'),
('ivanti-neurons-itsm','itsm-cmdb','supported',0.95,'Current release documentation includes ITSM CMDB integration; deployment scope should be confirmed.','https://docs.ivanti.com/neurons-for-itsm-release-notes-enu-latest'),

-- ADP Workforce Now
('adp-workforce-now','hr-core-employee-records','supported',0.99,'ADP documents centralized workforce data and digital employee records.','https://www.adp.com/what-we-offer/products/adp-workforce-now/capabilities.aspx'),
('adp-workforce-now','hr-onboarding','supported',0.99,'Guided preboarding and onboarding are documented.','https://www.adp.com/what-we-offer/products/adp-workforce-now/capabilities.aspx'),
('adp-workforce-now','hr-recruiting','supported',0.99,'Talent acquisition and recruitment are documented.','https://www.adp.com/what-we-offer/products/adp-workforce-now/compare-options.aspx'),
('adp-workforce-now','hr-time-attendance','supported',0.99,'Time, scheduling and attendance are documented in Workforce Management.','https://www.adp.com/what-we-offer/products/adp-workforce-now/capabilities.aspx'),
('adp-workforce-now','hr-leave-absence','supported',0.95,'PTO/time-off requests and accruals are documented in current packages.','https://www.adp.com/what-we-offer/products/adp-workforce-now/compare-options.aspx'),
('adp-workforce-now','hr-payroll','supported',0.99,'Payroll is a core Workforce Now capability.','https://www.adp.com/what-we-offer/products/adp-workforce-now/capabilities.aspx'),
('adp-workforce-now','hr-reports-analytics','supported',0.99,'Reporting and analytics are documented as a core suite capability.','https://www.adp.com/what-we-offer/products/adp-workforce-now/capabilities.aspx'),

-- Infor CloudSuite Industrial
('infor-cloudsuite-industrial','erp-financial-accounting','supported',0.99,NULL,'https://www.infor.com/en/solutions/erp'),
('infor-cloudsuite-industrial','erp-procurement','supported',0.99,NULL,'https://www.infor.com/en/solutions/erp'),
('infor-cloudsuite-industrial','erp-inventory-warehouse','supported',0.99,NULL,'https://www.infor.com/mea/solutions/erp/industrial-manufacturing'),
('infor-cloudsuite-industrial','erp-supply-chain-planning','supported',0.98,'Demand forecasting, scheduling and supply-chain operations are documented.','https://www.infor.com/mea/solutions/erp/industrial-manufacturing'),
('infor-cloudsuite-industrial','erp-manufacturing','supported',0.99,NULL,'https://www.infor.com/en/solutions/erp'),
('infor-cloudsuite-industrial','erp-project-operations','supported',0.95,'Project and program delivery capabilities are documented for industrial manufacturing.','https://www.infor.com/mea/solutions/erp/industrial-manufacturing'),
('infor-cloudsuite-industrial','erp-reports-dashboards','supported',0.99,'Embedded reporting, dashboards and prebuilt data models are documented.','https://www.infor.com/products/cloud-strategy'),

-- Adobe Workfront
('adobe-workfront','pm-task-project-management','supported',0.99,'Projects, tasks and issues are core Workfront objects.','https://experienceleague.adobe.com/en/docs/workfront/using/manage-work/manage-work'),
('adobe-workfront','pm-timeline-schedule','supported',0.99,'Gantt/timeline management is documented.','https://experienceleague.adobe.com/en/docs/workfront/using/manage-work/manage-work'),
('adobe-workfront','pm-workflow-automation','supported',0.99,'Task automation and workflow management are explicitly documented.','https://business.adobe.com/products/workfront/workflow-management.html'),
('adobe-workfront','pm-dashboards-reporting','supported',0.98,'Central dashboards and project visibility are documented.','https://business.adobe.com/products/workfront/workflow-management.html'),
('adobe-workfront','pm-team-collaboration','supported',0.98,'Online proofing, approvals and collaboration are documented.','https://business.adobe.com/products/workfront/workflow-management.html'),

-- Sisense
('sisense','bi-dashboards-reports','supported',0.99,'Dashboards and widgets are core documented platform capabilities.','https://www.sisense.com/ai-analytics-platform/'),
('sisense','bi-self-service','supported',0.99,'Self-service exploration is explicitly documented.','https://www.sisense.com/ai-analytics-platform/'),
('sisense','bi-data-visualization','supported',0.99,'Visual analytics and dashboards are explicitly documented.','https://www.sisense.com/ai-analytics-platform/'),
('sisense','bi-data-connectivity','supported',0.99,'Sisense documents hundreds of connectors and live/cached connectivity.','https://www.sisense.com/ai-analytics-platform/data-connectivity-solutions/'),
('sisense','bi-sharing-collaboration','supported',0.95,'Embedded and shared analytics distribution are documented.','https://www.sisense.com/ai-analytics-platform/'),
('sisense','bi-governance','supported',0.99,'Governed semantics, role-based access and security controls are documented.','https://www.sisense.com/ai-analytics-platform/trust-and-security/'),

-- ESET PROTECT Enterprise
('eset-protect-enterprise','endpoint-malware-ransomware','supported',0.99,'ESET documents multilayered protection including ransomware and zero-day defenses.','https://www.eset.com/us/business/resource-center/solution-overviews/eset-protect-enterprise/'),
('eset-protect-enterprise','endpoint-behavior-exploit','supported',0.99,'Behavior and reputation-based detection plus advanced threat defense are documented.','https://www.eset.com/us/business/resource-center/solution-overviews/eset-protect-enterprise/'),
('eset-protect-enterprise','endpoint-edr','supported',0.99,'XDR detection and response capabilities are explicitly documented.','https://www.eset.com/us/business/resource-center/solution-overviews/eset-protect-enterprise/'),
('eset-protect-enterprise','endpoint-central-management','supported',0.99,'Single-pane remote management is explicitly documented.','https://www.eset.com/us/business/resource-center/solution-overviews/eset-protect-enterprise/'),
('eset-protect-enterprise','endpoint-cross-platform','supported',0.95,'Enterprise endpoints and mobiles are covered; exact supported OS versions should be confirmed before deployment.','https://www.eset.com/us/business/resource-center/solution-overviews/eset-protect-enterprise/'),

-- Veritas NetBackup
('veritas-netbackup','backup-core','supported',0.99,'NetBackup provides enterprise backup and recovery.','https://origin-www.veritas.com/content/support/en_US/doc/150074555-159313136-0/v147858157-159313136'),
('veritas-netbackup','backup-cloud-saas','supported',0.95,'Official cloud workload documentation covers cloud assets; SaaS application coverage varies by workload and release.','https://origin-www.veritas.com/content/support/en_US/doc/150074555-159313136-0/v147858157-159313136'),
('veritas-netbackup','backup-ransomware-resilience','supported',0.99,'WORM immutability and indelibility are explicitly documented for backup images.','https://origin-www.veritas.com/content/support/en_US/doc/21733320-172136947-0/v141703949-172136947'),
('veritas-netbackup','backup-disaster-recovery-capability','supported',0.98,'NetBackup supports recovery workflows for protected workloads and cloud assets.','https://origin-www.veritas.com/content/support/en_US/doc/150074555-159313136-0/v147858157-159313136'),
('veritas-netbackup','backup-central-management','supported',0.98,'Protection plans and centralized workload management are documented.','https://origin-www.veritas.com/content/support/en_US/doc/150074555-159313136-0/v147858157-159313136'),
('veritas-netbackup','backup-hybrid-multicloud','supported',0.99,'Cloud asset protection across AWS, Azure and Google Cloud is documented.','https://origin-www.veritas.com/content/support/en_US/doc/150074555-159313136-0/v147858157-159313136');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat76_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat76_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,f.limitations
FROM cat76_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Conservative deployment facts only.
INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.95 FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug IN('ivanti-neurons-itsm','adp-workforce-now','infor-cloudsuite-industrial','adobe-workfront','sisense')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.90 FROM products p JOIN deployment_models d ON d.slug='on-premise'
WHERE p.slug IN('sisense','eset-protect-enterprise','veritas-netbackup')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

-- Product-specific integration coverage is not reviewed in this batch; preserve explicit unknowns.
INSERT INTO product_integrations(product_id,integration_id,support_status,confidence_score)
SELECT p.id,i.id,'not_yet_verified',0 FROM products p JOIN integrations i
WHERE p.slug IN('ivanti-neurons-itsm','adp-workforce-now','infor-cloudsuite-industrial','adobe-workfront','sisense','eset-protect-enterprise','veritas-netbackup')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

DROP TEMPORARY TABLE IF EXISTS cat76_facts;
DROP TEMPORARY TABLE IF EXISTS cat76_products;
COMMIT;
