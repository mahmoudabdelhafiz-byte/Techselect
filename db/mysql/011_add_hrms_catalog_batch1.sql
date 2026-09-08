-- TechSelectAI catalog expansion: HRMS/HCM batch 1
-- Adds Workday HCM, SAP SuccessFactors HCM, BambooHR, Rippling, Zoho People,
-- Odoo HR and Oracle Fusion Cloud HCM using official vendor documentation reviewed in Sep 2026.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('HR & HCM','hr-hcm','Human resources and human capital management software for employee records, onboarding, recruiting, performance, time, payroll, analytics and workforce lifecycle management.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @cat_id=(SELECT id FROM categories WHERE slug='hr-hcm' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@cat_id,'Core HR & Lifecycle','hr-core-lifecycle','Employee records, onboarding, offboarding and employee lifecycle management.',1),
(@cat_id,'Talent & Performance','hr-talent-performance','Recruiting, performance management, learning and talent processes.',1),
(@cat_id,'Time, Payroll & Workforce','hr-time-payroll','Time, attendance, leave, payroll and workforce administration.',1),
(@cat_id,'Analytics & Enterprise','hr-analytics-enterprise','Reporting, APIs, integrations and enterprise access.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.security,1
FROM modules m JOIN (
 SELECT 'hr-core-lifecycle' module_slug,'Core employee records' name,'hr-core-employee-records' slug,'Maintain employee profiles, employment data and organizational records.' description,0 security UNION ALL
 SELECT 'hr-core-lifecycle','Employee onboarding','hr-onboarding','Manage onboarding tasks, documents and new-hire workflows.',0 UNION ALL
 SELECT 'hr-core-lifecycle','Employee offboarding','hr-offboarding','Manage employee termination/offboarding workflows and lifecycle actions.',1 UNION ALL
 SELECT 'hr-talent-performance','Recruiting / applicant tracking','hr-recruiting','Manage job openings, candidates, applications and hiring workflows.',0 UNION ALL
 SELECT 'hr-talent-performance','Performance management','hr-performance-management','Manage goals, reviews, feedback and employee performance processes.',0 UNION ALL
 SELECT 'hr-talent-performance','Learning / talent development','hr-learning-development','Support employee learning, skills or talent development processes.',0 UNION ALL
 SELECT 'hr-time-payroll','Time & attendance','hr-time-attendance','Track employee time, attendance or workforce presence.',0 UNION ALL
 SELECT 'hr-time-payroll','Leave / absence management','hr-leave-absence','Manage leave, time off and absence workflows.',0 UNION ALL
 SELECT 'hr-time-payroll','Payroll','hr-payroll','Process payroll directly or through a native payroll module.',0 UNION ALL
 SELECT 'hr-analytics-enterprise','HR reports & analytics','hr-reports-analytics','Provide workforce reporting, dashboards and analytics.',0 UNION ALL
 SELECT 'hr-analytics-enterprise','API access','hr-api-access','Vendor-supported API access for HR data and integrations.',0 UNION ALL
 SELECT 'hr-analytics-enterprise','Single sign-on (SSO)','hr-sso','Enterprise single sign-on for HR users.',1
) x ON x.module_slug=m.slug
WHERE m.category_id=@cat_id
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Workday','workday','https://www.workday.com/','Enterprise cloud HCM and finance software vendor.','active'),
('SAP','sap','https://www.sap.com/','Enterprise applications and cloud software vendor.','active'),
('BambooHR','bamboohr','https://www.bamboohr.com/','HR software and people intelligence platform vendor.','active'),
('Rippling','rippling','https://www.rippling.com/','Workforce management, HR, payroll and IT platform vendor.','active'),
('Zoho','zoho','https://www.zoho.com/','Business software and HR application vendor.','active'),
('Odoo','odoo','https://www.odoo.com/','Open-source business application suite vendor.','active'),
('Oracle','oracle','https://www.oracle.com/','Enterprise database, cloud and business application vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,@cat_id,x.name,x.slug,x.description,x.url,'active',NOW()
FROM vendors v JOIN (
 SELECT 'workday' vendor_slug,'Workday HCM' name,'workday-hcm' slug,'Enterprise cloud HCM suite for core HR, recruiting, talent, workforce management, payroll and analytics.' description,'https://www.workday.com/en-us/products/human-capital-management/overview.html' url UNION ALL
 SELECT 'sap','SAP SuccessFactors HCM','sap-successfactors-hcm','Cloud HCM suite centered on Employee Central with recruiting, talent, payroll and integration capabilities.','https://www.sap.com/products/hcm.html' UNION ALL
 SELECT 'bamboohr','BambooHR','bamboohr','HR platform covering employee data, onboarding, hiring, performance, time, payroll and workforce analytics.','https://www.bamboohr.com/platform/' UNION ALL
 SELECT 'rippling','Rippling','rippling','Unified workforce platform for HR, onboarding, payroll, benefits, identity and employee lifecycle workflows.','https://www.rippling.com/' UNION ALL
 SELECT 'zoho','Zoho People','zoho-people','Cloud HRMS for employee records, onboarding, attendance, leave, performance and integrations.','https://www.zoho.com/people/' UNION ALL
 SELECT 'odoo','Odoo HR','odoo-hr','Open-source HR applications for employees, recruitment, onboarding, appraisals, attendance, leave and payroll-related workflows.','https://www.odoo.com/app/employees' UNION ALL
 SELECT 'oracle','Oracle Fusion Cloud HCM','oracle-fusion-cloud-hcm','Enterprise cloud HCM suite for HR, recruiting, talent, workforce management, payroll and integration.','https://www.oracle.com/human-capital-management/'
) x ON x.vendor_slug=v.slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',x.url,x.title,x.publisher,1,'verified','high',NOW()
FROM products p JOIN (
 SELECT 'workday-hcm' product_slug,'https://www.workday.com/en-us/products/human-capital-management/overview.html' url,'Workday Human Capital Management' title,'Workday' publisher UNION ALL
 SELECT 'workday-hcm','https://www.workday.com/en-us/topics/hr/human-capital-management-software.html','What is HCM software?','Workday' UNION ALL
 SELECT 'sap-successfactors-hcm','https://www.sap.com/products/hcm/employee-central-hris/technical-information.html','SAP SuccessFactors Employee Central technical information','SAP' UNION ALL
 SELECT 'sap-successfactors-hcm','https://help.sap.com/docs/successfactors-recruiting/sap-best-practices-for-sap-successfactors-recruiting/recruiting-with-integration-to-position-management-and-employee-central-3eg','SAP SuccessFactors Recruiting','SAP' UNION ALL
 SELECT 'bamboohr','https://www.bamboohr.com/platform/','BambooHR Platform','BambooHR' UNION ALL
 SELECT 'bamboohr','https://documentation.bamboohr.com/docs/getting-started','BambooHR API Getting Started','BambooHR' UNION ALL
 SELECT 'rippling','https://developer.rippling.com/documentation/rest-api/guides/hris-getting-started','Rippling HRIS API Getting Started','Rippling' UNION ALL
 SELECT 'zoho-people','https://www.zoho.com/people/api/overview.html','Zoho People API Overview','Zoho' UNION ALL
 SELECT 'zoho-people','https://www.zoho.com/people/api/onboarding.html','Zoho People Onboarding API','Zoho' UNION ALL
 SELECT 'odoo-hr','https://www.odoo.com/app/employees','Odoo Human Resources','Odoo' UNION ALL
 SELECT 'odoo-hr','https://www.odoo.com/app/employees-features','Odoo HR Features','Odoo' UNION ALL
 SELECT 'odoo-hr','https://www.odoo.com/app/appraisals','Odoo Appraisals','Odoo' UNION ALL
 SELECT 'oracle-fusion-cloud-hcm','https://www.oracle.com/human-capital-management/','Oracle Human Capital Management','Oracle' UNION ALL
 SELECT 'oracle-fusion-cloud-hcm','https://www.oracle.com/human-capital-management/talent-management/','Oracle Talent Management','Oracle' UNION ALL
 SELECT 'oracle-fusion-cloud-hcm','https://www.oracle.com/human-capital-management/payroll/','Oracle Fusion Cloud Payroll','Oracle' UNION ALL
 SELECT 'oracle-fusion-cloud-hcm','https://docs.oracle.com/en/cloud/saas/human-resources/api.html','Oracle Fusion Cloud HCM APIs','Oracle'
) x ON x.product_slug=p.slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=x.url);

DROP TEMPORARY TABLE IF EXISTS hr11_facts;
CREATE TEMPORARY TABLE hr11_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO hr11_facts VALUES
('workday-hcm','hr-core-employee-records','supported',0.99,NULL,'https://www.workday.com/en-us/products/human-capital-management/overview.html'),
('workday-hcm','hr-recruiting','supported',0.98,NULL,'https://www.workday.com/en-us/topics/hr/human-capital-management-software.html'),
('workday-hcm','hr-onboarding','supported',0.95,NULL,'https://www.workday.com/en-us/topics/hr/human-capital-management-software.html'),
('workday-hcm','hr-performance-management','supported',0.98,NULL,'https://www.workday.com/en-us/topics/hr/human-capital-management-software.html'),
('workday-hcm','hr-learning-development','supported',0.95,NULL,'https://www.workday.com/en-us/topics/hr/human-capital-management-software.html'),
('workday-hcm','hr-time-attendance','supported',0.95,NULL,'https://www.workday.com/en-us/topics/hr/human-capital-management-software.html'),
('workday-hcm','hr-leave-absence','supported',0.95,NULL,'https://www.workday.com/en-us/topics/hr/human-capital-management-software.html'),
('workday-hcm','hr-payroll','supported',0.95,'Payroll availability and country coverage vary by market and deployment scope.','https://www.workday.com/en-us/topics/hr/human-capital-management-software.html'),
('workday-hcm','hr-reports-analytics','supported',0.98,NULL,'https://www.workday.com/en-us/products/human-capital-management/overview.html'),

('sap-successfactors-hcm','hr-core-employee-records','supported',0.98,'Employee Central is the core HR system of record in the SuccessFactors suite.','https://www.sap.com/products/hcm/employee-central-hris/technical-information.html'),
('sap-successfactors-hcm','hr-recruiting','supported',0.99,NULL,'https://help.sap.com/docs/successfactors-recruiting/sap-best-practices-for-sap-successfactors-recruiting/recruiting-with-integration-to-position-management-and-employee-central-3eg'),
('sap-successfactors-hcm','hr-api-access','supported',0.95,'SAP documents APIs and prebuilt/custom integration options through Employee Central and SAP Business Accelerator Hub.','https://www.sap.com/products/hcm/employee-central-hris/technical-information.html'),

('bamboohr','hr-core-employee-records','supported',0.99,NULL,'https://www.bamboohr.com/platform/'),
('bamboohr','hr-onboarding','supported',0.99,NULL,'https://www.bamboohr.com/platform/'),
('bamboohr','hr-offboarding','supported',0.95,'BambooHR describes lifecycle coverage from hiring through offboarding.','https://www.bamboohr.com/platform/'),
('bamboohr','hr-recruiting','supported',0.98,NULL,'https://www.bamboohr.com/platform/'),
('bamboohr','hr-performance-management','supported',0.98,NULL,'https://www.bamboohr.com/platform/'),
('bamboohr','hr-time-attendance','supported',0.98,NULL,'https://www.bamboohr.com/platform/'),
('bamboohr','hr-payroll','supported',0.95,'Native BambooHR Payroll is primarily US-focused; international payroll can rely on partner integrations.','https://www.bamboohr.com/platform/'),
('bamboohr','hr-reports-analytics','supported',0.98,NULL,'https://www.bamboohr.com/platform/'),
('bamboohr','hr-api-access','supported',0.99,'BambooHR exposes a RESTful API with access constrained by user permissions.','https://documentation.bamboohr.com/docs/getting-started'),

('rippling','hr-core-employee-records','supported',0.95,'Rippling HRIS APIs expose worker, user and compensation records.','https://developer.rippling.com/documentation/rest-api/guides/hris-getting-started'),
('rippling','hr-onboarding','supported',0.95,'Bulk draft hire creation is documented in the HRIS API and Rippling positions the platform around employee lifecycle automation.','https://developer.rippling.com/documentation/rest-api/guides/hris-getting-started'),
('rippling','hr-api-access','supported',0.99,'Rippling HRIS APIs provide permission-scoped employee data access and write operations for selected workflows.','https://developer.rippling.com/documentation/rest-api/guides/hris-getting-started'),

('zoho-people','hr-onboarding','supported',0.99,'Zoho People exposes onboarding workflows and a dedicated onboarding API.','https://www.zoho.com/people/api/onboarding.html'),
('zoho-people','hr-time-attendance','supported',0.99,'Zoho People documents attendance APIs including check-in/check-out and attendance entries.','https://www.zoho.com/people/api/overview.html'),
('zoho-people','hr-api-access','supported',0.99,'Zoho People API supports extracting employee and form data and integrating third-party applications.','https://www.zoho.com/people/api/overview.html'),

('odoo-hr','hr-core-employee-records','supported',0.98,NULL,'https://www.odoo.com/app/employees'),
('odoo-hr','hr-onboarding','supported',0.98,NULL,'https://www.odoo.com/app/employees-features'),
('odoo-hr','hr-offboarding','supported',0.98,'Odoo HR provides configurable onboarding and offboarding plans that trigger preset activities.','https://www.odoo.com/app/employees-features'),
('odoo-hr','hr-recruiting','supported',0.98,NULL,'https://www.odoo.com/app/employees'),
('odoo-hr','hr-performance-management','supported',0.98,NULL,'https://www.odoo.com/app/appraisals'),
('odoo-hr','hr-time-attendance','supported',0.95,NULL,'https://www.odoo.com/app/employees'),
('odoo-hr','hr-leave-absence','supported',0.95,NULL,'https://www.odoo.com/app/employees-features'),

('oracle-fusion-cloud-hcm','hr-core-employee-records','supported',0.99,NULL,'https://www.oracle.com/human-capital-management/'),
('oracle-fusion-cloud-hcm','hr-recruiting','supported',0.99,NULL,'https://www.oracle.com/human-capital-management/talent-management/'),
('oracle-fusion-cloud-hcm','hr-onboarding','supported',0.98,NULL,'https://www.oracle.com/human-capital-management/talent-management/'),
('oracle-fusion-cloud-hcm','hr-performance-management','supported',0.99,NULL,'https://www.oracle.com/human-capital-management/talent-management/'),
('oracle-fusion-cloud-hcm','hr-learning-development','supported',0.98,NULL,'https://www.oracle.com/human-capital-management/talent-management/'),
('oracle-fusion-cloud-hcm','hr-payroll','supported',0.99,'Oracle Payroll supports more than 60 countries; country-specific coverage must still be confirmed for each deployment.','https://www.oracle.com/human-capital-management/payroll/'),
('oracle-fusion-cloud-hcm','hr-api-access','supported',0.99,'Oracle Fusion Cloud HCM provides REST APIs for viewing and managing HCM data.','https://docs.oracle.com/en/cloud/saas/human-resources/api.html');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM hr11_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,c.id,NULL,'not_yet_verified',0
FROM products p CROSS JOIN capabilities c JOIN modules m ON m.id=c.module_id
WHERE p.slug IN('workday-hcm','sap-successfactors-hcm','bamboohr','rippling','zoho-people','odoo-hr','oracle-fusion-cloud-hcm')
AND m.category_id=@cat_id
AND NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,f.limitations
FROM hr11_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.95 FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug IN('workday-hcm','sap-successfactors-hcm','bamboohr','rippling','zoho-people','odoo-hr','oracle-fusion-cloud-hcm')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.90 FROM products p JOIN deployment_models d ON d.slug IN('self-hosted','on-premise') WHERE p.slug='odoo-hr'
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

INSERT INTO product_integrations(product_id,integration_id,support_status,confidence_score)
SELECT p.id,i.id,
CASE
 WHEN i.slug='api' AND p.slug IN('bamboohr','rippling','zoho-people','oracle-fusion-cloud-hcm') THEN 'supported'
 ELSE 'not_yet_verified' END,
CASE WHEN i.slug='api' AND p.slug IN('bamboohr','rippling','zoho-people','oracle-fusion-cloud-hcm') THEN 0.97 ELSE 0 END
FROM products p JOIN integrations i
WHERE p.slug IN('workday-hcm','sap-successfactors-hcm','bamboohr','rippling','zoho-people','odoo-hr','oracle-fusion-cloud-hcm')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

COMMIT;
