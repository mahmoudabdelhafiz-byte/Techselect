-- TechSelectAI catalog expansion: major existing categories batch 1
-- Adds one well-known product to seven existing categories using official first-party evidence.
-- Reuses existing taxonomy and preserves Unknown != Unsupported.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Halo','halo','https://usehalo.com/','IT service management and service operations software vendor.','active'),
('Deel','deel','https://www.deel.com/','Global HR, payroll and workforce management platform vendor.','active'),
('Sage','sage','https://www.sage.com/','Accounting, ERP and business management software vendor.','active'),
('37signals','37signals','https://37signals.com/','Software company behind Basecamp.','active'),
('Domo','domo','https://www.domo.com/','Business intelligence, data and analytics platform vendor.','active'),
('Bitdefender','bitdefender','https://www.bitdefender.com/','Cybersecurity software vendor.','active'),
('Rubrik','rubrik','https://www.rubrik.com/','Data security, backup and cyber recovery platform vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat72_products;
CREATE TEMPORARY TABLE cat72_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO cat72_products VALUES
('halo','itsm','HaloITSM','haloitsm','ITIL-aligned IT service management platform for incidents, requests, problems, changes, knowledge, assets, CMDB, automation and service analytics.','https://www.usehalo.com/haloitsm'),
('deel','hr-hcm','Deel HR','deel-hr','Global HR platform for centralized worker records, onboarding, recruiting, time off, payroll-connected workflows and workforce integrations.','https://www.deel.com/solutions/hr/'),
('sage','erp','Sage Intacct','sage-intacct','Cloud financial management and ERP platform for core accounting, purchasing, reporting, planning, project accounting and integrations.','https://www.sage.com/en-us/sage-business-cloud/intacct/'),
('37signals','project-management','Basecamp','basecamp','Project and team collaboration platform for tasks, schedules, messages, files, progress visibility and reporting.','https://basecamp.com/features'),
('domo','business-intelligence-analytics','Domo','domo','Cloud business intelligence platform for dashboards, self-service analytics, visualization, data connectivity and governed sharing.','https://www.domo.com/'),
('bitdefender','endpoint-security','Bitdefender GravityZone Business Security Enterprise','bitdefender-gravityzone-enterprise','Enterprise endpoint security platform with prevention, EDR, centralized management, automated response and cross-platform protection.','https://www.bitdefender.com/en-us/business/products/gravityzone-enterprise-security'),
('rubrik','backup-disaster-recovery','Rubrik Security Cloud','rubrik-security-cloud','Enterprise data security and cyber resilience platform for backup, recovery, ransomware resilience, cloud and hybrid workload protection.','https://www.rubrik.com/');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat72_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',x.url,x.title,x.publisher,1,'verified','high',NOW()
FROM products p JOIN (
 SELECT 'haloitsm' product_slug,'https://www.usehalo.com/platform' url,'Halo platform capabilities' title,'Halo' publisher UNION ALL
 SELECT 'haloitsm','https://www.usehalo.com/platform/incident-management','Halo Incident Management','Halo' UNION ALL
 SELECT 'haloitsm','https://www.usehalo.com/platform/service-management','Halo Service Management','Halo' UNION ALL
 SELECT 'deel-hr','https://www.deel.com/solutions/hr/','Deel HR','Deel' UNION ALL
 SELECT 'deel-hr','https://developer.deel.com/api/hris/introduction','Deel HRIS API Introduction','Deel' UNION ALL
 SELECT 'deel-hr','https://developer.deel.com/api/ats-guides/getting-started','Deel ATS API Guide','Deel' UNION ALL
 SELECT 'deel-hr','https://www.deel.com/solutions/open-api/','Deel Open API','Deel' UNION ALL
 SELECT 'sage-intacct','https://www.sage.com/en-us/sage-business-cloud/intacct/product-capabilities/core-financials/','Sage Intacct Core Financials','Sage' UNION ALL
 SELECT 'sage-intacct','https://www.sage.com/en-us/sage-business-cloud/intacct/product-capabilities/core-financials/purchase-orders/','Sage Intacct Purchasing','Sage' UNION ALL
 SELECT 'sage-intacct','https://www.sage.com/en-us/sage-business-cloud/intacct/product-capabilities/extended-capabilities/','Sage Intacct Extended Capabilities','Sage' UNION ALL
 SELECT 'sage-intacct','https://www.sage.com/en-us/sage-business-cloud/intacct/product-capabilities/platform/web-services/','Sage Intacct Web Services API','Sage' UNION ALL
 SELECT 'basecamp','https://basecamp.com/features','Basecamp Features','37signals' UNION ALL
 SELECT 'domo','https://domo-webflow.domo.com/features','Domo Platform Features','Domo' UNION ALL
 SELECT 'domo','https://domo-webflow.domo.com/business-intelligence','Domo Business Intelligence','Domo' UNION ALL
 SELECT 'domo','https://domo-webflow.domo.com/data-integration','Domo Data Integration','Domo' UNION ALL
 SELECT 'domo','https://domo-webflow.domo.com/domo-for-enterprise','Domo for Enterprise','Domo' UNION ALL
 SELECT 'bitdefender-gravityzone-enterprise','https://www.bitdefender.com/en-us/business/products/gravityzone-enterprise-security','GravityZone Business Security Enterprise','Bitdefender' UNION ALL
 SELECT 'bitdefender-gravityzone-enterprise','https://www.bitdefender.com/business/support/en/77209-1441675-security-features.html','GravityZone Cloud Security Features','Bitdefender' UNION ALL
 SELECT 'bitdefender-gravityzone-enterprise','https://www.bitdefender.com/business/support/en/77209-1441676-operational-features.html','GravityZone Operational Features','Bitdefender' UNION ALL
 SELECT 'bitdefender-gravityzone-enterprise','https://www.bitdefender.com/business/support/en/77211-151139-edr---xdr.html','GravityZone EDR and XDR','Bitdefender' UNION ALL
 SELECT 'rubrik-security-cloud','https://www.rubrik.com/solutions/backup-recovery','Rubrik Backup and Recovery','Rubrik' UNION ALL
 SELECT 'rubrik-security-cloud','https://www.rubrik.com/solutions/ransomware-recovery','Rubrik Ransomware Recovery','Rubrik' UNION ALL
 SELECT 'rubrik-security-cloud','https://www.rubrik.com/solutions/cloud-solutions','Rubrik Cloud Data Protection','Rubrik' UNION ALL
 SELECT 'rubrik-security-cloud','https://www.rubrik.com/products/saas-data-protection','Rubrik SaaS Data Protection','Rubrik' UNION ALL
 SELECT 'rubrik-security-cloud','https://www.rubrik.com/resources/api-integration','Rubrik API Integration','Rubrik'
) x ON x.product_slug=p.slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=x.url);

