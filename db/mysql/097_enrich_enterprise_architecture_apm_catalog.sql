-- TechSelectAI Enterprise Architecture & APM depth pass.
-- Adds ServiceNow Application Portfolio Management as a fifth peer to the existing strategic category.
-- Uses first-party evidence only. Unknown != Unsupported. No Fit Score or recommendation changes.
SET NAMES utf8mb4;
START TRANSACTION;

SET @ea_cat=(SELECT id FROM categories WHERE slug='enterprise-architecture-apm' LIMIT 1);

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('ServiceNow','servicenow','https://www.servicenow.com/','Enterprise workflow, IT management and portfolio management software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,@ea_cat,'ServiceNow Application Portfolio Management','servicenow-application-portfolio-management',
'Application portfolio management for centralized application inventory, capability mapping, rationalization, lifecycle and technology-risk informed portfolio decisions.',
'https://www.servicenow.com/products/application-portfolio-management.html','active',NOW()
FROM vendors v WHERE v.slug='servicenow'
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS cat97_sources;
CREATE TEMPORARY TABLE cat97_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat97_sources VALUES
('servicenow-application-portfolio-management','https://www.servicenow.com/products/application-portfolio-management.html','ServiceNow Application Portfolio Management','ServiceNow'),
('servicenow-application-portfolio-management','https://www.servicenow.com/products/strategic-portfolio-management/what-is-application-portfolio-management.html','ServiceNow APM overview','ServiceNow');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM cat97_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS cat97_facts;
CREATE TEMPORARY TABLE cat97_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat97_facts VALUES
('servicenow-application-portfolio-management','ea-application-inventory','supported',0.990,'ServiceNow documents a centralized inventory of business applications.','https://www.servicenow.com/products/application-portfolio-management.html'),
('servicenow-application-portfolio-management','ea-business-capability-mapping','supported',0.990,'ServiceNow explicitly documents capability mapping and capability-based planning.','https://www.servicenow.com/products/application-portfolio-management.html'),
('servicenow-application-portfolio-management','ea-dependency-modeling','supported',0.930,'ServiceNow documents digital integration visibility and relationships across application/service landscapes.','https://www.servicenow.com/products/application-portfolio-management.html'),
('servicenow-application-portfolio-management','ea-roadmaps-target-state','supported',0.900,'ServiceNow documents planning for future business strategies and modernization roadmaps.','https://www.servicenow.com/products/application-portfolio-management.html'),
('servicenow-application-portfolio-management','ea-application-lifecycle','supported',0.970,'ServiceNow documents end-of-life application planning and application lifecycle decisions.','https://www.servicenow.com/products/application-portfolio-management.html'),
('servicenow-application-portfolio-management','ea-portfolio-rationalization','supported',0.990,'Application Rationalization is an explicit ServiceNow APM feature.','https://www.servicenow.com/products/application-portfolio-management.html'),
('servicenow-application-portfolio-management','ea-risk-cost-assessment','supported',0.970,'ServiceNow documents lower-cost, risk reduction and technology-risk informed portfolio decisions.','https://www.servicenow.com/products/strategic-portfolio-management/what-is-application-portfolio-management.html');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score,limitations,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.confidence,f.limitations,NOW()
FROM cat97_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score),limitations=VALUES(limitations),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM products p JOIN modules m ON m.category_id=@ea_cat JOIN capabilities cap ON cap.module_id=m.id
WHERE p.slug='servicenow-application-portfolio-management'
AND NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party source supporting this capability.'
FROM cat97_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,plat.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000
FROM products p JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') plat
WHERE p.slug='servicenow-application-portfolio-management'
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

COMMIT;