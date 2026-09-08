-- TechSelectAI catalog expansion: ERP batch 1
-- Adds SAP S/4HANA Cloud, Dynamics 365 Finance & Supply Chain Management,
-- Oracle Fusion Cloud ERP, Odoo ERP, Oracle NetSuite and Sage X3.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('ERP','erp','Enterprise resource planning software for finance, procurement, inventory, supply chain, manufacturing, projects and business operations.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @cat_id=(SELECT id FROM categories WHERE slug='erp' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@cat_id,'Finance & Accounting','erp-finance','General ledger, accounts payable/receivable, budgeting and financial reporting.',1),
(@cat_id,'Procurement & Supply Chain','erp-supply-chain','Purchasing, inventory, warehouse and supply-chain operations.',1),
(@cat_id,'Manufacturing & Projects','erp-operations','Manufacturing, planning and project-oriented operations.',1),
(@cat_id,'Analytics & Enterprise','erp-enterprise','Reporting, workflow, APIs and enterprise access.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.security,1
FROM modules m JOIN (
 SELECT 'erp-finance' module_slug,'General ledger & financial accounting' name,'erp-financial-accounting' slug,'Core accounting, journals, ledgers and financial close.' description,0 security UNION ALL
 SELECT 'erp-finance','Accounts payable & receivable','erp-ap-ar','Supplier invoices, customer receivables and payment workflows.',0 UNION ALL
 SELECT 'erp-finance','Budgeting & planning','erp-budgeting-planning','Budgeting, planning and financial forecasting capabilities.',0 UNION ALL
 SELECT 'erp-supply-chain','Procurement','erp-procurement','Purchasing, sourcing, supplier and procurement workflows.',0 UNION ALL
 SELECT 'erp-supply-chain','Inventory & warehouse management','erp-inventory-warehouse','Inventory visibility, warehouse operations and stock control.',0 UNION ALL
 SELECT 'erp-supply-chain','Supply chain planning','erp-supply-chain-planning','Demand, supply and replenishment planning.',0 UNION ALL
 SELECT 'erp-operations','Manufacturing management','erp-manufacturing','Production planning, manufacturing execution or shop-floor management.',0 UNION ALL
 SELECT 'erp-operations','Project accounting / project operations','erp-project-operations','Project costing, billing or project-oriented financial operations.',0 UNION ALL
 SELECT 'erp-enterprise','Reports & dashboards','erp-reports-dashboards','Operational and financial reporting and dashboards.',0 UNION ALL
 SELECT 'erp-enterprise','Workflow automation','erp-workflow-automation','Configurable business process approvals and automation.',0 UNION ALL
 SELECT 'erp-enterprise','API access','erp-api-access','Vendor-supported APIs for integrations and extensibility.',0 UNION ALL
 SELECT 'erp-enterprise','Single sign-on (SSO)','erp-sso','Enterprise single sign-on for ERP users.',1
) x ON x.module_slug=m.slug
WHERE m.category_id=@cat_id
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('SAP','sap','https://www.sap.com/','Enterprise application and ERP software vendor.','active'),
('Microsoft','microsoft','https://www.microsoft.com/','Enterprise software and cloud platform vendor.','active'),
('Oracle','oracle','https://www.oracle.com/','Enterprise database, cloud and application software vendor.','active'),
('Odoo','odoo','https://www.odoo.com/','Open-source business application suite vendor.','active'),
('NetSuite','netsuite','https://www.netsuite.com/','Oracle cloud ERP and business management platform.','active'),
('Sage','sage','https://www.sage.com/','Accounting, ERP and business management software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,@cat_id,x.name,x.slug,x.description,x.url,'active',NOW()
FROM vendors v JOIN (
 SELECT 'sap' vendor_slug,'SAP S/4HANA Cloud' name,'sap-s4hana-cloud' slug,'Enterprise cloud ERP for finance, sourcing, procurement, supply chain, manufacturing, asset and service operations.' description,'https://www.sap.com/products/erp/s4hana.html' url UNION ALL
 SELECT 'microsoft','Dynamics 365 Finance & Supply Chain Management','dynamics-365-finance-scm','Microsoft cloud ERP for financial management, procurement, inventory, manufacturing and supply-chain operations.','https://www.microsoft.com/en-us/dynamics-365/products/finance' UNION ALL
 SELECT 'oracle','Oracle Fusion Cloud ERP','oracle-fusion-cloud-erp','Cloud ERP suite for financials, procurement, project management, risk, analytics and enterprise operations.','https://www.oracle.com/erp/' UNION ALL
 SELECT 'odoo','Odoo ERP','odoo-erp','Integrated open-source business suite covering accounting, sales, purchasing, inventory, manufacturing, projects and more.','https://www.odoo.com/' UNION ALL
 SELECT 'netsuite','Oracle NetSuite','oracle-netsuite','Cloud ERP and business management suite for financials, order management, inventory, procurement and operations.','https://www.netsuite.com/portal/products/erp.shtml' UNION ALL
 SELECT 'sage','Sage X3','sage-x3','Enterprise management and ERP software for finance, distribution, supply chain and manufacturing operations.','https://www.sage.com/en-us/products/sage-x3/'
) x ON x.vendor_slug=v.slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',x.url,x.title,x.publisher,1,'verified','high',NOW()
FROM products p JOIN (
 SELECT 'sap-s4hana-cloud' product_slug,'https://www.sap.com/products/erp/s4hana.html' url,'SAP S/4HANA Cloud' title,'SAP' publisher UNION ALL
 SELECT 'dynamics-365-finance-scm','https://www.microsoft.com/en-us/dynamics-365/products/finance','Dynamics 365 Finance','Microsoft' UNION ALL
 SELECT 'dynamics-365-finance-scm','https://www.microsoft.com/en-us/dynamics-365/products/supply-chain-management','Dynamics 365 Supply Chain Management','Microsoft' UNION ALL
 SELECT 'oracle-fusion-cloud-erp','https://www.oracle.com/erp/','Oracle Fusion Cloud ERP','Oracle' UNION ALL
 SELECT 'odoo-erp','https://www.odoo.com/page/all-apps','Odoo Business Applications','Odoo' UNION ALL
 SELECT 'odoo-erp','https://www.odoo.com/documentation/19.0/developer/reference/external_api.html','Odoo External API','Odoo' UNION ALL
 SELECT 'oracle-netsuite','https://www.netsuite.com/portal/products/erp.shtml','NetSuite ERP','Oracle NetSuite' UNION ALL
 SELECT 'sage-x3','https://www.sage.com/en-us/products/sage-x3/','Sage X3','Sage'
) x ON x.product_slug=p.slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=x.url);

DROP TEMPORARY TABLE IF EXISTS erp12_facts;
CREATE TEMPORARY TABLE erp12_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO erp12_facts VALUES
('sap-s4hana-cloud','erp-financial-accounting','supported',0.99,NULL,'https://www.sap.com/products/erp/s4hana.html'),
('sap-s4hana-cloud','erp-procurement','supported',0.98,NULL,'https://www.sap.com/products/erp/s4hana.html'),
('sap-s4hana-cloud','erp-inventory-warehouse','supported',0.98,'Warehouse depth may depend on scope and adjacent SAP supply-chain capabilities.','https://www.sap.com/products/erp/s4hana.html'),
('sap-s4hana-cloud','erp-manufacturing','supported',0.99,NULL,'https://www.sap.com/products/erp/s4hana.html'),
('sap-s4hana-cloud','erp-reports-dashboards','supported',0.95,'Analytics depth can vary by edition and connected SAP analytics services.','https://www.sap.com/products/erp/s4hana.html'),

('dynamics-365-finance-scm','erp-financial-accounting','supported',0.99,NULL,'https://www.microsoft.com/en-us/dynamics-365/products/finance'),
('dynamics-365-finance-scm','erp-ap-ar','supported',0.98,NULL,'https://www.microsoft.com/en-us/dynamics-365/products/finance'),
('dynamics-365-finance-scm','erp-budgeting-planning','supported',0.95,NULL,'https://www.microsoft.com/en-us/dynamics-365/products/finance'),
('dynamics-365-finance-scm','erp-procurement','supported',0.98,NULL,'https://www.microsoft.com/en-us/dynamics-365/products/supply-chain-management'),
('dynamics-365-finance-scm','erp-inventory-warehouse','supported',0.99,NULL,'https://www.microsoft.com/en-us/dynamics-365/products/supply-chain-management'),
('dynamics-365-finance-scm','erp-supply-chain-planning','supported',0.98,NULL,'https://www.microsoft.com/en-us/dynamics-365/products/supply-chain-management'),
('dynamics-365-finance-scm','erp-manufacturing','supported',0.98,NULL,'https://www.microsoft.com/en-us/dynamics-365/products/supply-chain-management'),

('oracle-fusion-cloud-erp','erp-financial-accounting','supported',0.99,NULL,'https://www.oracle.com/erp/'),
('oracle-fusion-cloud-erp','erp-ap-ar','supported',0.98,NULL,'https://www.oracle.com/erp/'),
('oracle-fusion-cloud-erp','erp-procurement','supported',0.98,NULL,'https://www.oracle.com/erp/'),
('oracle-fusion-cloud-erp','erp-project-operations','supported',0.98,NULL,'https://www.oracle.com/erp/'),
('oracle-fusion-cloud-erp','erp-reports-dashboards','supported',0.95,NULL,'https://www.oracle.com/erp/'),
('oracle-fusion-cloud-erp','erp-workflow-automation','supported',0.95,'Automation and AI features depend on licensed services and configuration.','https://www.oracle.com/erp/'),

('odoo-erp','erp-financial-accounting','supported',0.98,NULL,'https://www.odoo.com/page/all-apps'),
('odoo-erp','erp-procurement','supported',0.98,NULL,'https://www.odoo.com/page/all-apps'),
('odoo-erp','erp-inventory-warehouse','supported',0.99,NULL,'https://www.odoo.com/page/all-apps'),
('odoo-erp','erp-manufacturing','supported',0.99,NULL,'https://www.odoo.com/page/all-apps'),
('odoo-erp','erp-project-operations','supported',0.95,'Project and accounting functions are available as integrated Odoo applications; exact scope depends on installed apps.','https://www.odoo.com/page/all-apps'),
('odoo-erp','erp-api-access','supported',0.95,'External API availability depends on deployment and subscription; current JSON-2 API replaces older RPC APIs.','https://www.odoo.com/documentation/19.0/developer/reference/external_api.html'),

('oracle-netsuite','erp-financial-accounting','supported',0.99,NULL,'https://www.netsuite.com/portal/products/erp.shtml'),
('oracle-netsuite','erp-ap-ar','supported',0.98,NULL,'https://www.netsuite.com/portal/products/erp.shtml'),
('oracle-netsuite','erp-procurement','supported',0.95,NULL,'https://www.netsuite.com/portal/products/erp.shtml'),
('oracle-netsuite','erp-inventory-warehouse','supported',0.95,NULL,'https://www.netsuite.com/portal/products/erp.shtml'),
('oracle-netsuite','erp-reports-dashboards','supported',0.95,NULL,'https://www.netsuite.com/portal/products/erp.shtml'),

('sage-x3','erp-financial-accounting','supported',0.98,NULL,'https://www.sage.com/en-us/products/sage-x3/'),
('sage-x3','erp-procurement','supported',0.95,NULL,'https://www.sage.com/en-us/products/sage-x3/'),
('sage-x3','erp-inventory-warehouse','supported',0.98,NULL,'https://www.sage.com/en-us/products/sage-x3/'),
('sage-x3','erp-manufacturing','supported',0.98,NULL,'https://www.sage.com/en-us/products/sage-x3/'),
('sage-x3','erp-reports-dashboards','supported',0.90,NULL,'https://www.sage.com/en-us/products/sage-x3/');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM erp12_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,c.id,NULL,'not_yet_verified',0
FROM products p CROSS JOIN capabilities c JOIN modules m ON m.id=c.module_id
WHERE p.slug IN('sap-s4hana-cloud','dynamics-365-finance-scm','oracle-fusion-cloud-erp','odoo-erp','oracle-netsuite','sage-x3')
AND m.category_id=@cat_id
AND NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,f.limitations
FROM erp12_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.95 FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug IN('sap-s4hana-cloud','dynamics-365-finance-scm','oracle-fusion-cloud-erp','odoo-erp','oracle-netsuite','sage-x3')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.90 FROM products p JOIN deployment_models d ON d.slug IN('self-hosted','on-premise') WHERE p.slug='odoo-erp'
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

INSERT INTO product_integrations(product_id,integration_id,support_status,confidence_score)
SELECT p.id,i.id,
CASE
 WHEN i.slug='microsoft-365' AND p.slug='dynamics-365-finance-scm' THEN 'supported'
 WHEN i.slug='api' AND p.slug='odoo-erp' THEN 'supported'
 ELSE 'not_yet_verified' END,
CASE
 WHEN i.slug='microsoft-365' AND p.slug='dynamics-365-finance-scm' THEN 0.95
 WHEN i.slug='api' AND p.slug='odoo-erp' THEN 0.95
 ELSE 0 END
FROM products p JOIN integrations i
WHERE p.slug IN('sap-s4hana-cloud','dynamics-365-finance-scm','oracle-fusion-cloud-erp','odoo-erp','oracle-netsuite','sage-x3')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

COMMIT;
