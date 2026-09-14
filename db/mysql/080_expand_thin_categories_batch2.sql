-- TechSelectAI catalog expansion: thinner categories batch 2
-- Adds five recognizable products to existing SIEM, IAM, PAM, WMS and Low-Code/BPM categories.
-- Official first-party evidence only. Unknown != Unsupported.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Exabeam','exabeam','https://www.exabeam.com/','Security operations and SIEM software vendor.','active'),
('SailPoint','sailpoint','https://www.sailpoint.com/','Identity security and governance software vendor.','active'),
('WALLIX','wallix','https://www.wallix.com/','Privileged access management and identity security vendor.','active'),
('Körber Supply Chain','koerber-supply-chain','https://koerber-supplychain.com/','Warehouse and supply-chain software vendor.','active'),
('Pegasystems','pegasystems','https://www.pega.com/','Enterprise workflow, process automation and low-code application platform vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat80_products;
CREATE TEMPORARY TABLE cat80_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO cat80_products VALUES
('exabeam','siem-security-operations','Exabeam New-Scale SIEM','exabeam-new-scale-siem','Cloud-native SIEM for high-volume security data ingestion, detection, investigation, behavioral analytics, risk scoring and automated response.','https://www.exabeam.com/platform/new-scale-siem/'),
('sailpoint','identity-access-management','SailPoint Identity Security Cloud','sailpoint-identity-security-cloud','Cloud identity security platform for centralized identity visibility, access governance, lifecycle provisioning, deprovisioning and least-privilege controls.','https://www.sailpoint.com/products/identity-security-cloud/atlas/capabilities/lifecycle-management'),
('wallix','privileged-access-management','WALLIX Bastion','wallix-bastion','Privileged access management platform for privileged credential discovery, password management and rotation, session control, monitoring and audit.','https://www.wallix.com/products/privileged-access-management/'),
('koerber-supply-chain','warehouse-management-systems','Körber Warehouse Management','koerber-warehouse-management','Warehouse management software portfolio for receiving, put-away, inventory, slotting, picking, packing, shipping, labor and automation integration.','https://koerber-supplychain.com/supply-chain-solutions/supply-chain-software/warehouse-management/'),
('pegasystems','low-code-bpm','Pega Platform','pega-platform','Enterprise low-code application and workflow platform for visual development, process automation and web/mobile application delivery.','https://www.pega.com/products/platform/ai-app-development');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat80_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',x.url,x.title,x.publisher,1,'verified','high',NOW()
FROM products p JOIN (
 SELECT 'exabeam-new-scale-siem' product_slug,'https://www.exabeam.com/platform/new-scale-siem/' url,'Exabeam New-Scale SIEM' title,'Exabeam' publisher UNION ALL
 SELECT 'exabeam-new-scale-siem','https://docs.exabeam.com/new-scale-security-operations-platform/','Exabeam New-Scale Security Operations Platform Documentation','Exabeam' UNION ALL
 SELECT 'sailpoint-identity-security-cloud','https://www.sailpoint.com/products/identity-security-cloud/atlas/capabilities/lifecycle-management','SailPoint Identity Security Cloud Lifecycle Management','SailPoint' UNION ALL
 SELECT 'sailpoint-identity-security-cloud','https://documentation.sailpoint.com/saas/help/access/index.html','SailPoint Identity Security Cloud Access Overview','SailPoint' UNION ALL
 SELECT 'wallix-bastion','https://www.wallix.com/products/privileged-access-management/','WALLIX Privileged Access Management','WALLIX' UNION ALL
 SELECT 'koerber-warehouse-management','https://koerber-supplychain.com/supply-chain-solutions/supply-chain-software/warehouse-management/','Körber Warehouse Management','Körber Supply Chain' UNION ALL
 SELECT 'pega-platform','https://www.pega.com/products/platform/ai-app-development','Pega AI-powered App Development','Pegasystems' UNION ALL
 SELECT 'pega-platform','https://www.pega.com/low-code/application-development','Pega Low-code Application Development','Pegasystems'
) x ON x.product_slug=p.slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=x.url);

