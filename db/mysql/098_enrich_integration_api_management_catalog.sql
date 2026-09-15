-- TechSelectAI Integration & API Management depth pass.
-- Adds Informatica Cloud Integration as a fifth peer to the existing strategic category.
-- Uses first-party evidence only. Unknown != Unsupported. No Fit Score or recommendation changes.
SET NAMES utf8mb4;
START TRANSACTION;

SET @integration_cat=(SELECT id FROM categories WHERE slug='integration-api-management' LIMIT 1);

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Informatica','informatica','https://www.informatica.com/','Enterprise cloud data management, integration and API management software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,@integration_cat,'Informatica Cloud Integration','informatica-cloud-integration',
'Enterprise iPaaS for application and data integration, workflow orchestration, hybrid connectivity, and API lifecycle management within Informatica IDMC.',
'https://www.informatica.com/products/cloud-integration.html','active',NOW()
FROM vendors v WHERE v.slug='informatica'
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS cat98_sources;
CREATE TEMPORARY TABLE cat98_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat98_sources VALUES
('informatica-cloud-integration','https://www.informatica.com/products/cloud-integration.html','Informatica Cloud Integration','Informatica'),
('informatica-cloud-integration','https://www.informatica.com/products/cloud-integration/integration-cloud/api-management.html','Informatica API Lifecycle Management','Informatica'),
('informatica-cloud-integration','https://success.informatica.com/success-accelerators/overview-of-cloud-application-integration-in-idmc.html','Overview of Cloud Application Integration in IDMC','Informatica'),
('informatica-cloud-integration','https://www.informatica.com/content/dam/informatica-com/en/collateral/data-sheet/informatica-cloud-application-integration_data-sheet_3464en.pdf','Informatica Cloud Application Integration data sheet','Informatica'),
('informatica-cloud-integration','https://docs.informatica.com/content/dam/source/GUID-C/GUID-C0A474A2-771F-4C7F-99B8-4C4090197055/18/en/APIC_May2025_Manage%28API%29S_en.pdf','Informatica API Center managed APIs','Informatica');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM cat98_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS cat98_facts;
CREATE TEMPORARY TABLE cat98_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat98_facts VALUES
('informatica-cloud-integration','integration-connectors','supported',0.970,'Informatica documents broad multi-cloud and application integration across enterprise applications and platforms.','https://www.informatica.com/products/cloud-integration.html'),
('informatica-cloud-integration','integration-workflow-orchestration','supported',0.990,'Cloud Application Integration documents service orchestration and business process management across cloud and on-premises applications.','https://success.informatica.com/success-accelerators/overview-of-cloud-application-integration-in-idmc.html'),
('informatica-cloud-integration','integration-hybrid-runtime','supported',0.990,'Informatica documents cloud and on-premises interaction for application integration in hybrid and multi-cloud environments.','https://www.informatica.com/content/dam/informatica-com/en/collateral/data-sheet/informatica-cloud-application-integration_data-sheet_3464en.pdf'),
('informatica-cloud-integration','api-design-publish','supported',0.990,'Informatica API management documents designing, testing, deploying and publishing APIs.','https://www.informatica.com/products/cloud-integration/integration-cloud/api-management.html'),
('informatica-cloud-integration','api-gateway-security','supported',0.990,'Informatica documents enterprise API security, access controls and policy-managed APIs.','https://docs.informatica.com/content/dam/source/GUID-C/GUID-C0A474A2-771F-4C7F-99B8-4C4090197055/18/en/APIC_May2025_Manage%28API%29S_en.pdf'),
('informatica-cloud-integration','api-lifecycle-governance','supported',0.990,'API Center documents complete managed API lifecycle management including activation, revision, deprecation and retirement.','https://docs.informatica.com/content/dam/source/GUID-C/GUID-C0A474A2-771F-4C7F-99B8-4C4090197055/18/en/APIC_May2025_Manage%28API%29S_en.pdf'),
('informatica-cloud-integration','api-monitoring-analytics','supported',0.990,'Informatica documents real-time API monitoring, performance/error visibility and API activity logs.','https://www.informatica.com/products/cloud-integration/integration-cloud/api-management.html');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score,limitations,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.confidence,f.limitations,NOW()
FROM cat98_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score),limitations=VALUES(limitations),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM products p JOIN modules m ON m.category_id=@integration_cat JOIN capabilities cap ON cap.module_id=m.id
WHERE p.slug='informatica-cloud-integration'
AND NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party source supporting this capability.'
FROM cat98_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,plat.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000
FROM products p JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') plat
WHERE p.slug='informatica-cloud-integration'
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

COMMIT;
