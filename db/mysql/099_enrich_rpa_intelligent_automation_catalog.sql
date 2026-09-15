-- TechSelectAI RPA & Intelligent Automation depth pass.
-- Adds SS&C Blue Prism Enterprise as an additional peer to the existing strategic category.
-- Uses first-party evidence only. Unknown != Unsupported. No Fit Score or recommendation changes.
SET NAMES utf8mb4;
START TRANSACTION;

SET @rpa_cat=(SELECT id FROM categories WHERE slug='rpa-intelligent-automation' LIMIT 1);

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('SS&C Blue Prism','ssc-blue-prism','https://www.blueprism.com/','Enterprise robotic process automation and intelligent automation software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,@rpa_cat,'SS&C Blue Prism Enterprise','blue-prism-enterprise',
'Enterprise intelligent automation and RPA platform for building, running, orchestrating and governing digital workers across business applications and workflows.',
'https://www.blueprism.com/products/enterprise/','active',NOW()
FROM vendors v WHERE v.slug='ssc-blue-prism'
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS cat99_sources;
CREATE TEMPORARY TABLE cat99_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat99_sources VALUES
('blue-prism-enterprise','https://www.blueprism.com/products/enterprise/','SS&C Blue Prism Enterprise Automation','SS&C Blue Prism'),
('blue-prism-enterprise','https://documentation.blueprism.com/bp-7-1/en-us/home.htm','Blue Prism Enterprise Documentation','SS&C Blue Prism'),
('blue-prism-enterprise','https://www.blueprism.com/automation-journey/rpa-governance/','RPA Governance Best Practices','SS&C Blue Prism');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM cat99_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS cat99_facts;
CREATE TEMPORARY TABLE cat99_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat99_facts VALUES
('blue-prism-enterprise','rpa-desktop-web-automation','supported',0.960,'Blue Prism Enterprise documents software robots that mimic human actions and work across legacy and modern applications; product-specific browser/desktop breadth is not separately quantified here.','https://www.blueprism.com/products/enterprise/'),
('blue-prism-enterprise','rpa-unattended','supported',0.970,'Blue Prism Enterprise documents an autonomous digital workforce operating in real time around the clock.','https://www.blueprism.com/products/enterprise/'),
('blue-prism-enterprise','rpa-orchestration-scheduling','supported',0.990,'Control Room provides centralized assignment, monitoring and SLA-based orchestration for digital workers.','https://www.blueprism.com/products/enterprise/'),
('blue-prism-enterprise','rpa-process-workflow','supported',0.960,'Blue Prism Enterprise is positioned for business-process automation with orchestration across work, people and systems.','https://www.blueprism.com/products/enterprise/'),
('blue-prism-enterprise','rpa-governance-audit','supported',0.990,'The product documents strict access controls, multilevel change approvals, monitoring, governance and detailed audit trails.','https://www.blueprism.com/products/enterprise/'),
('blue-prism-enterprise','rpa-ai-document','partially_supported',0.840,'Blue Prism Enterprise documents AI-powered intelligent digital workers, but dedicated document automation is a separate Blue Prism product and is therefore not claimed as fully supported here.','https://www.blueprism.com/products/enterprise/');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score,limitations,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.confidence,f.limitations,NOW()
FROM cat99_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score),limitations=VALUES(limitations),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM products p JOIN modules m ON m.category_id=@rpa_cat JOIN capabilities cap ON cap.module_id=m.id
WHERE p.slug='blue-prism-enterprise'
AND NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party source supporting this capability.'
FROM cat99_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

INSERT INTO product_mobile_access(product_id,platform,support_status,scope,evidence_url,last_verified_at)
SELECT p.id,plat.platform,'not_yet_verified','Mobile access has not yet been verified from product-specific first-party evidence.',NULL,NULL
FROM products p JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') plat
WHERE p.slug='blue-prism-enterprise'
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope=VALUES(scope);

COMMIT;
