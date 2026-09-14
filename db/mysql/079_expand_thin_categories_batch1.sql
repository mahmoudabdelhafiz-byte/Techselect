-- TechSelectAI catalog expansion: thinner existing categories batch 1
-- Adds eight recognizable products using official first-party evidence reviewed in Sep 2026.
-- Reuses existing taxonomy and preserves Unknown != Unsupported.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Palo Alto Networks','palo-alto-networks','https://www.paloaltonetworks.com/','Enterprise cybersecurity and security-operations platform vendor.','active'),
('OneLogin','onelogin','https://www.onelogin.com/','Workforce identity and access management vendor.','active'),
('One Identity','one-identity','https://www.oneidentity.com/','Identity governance and privileged access management vendor.','active'),
('Infor','infor','https://www.infor.com/','Enterprise ERP, supply-chain and warehouse-management software vendor.','active'),
('ServiceNow','servicenow','https://www.servicenow.com/','Enterprise workflow, IT service management and application-platform vendor.','active'),
('Creatio','creatio','https://www.creatio.com/','CRM, workflow automation and no-code platform vendor.','active'),
('Paycom','paycom','https://www.paycom.com/','Human capital management, payroll and workforce software vendor.','active'),
('IFS','ifs','https://www.ifs.com/','Enterprise ERP, asset, service and industrial software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat79_products;
CREATE TEMPORARY TABLE cat79_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO cat79_products VALUES
('palo-alto-networks','siem-security-operations','Cortex XSIAM','cortex-xsiam','AI-driven security operations platform combining unified security data, SIEM, detection, investigation, automation and response.','https://www.paloaltonetworks.com/cortex/cortex-xsiam'),
('onelogin','identity-access-management','OneLogin Workforce Identity','onelogin-workforce-identity','Workforce identity and access management platform for SSO, MFA, adaptive authentication, directory services and lifecycle provisioning.','https://www.onelogin.com/solutions/workforce-iam'),
('one-identity','privileged-access-management','One Identity Safeguard for Privileged Passwords','one-identity-safeguard-privileged-passwords','Privileged password management platform for discovering, vaulting, controlling and governing access to privileged credentials and systems.','https://www.oneidentity.com/one-identity-safeguard/'),
('infor','warehouse-management-systems','Infor WMS','infor-wms','Cloud warehouse management platform for inventory visibility, receiving, put-away, picking, packing, shipping, labor, automation and warehouse optimization.','https://www.infor.com/mea/solutions/scm/warehouse-management-system'),
('servicenow','low-code-bpm','ServiceNow App Engine','servicenow-app-engine','Enterprise low-code application platform for visual development, workflow automation, web and mobile experiences, APIs, integrations and governed delivery.','https://www.servicenow.com/products/application-development.html'),
('creatio','crm','Creatio Sales','creatio-sales','AI-enabled sales CRM for lead management, opportunity pipelines, guided selling, forecasting, workflow automation and customer-data orchestration.','https://www.creatio.com/sales'),
('paycom','hr-hcm','Paycom','paycom','Single-database HR and payroll platform covering employee records, payroll, time and attendance and broader HR administration.','https://www.paycom.com/software/'),
('ifs','erp','IFS Cloud ERP','ifs-cloud-erp','Industrial ERP for finance, procurement, supply chain, manufacturing, projects, operations and real-time analytics.','https://www.ifs.com/en/products/erp');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat79_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',x.url,x.title,x.publisher,1,'verified','high',NOW()
FROM products p JOIN (
 SELECT 'cortex-xsiam' product_slug,'https://www.paloaltonetworks.com/cortex/cortex-xsiam' url,'Cortex XSIAM' title,'Palo Alto Networks' publisher UNION ALL
 SELECT 'onelogin-workforce-identity','https://www.onelogin.com/solutions/workforce-iam','OneLogin Workforce IAM','OneLogin' UNION ALL
 SELECT 'onelogin-workforce-identity','https://www.onelogin.com/product/identity-lifecycle-management','OneLogin Identity Lifecycle Management','OneLogin' UNION ALL
 SELECT 'one-identity-safeguard-privileged-passwords','https://www.oneidentity.com/one-identity-safeguard/','One Identity Safeguard products','One Identity' UNION ALL
 SELECT 'one-identity-safeguard-privileged-passwords','https://support.oneidentity.com/technical-documents/one-identity-safeguard-for-privileged-passwords/7.3/administration-guide','Safeguard for Privileged Passwords Administration Guide','One Identity' UNION ALL
 SELECT 'infor-wms','https://www.infor.com/mea/solutions/scm/warehouse-management-system','Infor WMS','Infor' UNION ALL
 SELECT 'infor-wms','https://docs.infor.com/lncs/latest/en-us/lncslib/lncspov/wzu1564481459702.html','Infor WMS overview','Infor' UNION ALL
 SELECT 'servicenow-app-engine','https://www.servicenow.com/products/application-development.html','ServiceNow Application Development','ServiceNow' UNION ALL
 SELECT 'servicenow-app-engine','https://www.servicenow.com/products/app-engine-studio.html','ServiceNow App Engine Studio','ServiceNow' UNION ALL
 SELECT 'creatio-sales','https://www.creatio.com/sales','Creatio Sales','Creatio' UNION ALL
 SELECT 'paycom','https://www.paycom.com/software/','Paycom HCM software','Paycom' UNION ALL
 SELECT 'paycom','https://www.paycom.com/software/hr-management/','Paycom HR Management','Paycom' UNION ALL
 SELECT 'paycom','https://www.paycom.com/software/time-and-attendance/','Paycom Time and Attendance','Paycom' UNION ALL
 SELECT 'ifs-cloud-erp','https://www.ifs.com/en/products/erp','IFS Cloud ERP','IFS' UNION ALL
 SELECT 'ifs-cloud-erp','https://www.ifs.com/en/products/erp/finance','IFS Cloud Finance','IFS' UNION ALL
 SELECT 'ifs-cloud-erp','https://www.ifs.com/en/products/erp/supply-chain','IFS Cloud Supply Chain','IFS' UNION ALL
 SELECT 'ifs-cloud-erp','https://www.ifs.com/en/products/erp/projects','IFS Cloud Project Management','IFS'
) x ON x.product_slug=p.slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=x.url);

