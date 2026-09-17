-- TechSelectAI Data Catalog & Governance catalog expansion.
-- Adds one canonical data-catalog/governance category and five evidence-backed enterprise products.
-- Official first-party evidence reviewed Sep 2026. Presence is not an endorsement.
-- Unknown != Unsupported. No Fit Score, recommendation ranking, review score, follower/community popularity or commercial placement logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('Data Catalog & Governance','data-catalog-governance','Platforms for discovering, cataloging, contextualizing, governing and tracing enterprise data and AI assets across distributed data estates.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @dcg_cat=(SELECT id FROM categories WHERE slug='data-catalog-governance' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@dcg_cat,'Catalog & Context','dcg-catalog-context','Metadata inventory, search, discovery, business context and glossary capabilities for enterprise data assets.',1),
(@dcg_cat,'Governance, Lineage & Trust','dcg-governance-lineage','Lineage, governance workflows, policies, quality/trust signals and governed data-product capabilities.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.sec,1
FROM modules m JOIN (
 SELECT 'dcg-catalog-context' module_slug,'Metadata harvesting & asset inventory' name,'dcg-metadata-inventory' slug,'Automatically collect, organize and maintain metadata and inventory for enterprise data and AI assets.',0 sec UNION ALL
 SELECT 'dcg-catalog-context','Search & data discovery','dcg-search-discovery','Help users find and understand relevant data assets through search, discovery, context and trust signals.',0 UNION ALL
 SELECT 'dcg-catalog-context','Business glossary / semantic context','dcg-business-glossary','Manage business terms, definitions, ownership or semantic context that connects technical data to business meaning.',0 UNION ALL
 SELECT 'dcg-governance-lineage','Data lineage & impact analysis','dcg-lineage-impact','Trace data origins, movement, transformations, dependencies and downstream impact.',0 UNION ALL
 SELECT 'dcg-governance-lineage','Governance policies & stewardship workflows','dcg-governance-workflows','Manage policies, stewardship roles, governance tasks, approvals or workflow automation for governed data.',1 UNION ALL
 SELECT 'dcg-governance-lineage','Data quality / trust signals','dcg-quality-trust','Surface or manage data quality, trust, certification or observability signals that help users assess data fitness.',0 UNION ALL
 SELECT 'dcg-governance-lineage','Governed data products / marketplace','dcg-data-products-marketplace','Package, publish, discover or govern reusable data products or marketplace-style governed data assets.',0
) x ON x.module_slug=m.slug
WHERE m.category_id=@dcg_cat
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Collibra','collibra','https://www.collibra.com/','Data intelligence, data catalog, governance, lineage and data quality software vendor.','active'),
('Alation','alation','https://www.alation.com/','Data intelligence, catalog, governance, lineage and data quality software vendor.','active'),
('Microsoft','microsoft','https://www.microsoft.com/','Enterprise software, cloud, security, data and governance platform vendor.','active'),
('Atlan','atlan','https://atlan.com/','Metadata, data catalog, lineage, governance and data-product platform vendor.','active'),
('Informatica','informatica','https://www.informatica.com/','Enterprise data management, catalog, governance, lineage, quality and integration software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat108_products;
CREATE TEMPORARY TABLE cat108_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO cat108_products VALUES
('collibra','data-catalog-governance','Collibra Platform','collibra-platform','Unified data and AI governance platform spanning catalog, lineage, governance, quality, privacy and trusted-data workflows across enterprise data estates.','https://www.collibra.com/platform'),
('alation','data-catalog-governance','Alation Data Intelligence Platform','alation-data-intelligence-platform','Enterprise data intelligence platform combining catalog, governance, lineage, data quality, search, glossary and AI-assisted data-management capabilities.','https://www.alation.com/product/agentic-data-intelligence-platform/'),
('microsoft','data-catalog-governance','Microsoft Purview Unified Catalog','microsoft-purview-unified-catalog','Business-friendly data governance and catalog experience built on Microsoft Purview Data Map for discovering, understanding, governing and consuming enterprise data assets and data products.','https://learn.microsoft.com/en-us/purview/unified-catalog'),
('atlan','data-catalog-governance','Atlan','atlan-data-catalog-governance','Metadata and governance platform that combines automated metadata collection, enterprise discovery, lineage, business context, data products and governance workflows for people and AI agents.','https://docs.atlan.com/get-started/what-is-atlan'),
('informatica','data-catalog-governance','Informatica Cloud Data Governance & Catalog','informatica-cloud-data-governance-catalog','Cloud data governance and catalog service for metadata discovery, classification, lineage, governance, quality context and trusted data/AI asset management.','https://www.informatica.com/products/data-governance/cloud-data-governance-and-catalog.html.html.html');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat108_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS cat108_sources;
CREATE TEMPORARY TABLE cat108_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat108_sources VALUES
('collibra-platform','https://www.collibra.com/platform','Collibra Platform','Collibra'),
('collibra-platform','https://www.collibra.com/products/data-catalog','Collibra Data Catalog','Collibra'),
('collibra-platform','https://productresources.collibra.com/docs/collibra/latest/Content/Catalog/to_catalog.htm','About Collibra Data Catalog','Collibra'),
('alation-data-intelligence-platform','https://www.alation.com/product/agentic-data-intelligence-platform/','Alation Data Intelligence Platform','Alation'),
('alation-data-intelligence-platform','https://www.alation.com/product/data-governance/','Alation Data Governance','Alation'),
('alation-data-intelligence-platform','https://www.alation.com/product/data-catalog/','Alation Data Catalog','Alation'),
('microsoft-purview-unified-catalog','https://learn.microsoft.com/en-us/purview/unified-catalog','Microsoft Purview Unified Catalog','Microsoft'),
('microsoft-purview-unified-catalog','https://learn.microsoft.com/en-us/purview/data-governance-plan','Plan for data governance with Microsoft Purview','Microsoft'),
('microsoft-purview-unified-catalog','https://learn.microsoft.com/en-us/purview/unified-catalog-data-products','Data products in Microsoft Purview Unified Catalog','Microsoft'),
('microsoft-purview-unified-catalog','https://learn.microsoft.com/en-us/purview/data-gov-classic-lineage','Microsoft Purview data lineage','Microsoft'),
('atlan-data-catalog-governance','https://docs.atlan.com/get-started/what-is-atlan','What is Atlan?','Atlan'),
('atlan-data-catalog-governance','https://docs.atlan.com/product/capabilities/lineage','Atlan Lineage','Atlan'),
('atlan-data-catalog-governance','https://docs.atlan.com/product/capabilities/data-products','Atlan Data Products','Atlan'),
('atlan-data-catalog-governance','https://atlan.com/active-data-governance/','Atlan Active Data Governance','Atlan'),
('informatica-cloud-data-governance-catalog','https://www.informatica.com/products/data-governance/cloud-data-governance-and-catalog.html.html.html','Informatica Cloud Data Governance & Catalog','Informatica'),
('informatica-cloud-data-governance-catalog','https://www.informatica.com/products/data-catalog.html/','Informatica Data Catalog','Informatica'),
('informatica-cloud-data-governance-catalog','https://www.informatica.com/products/data-catalog/data-lineage.html','Informatica Data Lineage','Informatica');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM cat108_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS cat108_facts;
CREATE TEMPORARY TABLE cat108_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat108_facts VALUES
-- Collibra
('collibra-platform','dcg-metadata-inventory','supported',0.990,'Collibra Data Catalog documents enterprise metadata integration and inventory across databases, lakes, warehouses, applications, ETL and BI systems.','https://productresources.collibra.com/docs/collibra/latest/Content/Catalog/to_catalog.htm'),
('collibra-platform','dcg-search-discovery','supported',0.990,'Collibra documents a searchable enterprise catalog that centralizes metadata, ownership, definitions, classifications, lineage and policies.','https://www.collibra.com/products/data-catalog'),
('collibra-platform','dcg-business-glossary','supported',0.970,'Collibra platform material documents business context and governance capabilities; exact glossary configuration depends on the deployed governance model.','https://www.collibra.com/platform'),
('collibra-platform','dcg-lineage-impact','supported',0.990,'Collibra documents data lineage as a core platform capability for understanding data origins, movement and downstream impact.','https://www.collibra.com/platform'),
('collibra-platform','dcg-governance-workflows','supported',0.990,'Collibra documents unified data and AI governance, policies and workflows across governed assets.','https://www.collibra.com/platform'),
('collibra-platform','dcg-quality-trust','supported',0.950,'Collibra Platform includes Data Quality & Observability; exact quality functionality can depend on licensed product modules.','https://www.collibra.com/platform'),

-- Alation
('alation-data-intelligence-platform','dcg-metadata-inventory','supported',0.990,'Alation documents cataloging and centralization of metadata, definitions, policies and relationships across the enterprise data estate.','https://www.alation.com/product/agentic-data-intelligence-platform/'),
('alation-data-intelligence-platform','dcg-search-discovery','supported',0.990,'Alation Data Catalog documents enterprise search and discovery for trusted data assets and business context.','https://www.alation.com/product/data-catalog/'),
('alation-data-intelligence-platform','dcg-business-glossary','supported',0.990,'Alation documents business context, definitions and governance policy management as integrated platform capabilities.','https://www.alation.com/product/agentic-data-intelligence-platform/'),
('alation-data-intelligence-platform','dcg-lineage-impact','supported',0.990,'Alation documents automated column-level lineage and end-to-end data relationship visualization.','https://www.alation.com/product/agentic-data-intelligence-platform/'),
('alation-data-intelligence-platform','dcg-governance-workflows','supported',0.990,'Alation documents Policy Center, workflow automation, policy updates, renewal tasks and governed classification.','https://www.alation.com/product/data-governance/'),
('alation-data-intelligence-platform','dcg-quality-trust','supported',0.990,'Alation documents AI-powered data quality prioritization, monitoring, trust indicators and quality controls.','https://www.alation.com/product/agentic-data-intelligence-platform/'),
('alation-data-intelligence-platform','dcg-data-products-marketplace','supported',0.980,'Alation documents a Data Products Marketplace for reusable governed data products; availability can depend on the subscribed platform capabilities.','https://www.alation.com/product/agentic-data-intelligence-platform/'),

-- Microsoft Purview Unified Catalog
('microsoft-purview-unified-catalog','dcg-metadata-inventory','supported',0.990,'Microsoft documents Purview Data Map inventory of enterprise data assets and metadata that powers Unified Catalog.','https://learn.microsoft.com/en-us/purview/data-governance-plan'),
('microsoft-purview-unified-catalog','dcg-search-discovery','supported',0.990,'Microsoft documents business-friendly search and discovery of governed data through Unified Catalog.','https://learn.microsoft.com/en-us/purview/unified-catalog'),
('microsoft-purview-unified-catalog','dcg-business-glossary','supported',0.970,'Unified Catalog supports governance domains, glossary/business context and curated data products; exact semantic governance depends on configured domains and glossary content.','https://learn.microsoft.com/en-us/purview/unified-catalog'),
('microsoft-purview-unified-catalog','dcg-lineage-impact','supported',0.990,'Microsoft Purview documents lineage across data assets, processes and transformations; Unified Catalog exposes lineage through governed asset views.','https://learn.microsoft.com/en-us/purview/data-gov-classic-lineage'),
('microsoft-purview-unified-catalog','dcg-governance-workflows','supported',0.990,'Microsoft documents governance domains, roles, access policies, stewardship and governance workflows in Unified Catalog.','https://learn.microsoft.com/en-us/purview/data-governance-plan'),
('microsoft-purview-unified-catalog','dcg-data-products-marketplace','supported',0.990,'Microsoft documents governed data products that group assets for defined use cases and consumer discovery.','https://learn.microsoft.com/en-us/purview/unified-catalog-data-products'),

-- Atlan
('atlan-data-catalog-governance','dcg-metadata-inventory','supported',0.990,'Atlan documents automatic metadata crawling from warehouses, BI, transformation, observability and other tools into an Enterprise Data Graph.','https://docs.atlan.com/get-started/what-is-atlan'),
('atlan-data-catalog-governance','dcg-search-discovery','supported',0.990,'Atlan documents a single context layer where data teams and AI agents find, understand and act on enterprise data.','https://docs.atlan.com/get-started/what-is-atlan'),
('atlan-data-catalog-governance','dcg-business-glossary','supported',0.990,'Atlan documents business glossary and semantic context that propagates definitions along lineage.','https://atlan.com/data-glossary/'),
('atlan-data-catalog-governance','dcg-lineage-impact','supported',0.990,'Atlan documents automated lineage for root-cause analysis, impact analysis and metadata propagation.','https://docs.atlan.com/product/capabilities/lineage'),
('atlan-data-catalog-governance','dcg-governance-workflows','supported',0.990,'Atlan documents governance policy enforcement, classifications, access controls and governed workflows.','https://atlan.com/active-data-governance/'),
('atlan-data-catalog-governance','dcg-data-products-marketplace','supported',0.990,'Atlan documents governed data products organized by domain for discovery, understanding and collaboration.','https://docs.atlan.com/product/capabilities/data-products'),

-- Informatica
('informatica-cloud-data-governance-catalog','dcg-metadata-inventory','supported',0.990,'Informatica documents automated discovery, classification and inventory of structured, semi-structured and unstructured data and AI assets.','https://www.informatica.com/products/data-catalog.html/'),
('informatica-cloud-data-governance-catalog','dcg-search-discovery','supported',0.990,'Informatica documents enterprise search and discovery across cataloged assets with business and technical context.','https://www.informatica.com/products/data-catalog.html/'),
('informatica-cloud-data-governance-catalog','dcg-business-glossary','supported',0.970,'Cloud Data Governance & Catalog documents shared business context and AI-powered governance; exact glossary administration depends on deployed governance configuration.','https://www.informatica.com/products/data-governance/cloud-data-governance-and-catalog.html.html.html'),
('informatica-cloud-data-governance-catalog','dcg-lineage-impact','supported',0.990,'Informatica documents automated end-to-end lineage, dependency analysis and impact visibility.','https://www.informatica.com/products/data-catalog/data-lineage.html'),
('informatica-cloud-data-governance-catalog','dcg-governance-workflows','supported',0.990,'Informatica documents AI-powered governance, policy automation, curation and stewardship across data and AI assets.','https://www.informatica.com/products/data-governance/cloud-data-governance-and-catalog.html.html.html'),
('informatica-cloud-data-governance-catalog','dcg-quality-trust','supported',0.950,'Informatica Data Catalog integrates profiling, rules, quality metrics and scorecards; deeper quality functions may use companion Data Quality & Observability services.','https://www.informatica.com/products/data-catalog.html/');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat108_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat108_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party vendor documentation supporting this capability.'
FROM cat108_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Deployment is not promoted here unless product-specific deployment evidence is explicit enough for the selected SKU.
-- Mobile administrative scope is not inferred from general mobile/browser access.
INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000
FROM products p CROSS JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') x
WHERE p.slug IN('collibra-platform','alation-data-intelligence-platform','microsoft-purview-unified-catalog','atlan-data-catalog-governance','informatica-cloud-data-governance-catalog')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

COMMIT;
