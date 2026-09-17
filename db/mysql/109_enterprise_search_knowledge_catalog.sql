-- TechSelectAI Enterprise Search & Knowledge Discovery catalog expansion.
-- Adds one canonical enterprise-search category and five evidence-backed current products.
-- Official first-party evidence reviewed Sep 2026. Presence is not an endorsement.
-- Elastic Workplace Search is intentionally excluded because Elastic documents the standalone product as maintenance mode / not recommended for new search experiences.
-- Unknown != Unsupported. No Fit Score, recommendation ranking, review score, follower/community popularity or commercial placement logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('Enterprise Search & Knowledge Discovery','enterprise-search-knowledge-discovery','Platforms that connect and index enterprise information so employees, support teams and AI systems can securely search, retrieve and generate answers from distributed organizational knowledge.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @es_cat=(SELECT id FROM categories WHERE slug='enterprise-search-knowledge-discovery' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@es_cat,'Search, Retrieval & Connectivity','es-search-connectivity','Connectors, indexing, hybrid or semantic retrieval, relevance and permissions-aware enterprise search.',1),
(@es_cat,'AI Answers & Knowledge Operations','es-ai-knowledge','Grounded AI answers, knowledge curation, analytics, administration and governance for enterprise knowledge discovery.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.sec,1
FROM modules m JOIN (
 SELECT 'es-search-connectivity' module_slug,'Enterprise connectors & unified indexing' name,'es-connectors-indexing' slug,'Connect and index content from multiple enterprise applications, repositories and data sources into a searchable knowledge layer.',0 sec UNION ALL
 SELECT 'es-search-connectivity','Semantic / hybrid relevance & search' name,'es-relevance-search','Search enterprise knowledge using keyword, semantic, neural, hybrid or other relevance-ranking methods.',0 UNION ALL
 SELECT 'es-search-connectivity','Permissions-aware retrieval' name,'es-permissions-aware','Honor source-system permissions or equivalent access controls when returning search results or AI-grounding content.',1 UNION ALL
 SELECT 'es-ai-knowledge','Grounded AI answers / assistants' name,'es-ai-answers','Generate conversational or direct answers grounded in indexed enterprise content with source-aware retrieval.',0 UNION ALL
 SELECT 'es-ai-knowledge','Knowledge curation & verification' name,'es-knowledge-curation','Create, curate, verify, reconcile or maintain trusted enterprise knowledge beyond passive indexing.',0 UNION ALL
 SELECT 'es-ai-knowledge','Search analytics & administration' name,'es-analytics-admin','Provide analytics, tuning, administration, auditing or management controls for enterprise search and knowledge experiences.',0
) x ON x.module_slug=m.slug
WHERE m.category_id=@es_cat
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Glean','glean','https://www.glean.com/','Enterprise AI, workplace search and knowledge discovery software vendor.','active'),
('Coveo','coveo','https://www.coveo.com/','AI search, relevance, recommendations and generative-answering platform vendor.','active'),
('Sinequa','sinequa','https://www.sinequa.com/','Enterprise AI search, knowledge discovery and agentic AI platform vendor.','active'),
('Guru','guru','https://www.getguru.com/','Enterprise AI search and knowledge management software vendor.','active'),
('Lucidworks','lucidworks','https://lucidworks.com/','Enterprise AI-powered search, discovery and relevance platform vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat109_products;
CREATE TEMPORARY TABLE cat109_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO cat109_products VALUES
('glean','enterprise-search-knowledge-discovery','Glean Search','glean-search','AI-powered workplace search that connects enterprise applications and content sources to deliver personalized, permissions-aware search and grounded answers across company knowledge.','https://www.glean.com/enterprise-search'),
('coveo','enterprise-search-knowledge-discovery','Coveo Platform','coveo-platform','Cloud AI search and relevance platform that unifies enterprise content into a searchable index and supports secure retrieval, personalized relevance and grounded generative answering.','https://docs.coveo.com/en/3361/'),
('sinequa','enterprise-search-knowledge-discovery','Sinequa Enterprise AI Search','sinequa-enterprise-ai-search','Enterprise AI search platform for securely connecting, indexing and retrieving knowledge across enterprise systems with hybrid retrieval, permissions enforcement and grounded AI assistants.','https://www.sinequa.com/product/workplace-search/'),
('guru','enterprise-search-knowledge-discovery','Guru Enterprise AI Search','guru-enterprise-ai-search','Enterprise search and knowledge platform that connects company applications, produces cited permission-aware answers and adds verification, curation and knowledge-maintenance workflows.','https://www.getguru.com/solutions/ai-enterprise-search'),
('lucidworks','enterprise-search-knowledge-discovery','Lucidworks Platform','lucidworks-platform','Enterprise AI-powered search and discovery platform combining data acquisition, hybrid relevance, enterprise security, AI orchestration, analytics and flexible deployment options.','https://lucidworks.com/platform');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat109_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS cat109_sources;
CREATE TEMPORARY TABLE cat109_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat109_sources VALUES
('glean-search','https://www.glean.com/enterprise-search','Glean Enterprise Search','Glean'),
('glean-search','https://www.glean.com/platform/browser-extension','Glean Browser Extension / Connectors','Glean'),
('coveo-platform','https://docs.coveo.com/en/3361/','Coveo Platform','Coveo'),
('coveo-platform','https://docs.coveo.com/en/n9de0370','Coveo Relevance Generative Answering','Coveo'),
('sinequa-enterprise-ai-search','https://www.sinequa.com/product/workplace-search/','Sinequa Enterprise AI Search','Sinequa'),
('sinequa-enterprise-ai-search','https://www.sinequa.com/product/','Sinequa Enterprise Agentic AI Platform','Sinequa'),
('guru-enterprise-ai-search','https://www.getguru.com/solutions/ai-enterprise-search','Guru Enterprise AI Search','Guru'),
('guru-enterprise-ai-search','https://www.getguru.com/product/how-it-works','How Guru Works','Guru'),
('lucidworks-platform','https://lucidworks.com/platform','Lucidworks Platform','Lucidworks'),
('lucidworks-platform','https://lucidworks.com/legal/compliance-security','Lucidworks Enterprise Security','Lucidworks'),
('lucidworks-platform','https://lucidworks.com/platform/deployment-options','Lucidworks Deployment Options','Lucidworks');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM cat109_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS cat109_facts;
CREATE TEMPORARY TABLE cat109_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat109_facts VALUES
-- Glean
('glean-search','es-connectors-indexing','supported',0.990,'Glean documents 100+ enterprise tools/connectors and real-time indexing across company applications; connector availability varies by source.','https://www.glean.com/enterprise-search'),
('glean-search','es-relevance-search','supported',0.990,'Glean documents deep-learning vector search, semantic understanding, personalization and continuously improving relevance.','https://www.glean.com/enterprise-search'),
('glean-search','es-permissions-aware','supported',0.990,'Glean documents enforcement of existing source permissions so users only see content they are authorized to access.','https://www.glean.com/enterprise-search'),
('glean-search','es-ai-answers','supported',0.990,'Glean documents grounded answers generated from relevant company knowledge and current indexed enterprise content.','https://www.glean.com/enterprise-search'),

-- Coveo
('coveo-platform','es-connectors-indexing','supported',0.990,'Coveo documents a unified index across cloud and on-premises repositories, websites, knowledge bases and catalogs.','https://docs.coveo.com/en/3361/'),
('coveo-platform','es-relevance-search','supported',0.990,'Coveo documents AI-powered relevance, dynamic ranking and search experiences based on query context and user behavior.','https://docs.coveo.com/en/3361/'),
('coveo-platform','es-permissions-aware','supported',0.980,'Coveo documents secure enterprise content retrieval; source-specific permission mapping must be configured correctly for each connector.','https://docs.coveo.com/en/3361/'),
('coveo-platform','es-ai-answers','supported',0.990,'Coveo Relevance Generative Answering generates grounded answers from indexed enterprise content; it is a paid product extension.','https://docs.coveo.com/en/n9de0370'),

-- Sinequa
('sinequa-enterprise-ai-search','es-connectors-indexing','supported',0.990,'Sinequa documents prebuilt connectors and unified access across enterprise systems, documents and data sources.','https://www.sinequa.com/product/'),
('sinequa-enterprise-ai-search','es-relevance-search','supported',0.990,'Sinequa documents keyword, vector, graph, structured and multimodal retrieval plus hybrid neural search.','https://www.sinequa.com/product/'),
('sinequa-enterprise-ai-search','es-permissions-aware','supported',0.990,'Sinequa documents inherited source permissions and document-level security for search and AI retrieval.','https://www.sinequa.com/product/'),
('sinequa-enterprise-ai-search','es-ai-answers','supported',0.990,'Sinequa documents grounded AI assistants and real-time contextual answers with reference trails.','https://www.sinequa.com/product/workplace-search/'),
('sinequa-enterprise-ai-search','es-analytics-admin','supported',0.970,'Sinequa documents a management console, configurable relevance/security controls and auditability; exact analytics depth should be validated for the target deployment.','https://www.sinequa.com/product/'),

-- Guru
('guru-enterprise-ai-search','es-connectors-indexing','supported',0.990,'Guru documents 100+ connectors and a unified knowledge index across enterprise applications, docs and chats.','https://www.getguru.com/product/how-it-works'),
('guru-enterprise-ai-search','es-relevance-search','supported',0.990,'Guru documents AI/semantic enterprise search across connected sources with personalized, relevant answers.','https://www.getguru.com/solutions/ai-enterprise-search'),
('guru-enterprise-ai-search','es-permissions-aware','supported',0.990,'Guru documents inherited permissions, least-privilege access and permission-aware answers.','https://www.getguru.com/solutions/ai-enterprise-search'),
('guru-enterprise-ai-search','es-ai-answers','supported',0.990,'Guru documents cited AI answers grounded in connected enterprise knowledge.','https://www.getguru.com/solutions/ai-enterprise-search'),
('guru-enterprise-ai-search','es-knowledge-curation','supported',0.990,'Guru documents verification workflows, stale/duplicate detection, knowledge reconciliation, gap detection and AI-assisted authoring.','https://www.getguru.com/product/how-it-works'),
('guru-enterprise-ai-search','es-analytics-admin','supported',0.970,'Guru documents visibility into questions, answers and sources plus auditability; exact analytics/reporting depth depends on configuration.','https://www.getguru.com/solutions/ai-enterprise-search'),

-- Lucidworks
('lucidworks-platform','es-connectors-indexing','supported',0.990,'Lucidworks documents Data Acquisition and connectors that unify structured and unstructured enterprise data sources.','https://lucidworks.com/platform'),
('lucidworks-platform','es-relevance-search','supported',0.990,'Lucidworks documents hybrid search, semantic AI, relevance tuning and enterprise search/discovery capabilities.','https://lucidworks.com/platform'),
('lucidworks-platform','es-permissions-aware','supported',0.990,'Lucidworks documents permission-aware data access, enterprise access controls and source-system security boundaries.','https://lucidworks.com/legal/compliance-security'),
('lucidworks-platform','es-ai-answers','supported',0.970,'Lucidworks documents generative-AI search/agent experiences grounded in enterprise search and connected data; exact agent modules depend on selected package.','https://lucidworks.com/platform'),
('lucidworks-platform','es-analytics-admin','supported',0.990,'Lucidworks documents analytics, no-code studios, relevance controls, KPI management and administration for search experiences.','https://lucidworks.com/platform');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat109_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat109_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party vendor documentation supporting this capability.'
FROM cat109_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Only explicit current deployment statements are promoted.
INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.99
FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug IN('coveo-platform','sinequa-enterprise-ai-search','lucidworks-platform')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.99
FROM products p JOIN deployment_models d ON d.slug='on-premise'
WHERE p.slug IN('sinequa-enterprise-ai-search','lucidworks-platform')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

-- Mobile administrative scope is not inferred from browser extensions, mobile access or collaboration integrations.
INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000
FROM products p CROSS JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') x
WHERE p.slug IN('glean-search','coveo-platform','sinequa-enterprise-ai-search','guru-enterprise-ai-search','lucidworks-platform')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

COMMIT;