DROP TEMPORARY TABLE IF EXISTS cat79_facts;
CREATE TEMPORARY TABLE cat79_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat79_facts VALUES
-- Cortex XSIAM
('cortex-xsiam','siem-data-ingestion','supported',0.99,'Cortex XSIAM centralizes telemetry from endpoint, network, identity, cloud and third-party sources.','https://www.paloaltonetworks.com/cortex/cortex-xsiam'),
('cortex-xsiam','siem-threat-detection','supported',0.99,'Official product material documents analytics-driven threat detection across unified security data.','https://www.paloaltonetworks.com/cortex/cortex-xsiam'),
('cortex-xsiam','siem-investigation-hunting','supported',0.99,'XSIAM provides unified investigation and attack-story context for prioritized incidents.','https://www.paloaltonetworks.com/cortex/cortex-xsiam'),
('cortex-xsiam','siem-soar','supported',0.99,'SOAR and security automation are explicitly included in the XSIAM platform.','https://www.paloaltonetworks.com/cortex/cortex-xsiam'),
('cortex-xsiam','siem-behavior-risk','supported',0.95,'The platform applies AI, analytics models and contextual security intelligence; exact entity-risk functions depend on licensed capabilities.','https://www.paloaltonetworks.com/cortex/cortex-xsiam'),

-- OneLogin Workforce Identity
('onelogin-workforce-identity','iam-sso','supported',0.99,NULL,'https://www.onelogin.com/solutions/workforce-iam'),
('onelogin-workforce-identity','iam-mfa','supported',0.99,NULL,'https://www.onelogin.com/solutions/workforce-iam'),
('onelogin-workforce-identity','iam-conditional-access','supported',0.98,'SmartFactor authentication uses contextual risk signals to adapt authentication flows.','https://www.onelogin.com/solutions/workforce-iam'),
('onelogin-workforce-identity','iam-lifecycle-provisioning','supported',0.99,'Automated onboarding, offboarding and downstream application provisioning are documented.','https://www.onelogin.com/product/identity-lifecycle-management'),
('onelogin-workforce-identity','iam-directory','supported',0.99,'OneLogin provides a centralized cloud directory with synchronization to enterprise directories.','https://www.onelogin.com/solutions/workforce-iam'),

-- One Identity Safeguard for Privileged Passwords
('one-identity-safeguard-privileged-passwords','pam-vault','supported',0.99,'Safeguard for Privileged Passwords is documented as a vault for privileged passwords, keys and secrets.','https://support.oneidentity.com/technical-documents/one-identity-safeguard-for-privileged-passwords/7.3/administration-guide'),
('one-identity-safeguard-privileged-passwords','pam-discovery','supported',0.98,'Quick discovery and onboarding of assets are documented product capabilities.','https://www.oneidentity.com/one-identity-safeguard/'),
('one-identity-safeguard-privileged-passwords','pam-rotation','supported',0.95,'The administration model includes managed-account password check/change controls; rotation policies should be confirmed for the target deployment.','https://support.oneidentity.com/technical-documents/one-identity-safeguard-for-privileged-passwords/7.3/administration-guide'),

-- Infor WMS
('infor-wms','wms-inventory-visibility','supported',0.99,'Infor documents real-time inventory visibility down to bin/location level.','https://www.infor.com/mea/solutions/scm/warehouse-management-system'),
('infor-wms','wms-inbound','supported',0.99,'Receiving, put-away, cross-docking and related inbound workflows are explicitly documented.','https://www.infor.com/mea/solutions/scm/warehouse-management-system'),
('infor-wms','wms-outbound','supported',0.99,'Picking, packing, shipping, wave management and replenishment are documented.','https://www.infor.com/mea/solutions/scm/warehouse-management-system'),
('infor-wms','wms-automation','supported',0.99,'Infor WMS explicitly supports integration with warehouse automation systems.','https://www.infor.com/mea/solutions/scm/warehouse-management-system'),
('infor-wms','wms-optimization-orchestration','supported',0.99,'Labor management, task automation, pick-path optimization and operational orchestration are documented.','https://www.infor.com/mea/solutions/scm/warehouse-management-system'),