DROP TEMPORARY TABLE IF EXISTS cat80_facts;
CREATE TEMPORARY TABLE cat80_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat80_facts VALUES
-- Exabeam New-Scale SIEM
('exabeam-new-scale-siem','siem-data-ingestion','supported',0.99,'Official material documents ingestion from cloud, on-premises and third-party sources.','https://www.exabeam.com/platform/new-scale-siem/'),
('exabeam-new-scale-siem','siem-threat-detection','supported',0.99,'Real-time analytics, detection correlation and risk scoring are documented.','https://www.exabeam.com/platform/new-scale-siem/'),
('exabeam-new-scale-siem','siem-investigation-hunting','supported',0.99,'High-performance search, timelines and investigation workflows are documented.','https://www.exabeam.com/platform/new-scale-siem/'),
('exabeam-new-scale-siem','siem-soar','supported',0.98,'Automation Management and playbooks are documented for response workflows.','https://docs.exabeam.com/new-scale-security-operations-platform/'),
('exabeam-new-scale-siem','siem-behavior-risk','supported',0.99,'Behavioral analytics and context-aware risk scoring are documented.','https://www.exabeam.com/platform/new-scale-siem/'),

-- SailPoint Identity Security Cloud
('sailpoint-identity-security-cloud','iam-lifecycle-provisioning','supported',0.99,'Lifecycle states automate provisioning, access changes and deprovisioning.','https://www.sailpoint.com/products/identity-security-cloud/atlas/capabilities/lifecycle-management'),
('sailpoint-identity-security-cloud','iam-directory','supported',0.95,'Identity Security Cloud centralizes identities, accounts, roles, access profiles and entitlements from connected sources.','https://documentation.sailpoint.com/saas/help/access/index.html'),

-- WALLIX Bastion
('wallix-bastion','pam-vault','supported',0.99,'Password Manager secures privileged credentials and password policies.','https://www.wallix.com/products/privileged-access-management/'),
('wallix-bastion','pam-discovery','supported',0.95,'WALLIX documents discovery and management of privileged credential activity.','https://www.wallix.com/products/privileged-access-management/'),
('wallix-bastion','pam-rotation','supported',0.99,'Password complexity, security and rotation are explicitly documented.','https://www.wallix.com/products/privileged-access-management/'),
('wallix-bastion','pam-session-monitoring','supported',0.99,'Session Manager provides monitored sessions, video, transcript and metadata audit trails.','https://www.wallix.com/products/privileged-access-management/'),

-- Körber Warehouse Management
('koerber-warehouse-management','wms-inventory-visibility','supported',0.99,'Körber documents differentiated inventory management and full warehouse visibility.','https://koerber-supplychain.com/supply-chain-solutions/supply-chain-software/warehouse-management/'),
('koerber-warehouse-management','wms-inbound','supported',0.99,'Receiving and put-away are explicit WMS capabilities.','https://koerber-supplychain.com/supply-chain-solutions/supply-chain-software/warehouse-management/'),
('koerber-warehouse-management','wms-outbound','supported',0.99,'Picking, packing, shipping and staging are explicitly documented.','https://koerber-supplychain.com/supply-chain-solutions/supply-chain-software/warehouse-management/'),
('koerber-warehouse-management','wms-automation','supported',0.99,'Integration with material-handling automation from multiple vendors is documented.','https://koerber-supplychain.com/supply-chain-solutions/supply-chain-software/warehouse-management/'),
('koerber-warehouse-management','wms-optimization-orchestration','supported',0.98,'Slotting, labor/resource management and process optimization are documented.','https://koerber-supplychain.com/supply-chain-solutions/supply-chain-software/warehouse-management/'),

-- Pega Platform
('pega-platform','lowcode-visual-development','supported',0.99,'Pega documents visual, model-driven low-code application development.','https://www.pega.com/low-code/application-development'),
('pega-platform','lowcode-web-mobile','supported',0.98,'Pega documents app delivery across web and mobile channels.','https://www.pega.com/low-code/application-development'),
('pega-platform','lowcode-workflow-automation','supported',0.99,'Pega documents customizable workflows and enterprise-grade process automation.','https://www.pega.com/products/platform/ai-app-development');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat80_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat80_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,f.limitations
FROM cat80_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Conservative deployment facts from explicit vendor material.
INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.98 FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug IN('exabeam-new-scale-siem','sailpoint-identity-security-cloud')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.95 FROM products p JOIN deployment_models d ON d.slug IN('public-saas','on-premise')
WHERE p.slug IN('wallix-bastion','koerber-warehouse-management')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

-- Integrations were not systematically reviewed in this batch.
INSERT INTO product_integrations(product_id,integration_id,support_status,confidence_score)
SELECT p.id,i.id,'not_yet_verified',0 FROM products p JOIN integrations i
WHERE p.slug IN('exabeam-new-scale-siem','sailpoint-identity-security-cloud','wallix-bastion','koerber-warehouse-management','pega-platform')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

DROP TEMPORARY TABLE IF EXISTS cat80_facts;
DROP TEMPORARY TABLE IF EXISTS cat80_products;
COMMIT;