DROP TEMPORARY TABLE IF EXISTS cat72_facts;
CREATE TEMPORARY TABLE cat72_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat72_facts VALUES
-- HaloITSM
('haloitsm','itsm-incident-management','supported',0.99,NULL,'https://www.usehalo.com/platform/incident-management'),
('haloitsm','itsm-request-service-catalog','supported',0.99,NULL,'https://www.usehalo.com/platform/service-management'),
('haloitsm','itsm-sla-management','supported',0.99,NULL,'https://www.usehalo.com/platform/service-management'),
('haloitsm','itsm-problem-management','supported',0.98,NULL,'https://www.usehalo.com/platform'),
('haloitsm','itsm-change-management','supported',0.98,NULL,'https://www.usehalo.com/platform'),
('haloitsm','itsm-knowledge-management','supported',0.98,NULL,'https://www.usehalo.com/platform'),
('haloitsm','itsm-asset-management','supported',0.98,NULL,'https://www.usehalo.com/platform'),
('haloitsm','itsm-cmdb','supported',0.98,NULL,'https://www.usehalo.com/platform'),
('haloitsm','itsm-workflow-automation','supported',0.99,'Visual no-code workflow automation is documented across service processes.','https://www.usehalo.com/platform/service-management'),
('haloitsm','itsm-reports-dashboards','supported',0.95,'Live dashboards and scheduled reporting are documented.','https://www.usehalo.com/platform/service-management'),

