-- TechSelectAI Contract Lifecycle Management (CLM) catalog expansion.
-- Adds a new canonical CLM category and six evidence-backed enterprise products.
-- Official first-party evidence reviewed Sep 2026. Presence is not an endorsement.
-- Unknown != Unsupported. No Fit Score, recommendation ranking, review score, follower/community popularity or commercial placement logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('Contract Lifecycle Management (CLM)','contract-lifecycle-management','Software for requesting, authoring, negotiating, approving, executing, storing, analyzing and managing obligations, renewals and other activities across the contract lifecycle.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @clm_cat=(SELECT id FROM categories WHERE slug='contract-lifecycle-management' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@clm_cat,'Contract Creation & Negotiation','clm-creation-negotiation','Contract requests, templates, authoring, review, negotiation, redlining and approval workflows.',1),
(@clm_cat,'Repository, Obligations & Intelligence','clm-repository-intelligence','Contract repository, search, obligation/renewal tracking, analytics, AI and connected enterprise systems.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.sec,1
FROM modules m JOIN (
 SELECT 'clm-creation-negotiation' module_slug,'Contract authoring & templates' name,'clm-authoring-templates' slug,'Create contracts from approved templates, clauses or document-generation rules.',0 sec UNION ALL
 SELECT 'clm-creation-negotiation','Workflow & approvals','clm-workflow-approvals','Route contract requests, reviews and approvals through configurable business workflows.',0 UNION ALL
 SELECT 'clm-creation-negotiation','Negotiation & redlining','clm-negotiation-redlining','Support contract review, redlining, comparison, collaboration or negotiation workflows.',0 UNION ALL
 SELECT 'clm-repository-intelligence','Central contract repository & search','clm-repository-search','Store, organize and search contracts and associated structured contract data in a central system of record.',0 UNION ALL
 SELECT 'clm-repository-intelligence','Obligations, milestones & renewals','clm-obligations-renewals','Track contractual obligations, dates, milestones, renewals, expirations or related follow-up actions.',0 UNION ALL
 SELECT 'clm-repository-intelligence','Contract analytics / AI insights','clm-analytics-ai','Analyze contract data, terms, risks, performance or process metrics using reporting, analytics or AI.',0 UNION ALL
 SELECT 'clm-repository-intelligence','Enterprise integrations & APIs','clm-enterprise-integrations','Connect contract data and workflows with enterprise applications, APIs, CRM, ERP, procurement or collaboration systems.',0
) x ON x.module_slug=m.slug
WHERE m.category_id=@clm_cat
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Ironclad','ironclad','https://ironcladapp.com/','Digital contracting and contract lifecycle management software vendor.','active'),
('Icertis','icertis','https://www.icertis.com/','Enterprise contract intelligence and contract lifecycle management software vendor.','active'),
('Docusign','docusign','https://www.docusign.com/','Agreement management, electronic signature and contract lifecycle management software vendor.','active'),
('Conga','conga','https://conga.com/','Revenue lifecycle, document generation and contract lifecycle management software vendor.','active'),
('Sirion','sirion','https://www.sirion.ai/','AI-powered enterprise contract lifecycle and contract performance management software vendor.','active'),
('Agiloft','agiloft','https://www.agiloft.com/','Enterprise contract lifecycle management software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat106_products;
CREATE TEMPORARY TABLE cat106_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO cat106_products VALUES
('ironclad','contract-lifecycle-management','Ironclad CLM','ironclad-clm','Digital contract lifecycle management platform for standardized contract requests, authoring, negotiation, approvals, execution, repository management and contract analytics.','https://support.ironcladapp.com/hc/en-us/articles/12615001356567-Ironclad-Products-Overview'),
('icertis','contract-lifecycle-management','Icertis Contract Management','icertis-contract-management','Enterprise contract management platform for centralized contract repositories, standardized workflows, authoring, negotiation, obligations, AI-assisted insights and connected enterprise systems.','https://www.icertis.com/products/operate/contract-lifecycle-management/'),
('docusign','contract-lifecycle-management','Docusign CLM','docusign-clm','Contract lifecycle management platform for contract generation, review, approvals, workflows, centralized repository, obligations, analytics and connected agreement processes.','https://www.docusign.com/products/clm'),
('conga','contract-lifecycle-management','Conga CLM','conga-clm','Cloud contract lifecycle management for contract requests, drafting, redlining, approvals, signatures, repository management, obligations, renewals and reporting.','https://documentation.conga.com/en/clm-for-advantage-platform/preview/about-conga-clm'),
('sirion','contract-lifecycle-management','Sirion Agentic CLM','sirion-agentic-clm','AI-powered contract lifecycle management platform for centralizing contracts, authoring and negotiation, obligation tracking, performance management and enterprise contract intelligence.','https://www.sirion.ai/'),
('agiloft','contract-lifecycle-management','Agiloft CLM','agiloft-clm','AI-native contract lifecycle management platform for configurable request-to-renewal workflows, contract repository, authoring, obligations, analytics and enterprise integrations.','https://www.agiloft.com/platform/contract-management-software');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat106_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS cat106_sources;
CREATE TEMPORARY TABLE cat106_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat106_sources VALUES
('ironclad-clm','https://support.ironcladapp.com/hc/en-us/articles/12615001356567-Ironclad-Products-Overview','Ironclad Products Overview','Ironclad'),
('ironclad-clm','https://developer.ironcladapp.com/docs/ironclad-platform-overview','Ironclad Platform Overview','Ironclad'),
('ironclad-clm','https://support.ironcladapp.com/hc/en-us/articles/30794550432151-Ironclad-s-New-Dashboard-and-Workflow-Page-Overview-April-2025-Release','Ironclad Dashboard and Repository Overview','Ironclad'),
('ironclad-clm','https://support.ironcladapp.com/hc/en-us/articles/12447748332695-Ironclad-Insights-Overview','Ironclad Insights Overview','Ironclad'),
('icertis-contract-management','https://www.icertis.com/products/operate/contract-lifecycle-management/','Icertis Contract Management Platform','Icertis'),
('icertis-contract-management','https://www.icertis.com/products/operate/vera-obligations/','Icertis Vera Obligations','Icertis'),
('docusign-clm','https://www.docusign.com/products/clm','Docusign CLM','Docusign'),
('docusign-clm','https://www.docusign.com/legal/terms-and-conditions/schedule-docusignclm','Docusign CLM Service Schedule','Docusign'),
('conga-clm','https://documentation.conga.com/en/clm-for-advantage-platform/preview/about-conga-clm','About Conga CLM','Conga'),
('conga-clm','https://conga.com/legal-center/service-descriptions','Conga Service Descriptions','Conga'),
('sirion-agentic-clm','https://www.sirion.ai/','Sirion Agentic CLM Platform','Sirion'),
('sirion-agentic-clm','https://www.sirion.ai/library/platform-brochures/clm-platform/','Sirion Agentic CLM Platform Brochure','Sirion'),
('sirion-agentic-clm','https://www.sirion.ai/platform/store/contract-repository/','Sirion Contract Repository','Sirion'),
('agiloft-clm','https://www.agiloft.com/platform/contract-management-software','Agiloft CLM','Agiloft'),
('agiloft-clm','https://help.agiloft.com/space/SDA2603/521278417/Template%2BManagement','Agiloft Template Management','Agiloft');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM cat106_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS cat106_facts;
CREATE TEMPORARY TABLE cat106_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat106_facts VALUES
-- Ironclad CLM
('ironclad-clm','clm-authoring-templates','supported',0.990,'Ironclad documents contract workflows, document generation and in-browser contract editing; exact template depth depends on configured workflows.','https://developer.ironcladapp.com/docs/ironclad-platform-overview'),
('ironclad-clm','clm-workflow-approvals','supported',0.990,'Ironclad documents contract workflows covering collaboration, review, approvals and execution.','https://developer.ironcladapp.com/docs/ironclad-platform-overview'),
('ironclad-clm','clm-negotiation-redlining','supported',0.990,'Ironclad Editor supports contract editing, comments and accepting changes in a collaborative workflow.','https://developer.ironcladapp.com/docs/ironclad-platform-overview'),
('ironclad-clm','clm-repository-search','supported',0.990,'Ironclad documents a centralized repository/dashboard with search, filters, saved views and structured contract data.','https://support.ironcladapp.com/hc/en-us/articles/30794550432151-Ironclad-s-New-Dashboard-and-Workflow-Page-Overview-April-2025-Release'),
('ironclad-clm','clm-obligations-renewals','supported',0.970,'Ironclad documents repository support for contractual obligations plus lifecycle properties such as agreement, expiration and auto-renewal dates.','https://developer.ironcladapp.com/docs/ironclad-platform-overview'),
('ironclad-clm','clm-analytics-ai','supported',0.990,'Ironclad Insights provides real-time contract and process analytics across workflows and repository records.','https://support.ironcladapp.com/hc/en-us/articles/12447748332695-Ironclad-Insights-Overview'),
('ironclad-clm','clm-enterprise-integrations','supported',0.980,'Ironclad documents public APIs and third-party integrations; exact connectors should be verified for each deployment.','https://support.ironcladapp.com/hc/en-us/articles/30794550432151-Ironclad-s-New-Dashboard-and-Workflow-Page-Overview-April-2025-Release'),

-- Icertis
('icertis-contract-management','clm-authoring-templates','supported',0.990,'Icertis documents drafting from approved templates and clause libraries with Microsoft Word redlining.','https://www.icertis.com/products/operate/contract-lifecycle-management/'),
('icertis-contract-management','clm-workflow-approvals','supported',0.990,'Icertis documents standardized contract workflows with clear ownership from draft through execution.','https://www.icertis.com/products/operate/contract-lifecycle-management/'),
('icertis-contract-management','clm-negotiation-redlining','supported',0.990,'Icertis documents redline and review workflows directly in Microsoft Word.','https://www.icertis.com/products/operate/contract-lifecycle-management/'),
('icertis-contract-management','clm-repository-search','supported',0.990,'Icertis documents a governed centralized repository with searchable structured contract data and version history.','https://www.icertis.com/products/operate/contract-lifecycle-management/'),
('icertis-contract-management','clm-obligations-renewals','supported',0.990,'Icertis Vera Obligations discovers, assigns, tracks and reports contract obligations with alerts and workflows.','https://www.icertis.com/products/operate/vera-obligations/'),
('icertis-contract-management','clm-analytics-ai','supported',0.990,'Icertis documents AI-driven natural-language contract answers, summaries, insights and obligation dashboards.','https://www.icertis.com/products/operate/contract-lifecycle-management/'),
('icertis-contract-management','clm-enterprise-integrations','supported',0.990,'Icertis documents connected contract work inside SAP, Microsoft, Salesforce and Workday.','https://www.icertis.com/products/operate/contract-lifecycle-management/'),

-- Docusign CLM
('docusign-clm','clm-authoring-templates','supported',0.990,'Docusign documents dynamic templates, approved clause libraries and AI-assisted contract generation.','https://www.docusign.com/products/clm'),
('docusign-clm','clm-workflow-approvals','supported',0.990,'Docusign documents configurable drag-and-drop workflows and preconfigured steps for review and approval.','https://www.docusign.com/products/clm'),
('docusign-clm','clm-negotiation-redlining','supported',0.990,'Docusign documents AI-assisted review, negotiation, collaboration, comments and version control.','https://www.docusign.com/products/clm'),
('docusign-clm','clm-repository-search','supported',0.990,'Docusign documents a centralized AI-powered contract repository with keyword, concept and metadata search.','https://www.docusign.com/products/clm'),
('docusign-clm','clm-obligations-renewals','supported',0.990,'Docusign documents agreement reports for obligations, renewals and key milestones.','https://www.docusign.com/products/clm'),
('docusign-clm','clm-analytics-ai','supported',0.990,'Docusign documents contract analytics, risk scoring, AI review and extraction across contract data.','https://www.docusign.com/products/clm'),
('docusign-clm','clm-enterprise-integrations','supported',0.990,'Docusign documents prebuilt connectors and APIs for connecting CLM with business tools.','https://www.docusign.com/products/clm'),

-- Conga CLM
('conga-clm','clm-authoring-templates','supported',0.990,'Conga documents template-based contract creation and X-Author document generation.','https://conga.com/legal-center/service-descriptions'),
('conga-clm','clm-workflow-approvals','supported',0.990,'Conga documents contract requests, reviews, approvals and workflow automation across the lifecycle.','https://conga.com/legal-center/service-descriptions'),
('conga-clm','clm-negotiation-redlining','supported',0.990,'Conga documents redlining, comparison, negotiation and reconciliation workflows.','https://conga.com/legal-center/service-descriptions'),
('conga-clm','clm-repository-search','supported',0.990,'Conga documents a central repository with version control, hierarchy and search.','https://conga.com/legal-center/service-descriptions'),
('conga-clm','clm-obligations-renewals','supported',0.990,'Conga documents obligation reporting and renewal management throughout the contract lifecycle.','https://documentation.conga.com/en/clm-for-advantage-platform/preview/about-conga-clm'),
('conga-clm','clm-analytics-ai','supported',0.950,'Conga documents contract reports and search; deeper AI/Contract Intelligence capabilities may depend on edition or companion products.','https://conga.com/legal-center/service-descriptions'),
('conga-clm','clm-enterprise-integrations','supported',0.980,'Conga exposes contract APIs and supports integration with eSignature and enterprise workflows; exact integrations vary by platform edition.','https://documentation.conga.com/en/clm-for-advantage-platform/preview/about-conga-clm'),

-- Sirion
('sirion-agentic-clm','clm-authoring-templates','supported',0.990,'Sirion documents AI-assisted drafting and contract creation from enterprise playbooks.','https://www.sirion.ai/'),
('sirion-agentic-clm','clm-workflow-approvals','supported',0.970,'Sirion documents agentic automation for end-to-end contracting; exact approval configuration should be validated for the target implementation.','https://www.sirion.ai/library/platform-brochures/clm-platform/'),
('sirion-agentic-clm','clm-negotiation-redlining','supported',0.990,'Sirion documents AI-assisted risk review, negotiation and redlining.','https://www.sirion.ai/library/platform-brochures/clm-platform/'),
('sirion-agentic-clm','clm-repository-search','supported',0.990,'Sirion documents a secure, searchable, structured contract repository.','https://www.sirion.ai/platform/store/contract-repository/'),
('sirion-agentic-clm','clm-obligations-renewals','supported',0.990,'Sirion documents proactive obligation tracking, alerts, performance monitoring and renewal/expiration visibility.','https://www.sirion.ai/library/platform-brochures/clm-platform/'),
('sirion-agentic-clm','clm-analytics-ai','supported',0.990,'Sirion documents conversational AI, explainable insights and contract intelligence across the repository.','https://www.sirion.ai/'),
('sirion-agentic-clm','clm-enterprise-integrations','supported',0.970,'Sirion documents connecting contracts to enterprise tools and downstream applications; exact connectors should be verified.','https://www.sirion.ai/library/platform-brochures/clm-platform/'),

-- Agiloft
('agiloft-clm','clm-authoring-templates','supported',0.990,'Agiloft documents document templates, clause libraries and contract creation in its CLM platform.','https://help.agiloft.com/space/SDA2603/521278417/Template%2BManagement'),
('agiloft-clm','clm-workflow-approvals','supported',0.990,'Agiloft documents configurable no-code workflows, approvals and automations.','https://www.agiloft.com/platform/contract-management-software'),
('agiloft-clm','clm-negotiation-redlining','supported',0.980,'Agiloft documents contract comparison, recommended revisions and review workflows; exact redlining experience depends on configuration/integration.','https://www.agiloft.com/platform/contract-management-software'),
('agiloft-clm','clm-repository-search','supported',0.990,'Agiloft documents centralized governed contracts with searchable and reportable contract data.','https://www.agiloft.com/platform/contract-management-software'),
('agiloft-clm','clm-obligations-renewals','supported',0.990,'Agiloft documents automatic obligation tracking, notifications and contract renewal visibility.','https://www.agiloft.com/platform/contract-management-software'),
('agiloft-clm','clm-analytics-ai','supported',0.990,'Agiloft documents AI contract analysis, commitments extraction, dashboards and business intelligence.','https://www.agiloft.com/platform/contract-management-software'),
('agiloft-clm','clm-enterprise-integrations','supported',0.990,'Agiloft documents no-code integrations with more than 1,000 systems and enterprise applications.','https://www.agiloft.com/platform/contract-management-software');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat106_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat106_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party vendor documentation supporting this capability.'
FROM cat106_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Deployment is only promoted where the official product/service description is explicit.
INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.99
FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug IN('docusign-clm','conga-clm')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

-- Mobile administrative scope is not inferred from general mobile availability.
INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000
FROM products p CROSS JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') x
WHERE p.slug IN('ironclad-clm','icertis-contract-management','docusign-clm','conga-clm','sirion-agentic-clm','agiloft-clm')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

COMMIT;