-- ServiceNow App Engine
('servicenow-app-engine','lowcode-visual-development','supported',0.99,'App Engine Studio is a visual low-code application environment.','https://www.servicenow.com/products/app-engine-studio.html'),
('servicenow-app-engine','lowcode-web-mobile','supported',0.99,'ServiceNow documents web workspaces plus native mobile experience design and delivery.','https://www.servicenow.com/products/application-development.html'),
('servicenow-app-engine','lowcode-workflow-automation','supported',0.99,'Flow Designer and visual workflow automation are documented App Engine capabilities.','https://www.servicenow.com/products/application-development.html'),
('servicenow-app-engine','lowcode-integrations','supported',0.99,'Common and custom APIs plus native third-party system connections are documented.','https://www.servicenow.com/products/application-development.html'),
('servicenow-app-engine','lowcode-governance','supported',0.99,'App Engine Management Center, delegated development and enterprise guardrails are documented.','https://www.servicenow.com/products/app-engine-studio.html'),

-- Creatio Sales
('creatio-sales','crm-lead-management','supported',0.99,'Creatio documents lead capture, scoring and engagement within the sales platform.','https://www.creatio.com/sales'),
('creatio-sales','crm-contact-account-management','supported',0.95,'The sales platform uses connected customer data and account context throughout the sales cycle.','https://www.creatio.com/sales'),
('creatio-sales','crm-opportunity-pipeline','supported',0.99,'Creatio documents qualification, nurturing and opportunity pipeline management.','https://www.creatio.com/sales'),
('creatio-sales','crm-sales-automation','supported',0.99,'AI agents and workflow automation are core documented sales-platform functions.','https://www.creatio.com/sales'),
('creatio-sales','crm-sales-forecasting','supported',0.99,'A dedicated Forecast Agent and sales forecasting are explicitly documented.','https://www.creatio.com/sales'),

-- Paycom
('paycom','hr-core-employee-records','supported',0.99,'Paycom documents a single database for workforce and HR data.','https://www.paycom.com/software/hr-management/'),
('paycom','hr-payroll','supported',0.99,'Payroll is a core component of Paycom''s single HR and payroll software platform.','https://www.paycom.com/software/'),
('paycom','hr-time-attendance','supported',0.99,'Paycom provides dedicated time and attendance software integrated with payroll.','https://www.paycom.com/software/time-and-attendance/'),

-- IFS Cloud ERP
('ifs-cloud-erp','erp-financial-accounting','supported',0.99,'IFS Cloud Finance covers financial operations, accounting, budgeting and forecasting.','https://www.ifs.com/en/products/erp/finance'),
('ifs-cloud-erp','erp-budgeting-planning','supported',0.98,'IFS explicitly documents budgeting and forecasting within its finance capabilities.','https://www.ifs.com/en/products/erp/finance'),
('ifs-cloud-erp','erp-procurement','supported',0.99,'Procurement is an explicitly documented IFS Cloud ERP feature area.','https://www.ifs.com/en/products/erp'),
('ifs-cloud-erp','erp-supply-chain-planning','supported',0.99,'IFS Cloud includes supply-chain planning and execution capabilities.','https://www.ifs.com/en/products/erp/supply-chain'),
('ifs-cloud-erp','erp-manufacturing','supported',0.99,'Manufacturing scheduling and execution are explicitly documented.','https://www.ifs.com/en/products/erp'),
('ifs-cloud-erp','erp-project-operations','supported',0.99,'IFS Cloud provides integrated project planning, execution, financial control and asset/project visibility.','https://www.ifs.com/en/products/erp/projects'),
('ifs-cloud-erp','erp-reports-dashboards','supported',0.98,'Real-time data, analytics, interactive lobbies and operational performance visibility are documented.','https://www.ifs.com/en/products/erp');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat79_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat79_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,f.limitations
FROM cat79_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Conservative deployment facts only where the official product positioning is explicit.
INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.95 FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug IN('onelogin-workforce-identity','infor-wms','servicenow-app-engine','creatio-sales','paycom','ifs-cloud-erp')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.99 FROM products p JOIN deployment_models d ON d.slug='on-premise'
WHERE p.slug='one-identity-safeguard-privileged-passwords'
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

-- Product-specific integrations are not reviewed in this batch; preserve explicit unknowns.
INSERT INTO product_integrations(product_id,integration_id,support_status,confidence_score)
SELECT p.id,i.id,'not_yet_verified',0 FROM products p JOIN integrations i
WHERE p.slug IN('cortex-xsiam','onelogin-workforce-identity','one-identity-safeguard-privileged-passwords','infor-wms','servicenow-app-engine','creatio-sales','paycom','ifs-cloud-erp')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

DROP TEMPORARY TABLE IF EXISTS cat79_facts;
DROP TEMPORARY TABLE IF EXISTS cat79_products;
COMMIT;
