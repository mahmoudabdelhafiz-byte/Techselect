-- TechSelectAI catalog expansion: BMC Helix ITSM completion for cross-category batch 2
-- Adds BMC Helix ITSM to the existing ITSM taxonomy with official BMC evidence.
SET NAMES utf8mb4;
START TRANSACTION;

SET @cat_id=(SELECT id FROM categories WHERE slug='itsm' LIMIT 1);

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('BMC','bmc','https://www.bmc.com/','Enterprise IT service management, operations and automation software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,@cat_id,'BMC Helix ITSM','bmc-helix-itsm','Enterprise IT service management suite covering incident, problem, change, knowledge, service request, asset, configuration and service-level management.','https://www.bmc.com/it-solutions/bmc-helix-itsm.html','active',NOW()
FROM vendors v WHERE v.slug='bmc' AND @cat_id IS NOT NULL
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',x.url,x.title,'BMC',1,'verified','high',NOW()
FROM products p JOIN (
 SELECT 'bmc-helix-itsm' product_slug,'https://webapps.bmc.com/support/faces/az/prodallversions.xhtml?seqid=340560' url,'BMC Helix ITSM supported versions and OnDemand products' title UNION ALL
 SELECT 'bmc-helix-itsm','https://webapps.bmc.com/support/faces/az/prodversion.xhtml?prodverseqid=542818','BMC Helix ITSM OnPrem 25.2.01' UNION ALL
 SELECT 'bmc-helix-itsm','https://www.bmc.com/content/dam/bmc/education/Abstract_SPPT-ENT-SUBS-ITSM.pdf','BMC IT Service Management curriculum and modules' UNION ALL
 SELECT 'bmc-helix-itsm','https://www.bmc.com/content/dam/bmc/education/Abstract_SPPT-ITAA-2210-ASP.pdf','BMC Helix ITSM 22.x Fundamentals Administering Applications'
) x ON x.product_slug=p.slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=x.url);

DROP TEMPORARY TABLE IF EXISTS cat75_facts;
CREATE TEMPORARY TABLE cat75_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat75_facts VALUES
('bmc-helix-itsm','itsm-incident-management','supported',0.99,NULL,'https://www.bmc.com/content/dam/bmc/education/Abstract_SPPT-ITAA-2210-ASP.pdf'),
('bmc-helix-itsm','itsm-request-service-catalog','supported',0.95,'BMC documents Service Request Management as part of the ITSM suite; implementation scope varies by licensed service-management package.','https://www.bmc.com/content/dam/bmc/education/Abstract_SPPT-ENT-SUBS-ITSM.pdf'),
('bmc-helix-itsm','itsm-sla-management','supported',0.95,'BMC Service Level Management is documented within the ITSM suite curriculum.','https://www.bmc.com/content/dam/bmc/education/Abstract_SPPT-ENT-SUBS-ITSM.pdf'),
('bmc-helix-itsm','itsm-problem-management','supported',0.99,NULL,'https://www.bmc.com/content/dam/bmc/education/Abstract_SPPT-ITAA-2210-ASP.pdf'),
('bmc-helix-itsm','itsm-change-management','supported',0.99,NULL,'https://www.bmc.com/content/dam/bmc/education/Abstract_SPPT-ITAA-2210-ASP.pdf'),
('bmc-helix-itsm','itsm-knowledge-management','supported',0.99,'Knowledge Management is a documented BMC Helix ITSM component.','https://www.bmc.com/content/dam/bmc/education/Abstract_SPPT-ENT-SUBS-ITSM.pdf'),
('bmc-helix-itsm','itsm-asset-management','supported',0.99,'Asset Management is a documented BMC Helix ITSM component.','https://www.bmc.com/content/dam/bmc/education/Abstract_SPPT-ENT-SUBS-ITSM.pdf'),
('bmc-helix-itsm','itsm-cmdb','supported',0.99,'Current BMC Helix ITSM supported-version documentation links the corresponding BMC Helix CMDB release.','https://webapps.bmc.com/support/faces/az/prodversion.xhtml?prodverseqid=542818');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat75_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,c.id,NULL,'not_yet_verified',0
FROM products p CROSS JOIN capabilities c JOIN modules m ON m.id=c.module_id
WHERE p.slug='bmc-helix-itsm' AND m.category_id=@cat_id
AND NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,f.limitations
FROM cat75_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.99 FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug='bmc-helix-itsm'
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.99 FROM products p JOIN deployment_models d ON d.slug='on-premise'
WHERE p.slug='bmc-helix-itsm'
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

INSERT INTO product_integrations(product_id,integration_id,support_status,confidence_score)
SELECT p.id,i.id,'not_yet_verified',0 FROM products p JOIN integrations i WHERE p.slug='bmc-helix-itsm'
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

DROP TEMPORARY TABLE IF EXISTS cat75_facts;
COMMIT;