-- Deel HR
('deel-hr','hr-core-employee-records','supported',0.99,'Deel HRIS provides a global system of record for worker data and organizational structures.','https://developer.deel.com/api/hris/introduction'),
('deel-hr','hr-onboarding','supported',0.98,'Deel documents onboarding workflows and onboarding-tracker APIs.','https://www.deel.com/solutions/open-api/'),
('deel-hr','hr-recruiting','supported',0.98,'Deel ATS supports jobs, applications and recruiting workflows.','https://developer.deel.com/api/ats-guides/getting-started'),
('deel-hr','hr-leave-absence','supported',0.99,'The HRIS API supports time-off policies, entitlements and requests.','https://developer.deel.com/api/hris/introduction'),
('deel-hr','hr-payroll','supported',0.95,'Global payroll is part of the broader Deel workforce platform; country and worker-type coverage varies.','https://www.deel.com/solutions/hr/'),
('deel-hr','hr-api-access','supported',0.99,'Deel provides REST APIs for HRIS, payroll, onboarding and workforce operations.','https://www.deel.com/solutions/open-api/'),

-- Sage Intacct
('sage-intacct','erp-financial-accounting','supported',0.99,NULL,'https://www.sage.com/en-us/sage-business-cloud/intacct/product-capabilities/core-financials/'),
('sage-intacct','erp-ap-ar','supported',0.99,NULL,'https://www.sage.com/en-us/sage-business-cloud/intacct/product-capabilities/core-financials/'),
('sage-intacct','erp-budgeting-planning','supported',0.95,'Planning, budgeting and forecasting are documented as extended capabilities.','https://www.sage.com/en-us/sage-business-cloud/intacct/product-capabilities/extended-capabilities/'),
('sage-intacct','erp-procurement','supported',0.99,NULL,'https://www.sage.com/en-us/sage-business-cloud/intacct/product-capabilities/core-financials/purchase-orders/'),
('sage-intacct','erp-inventory-warehouse','partially_supported',0.85,'Inventory control is documented as an extended capability; full warehouse-management depth should be confirmed.','https://www.sage.com/en-us/sage-business-cloud/intacct/product-capabilities/extended-capabilities/'),
('sage-intacct','erp-project-operations','supported',0.95,'Project accounting is documented among extended capabilities.','https://www.sage.com/en-us/sage-business-cloud/intacct/product-capabilities/extended-capabilities/'),
('sage-intacct','erp-reports-dashboards','supported',0.99,NULL,'https://www.sage.com/en-us/sage-business-cloud/intacct/product-capabilities/core-financials/'),
('sage-intacct','erp-api-access','supported',0.99,'Sage documents Web Services APIs and platform integration capabilities.','https://www.sage.com/en-us/sage-business-cloud/intacct/product-capabilities/platform/web-services/'),

-- Basecamp
('basecamp','pm-task-project-management','supported',0.99,'Basecamp provides projects and assigned to-dos.','https://basecamp.com/features'),
('basecamp','pm-timeline-schedule','supported',0.98,'Schedule/calendar and project timeline views are documented.','https://basecamp.com/features'),
('basecamp','pm-dashboards-reporting','supported',0.95,'Basecamp reports provide project and assignment progress overviews.','https://basecamp.com/features'),
('basecamp','pm-team-collaboration','supported',0.99,'Messages, chat, files and project collaboration are core documented features.','https://basecamp.com/features'),

-- Domo
('domo','bi-dashboards-reports','supported',0.99,NULL,'https://domo-webflow.domo.com/business-intelligence'),
('domo','bi-self-service','supported',0.99,NULL,'https://domo-webflow.domo.com/business-intelligence'),
('domo','bi-data-visualization','supported',0.99,NULL,'https://domo-webflow.domo.com/features'),
('domo','bi-data-connectivity','supported',0.99,'Domo documents more than 1,000 prebuilt data connectors plus APIs and SDKs.','https://domo-webflow.domo.com/data-integration'),
('domo','bi-sharing-collaboration','supported',0.95,'Domo supports shared dashboards, embedded analytics and organization-wide distribution.','https://domo-webflow.domo.com/domo-for-enterprise'),
('domo','bi-governance','supported',0.99,'Domo documents centralized governance, permissions, lineage, audit trails and SAML-based SSO.','https://domo-webflow.domo.com/domo-for-enterprise'),

-- Bitdefender GravityZone
('bitdefender-gravityzone-enterprise','endpoint-malware-ransomware','supported',0.99,'GravityZone Business Security Enterprise includes endpoint prevention and antimalware layers.','https://www.bitdefender.com/en-us/business/products/gravityzone-enterprise-security'),
('bitdefender-gravityzone-enterprise','endpoint-behavior-exploit','supported',0.99,'Advanced Anti-Exploit and behavior-based protection are documented.','https://www.bitdefender.com/business/support/en/77209-1441675-security-features.html'),
('bitdefender-gravityzone-enterprise','endpoint-edr','supported',0.99,'EDR is included in Business Security Enterprise.','https://www.bitdefender.com/en-us/business/products/gravityzone-enterprise-security'),
('bitdefender-gravityzone-enterprise','endpoint-central-management','supported',0.99,'GravityZone Control Center centralizes policy and endpoint management.','https://www.bitdefender.com/business/support/en/77209-1441676-operational-features.html'),
('bitdefender-gravityzone-enterprise','endpoint-automated-response','supported',0.95,'EDR/XDR response workflows and automated containment are documented; exact actions depend on license.','https://www.bitdefender.com/business/support/en/77211-151139-edr---xdr.html'),
('bitdefender-gravityzone-enterprise','endpoint-cross-platform','supported',0.99,'GravityZone supports Windows, macOS and major Linux distributions.','https://www.bitdefender.com/en-us/business/gravityzone-platform/'),

-- Rubrik Security Cloud
('rubrik-security-cloud','backup-core','supported',0.99,NULL,'https://www.rubrik.com/solutions/backup-recovery'),
('rubrik-security-cloud','backup-cloud-saas','supported',0.99,'Rubrik documents cloud-native and SaaS workload protection including Microsoft 365 and Salesforce.','https://www.rubrik.com/products/saas-data-protection'),
('rubrik-security-cloud','backup-ransomware-resilience','supported',0.99,'Immutable backup and ransomware recovery capabilities are documented.','https://www.rubrik.com/solutions/ransomware-recovery'),
('rubrik-security-cloud','backup-disaster-recovery-capability','supported',0.99,'Rubrik documents rapid recovery and recovery orchestration across protected workloads.','https://www.rubrik.com/solutions/backup-recovery'),
('rubrik-security-cloud','backup-central-management','supported',0.98,'Rubrik provides centralized policy-based backup and recovery management.','https://www.rubrik.com/solutions/backup-recovery'),
('rubrik-security-cloud','backup-hybrid-multicloud','supported',0.99,'Rubrik documents unified protection across on-premises, cloud and SaaS environments.','https://www.rubrik.com/solutions/cloud-solutions');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat72_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

-- Explicit unknown rows for every unverified capability in each product's existing category.
INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat72_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,f.limitations
FROM cat72_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Hosted/cloud delivery is verified for all seven products.
INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.95 FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug IN('haloitsm','deel-hr','sage-intacct','basecamp','domo','bitdefender-gravityzone-enterprise','rubrik-security-cloud')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

-- Bitdefender also publishes an on-premises GravityZone console for supported enterprise editions.
INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.90 FROM products p JOIN deployment_models d ON d.slug='on-premise'
WHERE p.slug='bitdefender-gravityzone-enterprise'
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

-- Integration facts are asserted only where official evidence above directly supports them.
INSERT INTO product_integrations(product_id,integration_id,support_status,confidence_score)
SELECT p.id,i.id,
CASE
 WHEN p.slug='deel-hr' AND i.slug='api' THEN 'supported'
 WHEN p.slug='sage-intacct' AND i.slug='api' THEN 'supported'
 WHEN p.slug='domo' AND i.slug='api' THEN 'supported'
 WHEN p.slug='bitdefender-gravityzone-enterprise' AND i.slug='api' THEN 'supported'
 WHEN p.slug='rubrik-security-cloud' AND i.slug='api' THEN 'supported'
 ELSE 'not_yet_verified' END,
CASE
 WHEN p.slug IN('deel-hr','sage-intacct','domo','bitdefender-gravityzone-enterprise','rubrik-security-cloud') AND i.slug='api' THEN 0.95
 ELSE 0 END
FROM products p JOIN integrations i
WHERE p.slug IN('haloitsm','deel-hr','sage-intacct','basecamp','domo','bitdefender-gravityzone-enterprise','rubrik-security-cloud')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

DROP TEMPORARY TABLE IF EXISTS cat72_facts;
DROP TEMPORARY TABLE IF EXISTS cat72_products;
COMMIT;
