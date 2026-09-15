-- TechSelectAI catalog expansion: Document Management / ECM batch 1
-- Adds one strategic category and five recognizable products using first-party evidence reviewed in Sep 2026.
-- Preserves Unknown != Unsupported, recommendation neutrality, and evidence-parity principles.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('Document Management / ECM','document-management-ecm','Document management and enterprise content management platforms for governed content repositories, metadata, search, versioning, workflow, records lifecycle, access controls and enterprise content integrations.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO modules(category_id,name,slug,description,is_active)
SELECT c.id,x.name,x.slug,x.description,1 FROM categories c JOIN (
 SELECT 'document-management-ecm' cat,'Document & Content Control' name,'ecm-content-control' slug,'Governed document repositories, metadata, version control and enterprise content search.' description UNION ALL
 SELECT 'document-management-ecm','Workflow & Information Governance','ecm-governance-workflow','Document-centric workflow, records lifecycle, access governance and enterprise content integrations.'
) x ON x.cat=c.slug
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.sec,1 FROM modules m JOIN (
 SELECT 'ecm-content-control' ms,'Document / content repository' name,'ecm-document-repository' slug,'Store, organize and manage enterprise documents and content in governed repositories.' description,0 sec UNION ALL
 SELECT 'ecm-content-control','Metadata & classification','ecm-metadata-classification','Apply structured metadata, tags, content types or classification to organize and govern content.',0 UNION ALL
 SELECT 'ecm-content-control','Version control & history','ecm-version-control','Track document versions and support access to or restoration of prior versions.',0 UNION ALL
 SELECT 'ecm-content-control','Enterprise content search','ecm-search-discovery','Search and discover documents and enterprise content using indexed content, metadata or related context.',0 UNION ALL
 SELECT 'ecm-governance-workflow','Document workflow & automation','ecm-workflow-automation','Automate document-centric routing, review, approval, task or lifecycle workflows.',0 UNION ALL
 SELECT 'ecm-governance-workflow','Records & retention management','ecm-records-retention','Apply records, retention, disposition, hold or lifecycle policies to governed content.',1 UNION ALL
 SELECT 'ecm-governance-workflow','Permissions & access governance','ecm-access-governance','Control and govern access to enterprise documents and content using permissions, policies or roles.',1 UNION ALL
 SELECT 'ecm-governance-workflow','Enterprise content integrations','ecm-enterprise-integrations','Connect governed content with productivity suites, business applications or other content repositories.',0
) x ON x.ms=m.slug
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Microsoft','microsoft','https://www.microsoft.com/','Enterprise software, productivity, collaboration and cloud platform vendor.','active'),
('OpenText','opentext','https://www.opentext.com/','Enterprise information management and content-management software vendor.','active'),
('M-Files','m-files','https://www.m-files.com/','Metadata-driven document and information management software vendor.','active'),
('Box','box','https://www.box.com/','Enterprise content management, collaboration and workflow software vendor.','active'),
('Egnyte','egnyte','https://www.egnyte.com/','Enterprise content collaboration, governance and workflow software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat90_products;
CREATE TEMPORARY TABLE cat90_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO cat90_products VALUES
('microsoft','document-management-ecm','Microsoft SharePoint','microsoft-sharepoint','Enterprise content and collaboration platform for document libraries, metadata, search, version history, records retention and governed Microsoft 365 file collaboration.','https://www.microsoft.com/en-us/microsoft-365/sharepoint/collaboration'),
('opentext','document-management-ecm','OpenText Content Management','opentext-content-management','Enterprise content management platform, also known as Extended ECM, for governed document management, business workspaces, workflows, records management, search and business-application integration.','https://www.opentext.com/products/content-management'),
('m-files','document-management-ecm','M-Files','m-files','Metadata-driven document and information management platform for organizing, finding, versioning and governing content with automated workflows and permissions.','https://www.m-files.com/'),
('box','document-management-ecm','Box','box','Enterprise content management platform for secure content storage and collaboration, metadata, search, governance, records management and content-centric workflows.','https://www.box.com/overview'),
('egnyte','document-management-ecm','Egnyte','egnyte','Enterprise content collaboration and governance platform for centralized files, metadata, governed access, content lifecycle policies, integrations and document-centric workflows.','https://www.egnyte.com/');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat90_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS cat90_sources;
CREATE TEMPORARY TABLE cat90_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat90_sources VALUES
('microsoft-sharepoint','https://www.microsoft.com/en-us/microsoft-365/sharepoint/collaboration','Microsoft SharePoint collaboration and content platform','Microsoft'),
('microsoft-sharepoint','https://learn.microsoft.com/en-us/sharepoint/version-overview','SharePoint version history overview','Microsoft'),
('microsoft-sharepoint','https://learn.microsoft.com/en-us/purview/retention-policies-sharepoint','Retention for SharePoint and OneDrive','Microsoft'),
('microsoft-sharepoint','https://learn.microsoft.com/en-us/sharepoint/deploy-file-collaboration','Plan and deploy a file collaboration environment','Microsoft'),
('opentext-content-management','https://www.opentext.com/products/content-management','OpenText Content Management (Extended ECM)','OpenText'),
('m-files','https://www.m-files.com/supplemental/document-control/','M-Files Document Control','M-Files'),
('m-files','https://www.m-files.com/supplemental/document-management-workflow/','M-Files Document Management Workflow','M-Files'),
('box','https://www.box.com/overview','Box Intelligent Content Management Platform','Box'),
('box','https://www.box.com/en-gb/content-management/enterprise','Box Enterprise Content Management','Box'),
('egnyte','https://www.egnyte.com/','Egnyte Content Cloud','Egnyte'),
('egnyte','https://www.egnyte.com/products/governance','Egnyte Data Governance','Egnyte'),
('egnyte','https://helpdesk.egnyte.com/hc/en-us/articles/18529386415373-Getting-Started-Guide-for-Security-and-Governance','Egnyte Security and Governance Getting Started','Egnyte'),
('egnyte','https://www.egnyte.com/press-releases/egnyte-launches-ai-powered-workflow-automation-with-built-in-governance-to-help-organizations-scale-efficiently-and-securely','Egnyte AI-Powered Workflow Automation','Egnyte');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM cat90_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS cat90_facts;
CREATE TEMPORARY TABLE cat90_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat90_facts VALUES
-- Microsoft SharePoint
('microsoft-sharepoint','ecm-document-repository','supported',0.990,'SharePoint is documented as a secure Microsoft 365 file collaboration environment and content platform.','https://learn.microsoft.com/en-us/sharepoint/deploy-file-collaboration'),
('microsoft-sharepoint','ecm-metadata-classification','supported',0.970,'SharePoint content management supports structured content organization and metadata-driven information management.','https://www.microsoft.com/en-us/microsoft-365/sharepoint/collaboration'),
('microsoft-sharepoint','ecm-version-control','supported',0.990,'Microsoft documents SharePoint version history as a built-in capability for viewing, tracking and restoring prior file versions.','https://learn.microsoft.com/en-us/sharepoint/version-overview'),
('microsoft-sharepoint','ecm-search-discovery','supported',0.970,'Microsoft documents intelligent search across SharePoint content.','https://www.microsoft.com/en-us/microsoft-365/sharepoint/collaboration'),
('microsoft-sharepoint','ecm-records-retention','supported',0.990,'Microsoft Purview retention policies and labels apply to SharePoint content and versions.','https://learn.microsoft.com/en-us/purview/retention-policies-sharepoint'),
('microsoft-sharepoint','ecm-access-governance','supported',0.970,'Microsoft documents SharePoint as part of a secure file collaboration environment with governance and security controls.','https://learn.microsoft.com/en-us/sharepoint/deploy-file-collaboration'),

-- OpenText Content Management / Extended ECM
('opentext-content-management','ecm-document-repository','supported',0.990,'OpenText documents centralized document management and governed enterprise content workspaces.','https://www.opentext.com/products/content-management'),
('opentext-content-management','ecm-metadata-classification','supported',0.980,'OpenText documents metadata-driven content organization and contextual business workspaces.','https://www.opentext.com/products/content-management'),
('opentext-content-management','ecm-version-control','supported',0.980,'OpenText documents document editing and version control within Content Management.','https://www.opentext.com/products/content-management'),
('opentext-content-management','ecm-search-discovery','supported',0.990,'OpenText documents enterprise content search and AI-assisted content discovery.','https://www.opentext.com/products/content-management'),
('opentext-content-management','ecm-workflow-automation','supported',0.990,'OpenText documents workflow automation for document-centric business processes.','https://www.opentext.com/products/content-management'),
('opentext-content-management','ecm-records-retention','supported',0.990,'OpenText documents information governance and records management including legal holds and audit controls.','https://www.opentext.com/products/content-management'),
('opentext-content-management','ecm-access-governance','supported',0.990,'OpenText documents governed permissions and information-control features.','https://www.opentext.com/products/content-management'),
('opentext-content-management','ecm-enterprise-integrations','supported',0.990,'OpenText documents integrations with SAP, Salesforce, Microsoft and Guidewire business applications.','https://www.opentext.com/products/content-management'),

-- M-Files
('m-files','ecm-document-repository','supported',0.990,'M-Files provides a unified governed view of documents across repositories and business systems.','https://www.m-files.com/supplemental/document-control/'),
('m-files','ecm-metadata-classification','supported',0.990,'M-Files explicitly uses metadata to organize, share, process and authorize access to content.','https://www.m-files.com/supplemental/document-control/'),
('m-files','ecm-version-control','supported',0.990,'M-Files documents authoritative-copy document version control.','https://www.m-files.com/supplemental/document-control/'),
('m-files','ecm-search-discovery','supported',0.990,'M-Files documents metadata-driven document search and rapid retrieval.','https://www.m-files.com/supplemental/document-control/'),
('m-files','ecm-workflow-automation','supported',0.990,'M-Files documents metadata-driven automated document workflows and approval tasks.','https://www.m-files.com/supplemental/document-management-workflow/'),
('m-files','ecm-access-governance','supported',0.990,'M-Files documents dynamic permissions, role-based access and encryption for governed documents.','https://www.m-files.com/supplemental/document-control/'),
('m-files','ecm-enterprise-integrations','supported',0.980,'M-Files documents connections to SharePoint, Teams, CRM systems, network folders and other repositories.','https://www.m-files.com/supplemental/document-control/'),

-- Box
('box','ecm-document-repository','supported',0.990,'Box describes its platform as enterprise content management for managing and organizing enterprise files at scale.','https://www.box.com/overview'),
('box','ecm-metadata-classification','supported',0.990,'Box documents flexible metadata as a core enterprise content-management capability.','https://www.box.com/overview'),
('box','ecm-search-discovery','supported',0.990,'Box documents advanced enterprise content search.','https://www.box.com/overview'),
('box','ecm-workflow-automation','supported',0.990,'Box documents automation of content-centric workflows.','https://www.box.com/overview'),
('box','ecm-records-retention','supported',0.990,'Box documents governance and records-management capabilities across the content lifecycle.','https://www.box.com/overview'),
('box','ecm-access-governance','supported',0.990,'Box documents enterprise security, compliance and governed content controls.','https://www.box.com/overview'),
('box','ecm-enterprise-integrations','supported',0.970,'Box documents enterprise content-management integration as part of its unified content platform.','https://www.box.com/en-gb/content-management/enterprise'),

-- Egnyte
('egnyte','ecm-document-repository','supported',0.990,'Egnyte documents a unified platform that centralizes enterprise files, apps and workflows.','https://www.egnyte.com/'),
('egnyte','ecm-metadata-classification','supported',0.990,'Egnyte documents content classification and metadata extraction for governed content.','https://www.egnyte.com/products/governance'),
('egnyte','ecm-search-discovery','supported',0.980,'Egnyte documents searchable structured content produced by metadata extraction and AI workflows.','https://www.egnyte.com/press-releases/egnyte-launches-ai-powered-workflow-automation-with-built-in-governance-to-help-organizations-scale-efficiently-and-securely'),
('egnyte','ecm-workflow-automation','supported',0.990,'Egnyte documents workflow automation for document-intensive processes within the governed content platform.','https://www.egnyte.com/press-releases/egnyte-launches-ai-powered-workflow-automation-with-built-in-governance-to-help-organizations-scale-efficiently-and-securely'),
('egnyte','ecm-records-retention','supported',0.980,'Egnyte governance supports content lifecycle policies for retention, archive and deletion.','https://helpdesk.egnyte.com/hc/en-us/articles/18529386415373-Getting-Started-Guide-for-Security-and-Governance'),
('egnyte','ecm-access-governance','supported',0.990,'Egnyte documents access control, permission governance and sensitive-content protection.','https://www.egnyte.com/products/governance'),
('egnyte','ecm-enterprise-integrations','supported',0.990,'Egnyte documents integrations with Microsoft 365, Google Drive, Amazon S3, Splunk and other business applications.','https://www.egnyte.com/products/governance');

-- Insert any fact row that is not present yet, then refresh matching rows.
INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat90_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
WHERE NOT EXISTS(
 SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
);

UPDATE product_capabilities pc
JOIN products p ON p.id=pc.product_id
JOIN capabilities c ON c.id=pc.capability_id
JOIN cat90_facts f ON f.product_slug=p.slug AND f.capability_slug=c.slug
SET pc.support_status=f.support_status,pc.limitations=f.limitations,pc.confidence_score=f.confidence,pc.last_verified_at=NOW()
WHERE pc.edition_id IS NULL;

-- Explicitly represent every unverified category capability as not_yet_verified.
INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score,last_verified_at)
SELECT p.id,cap.id,NULL,'not_yet_verified',0.000,NULL
FROM cat90_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id AND cap.is_active=1
WHERE NOT EXISTS(
 SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL
);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,f.limitations
FROM cat90_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- New products were added after migration 086, so seed explicit mobile-access unknowns here.
INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,scope_notes,evidence_url,evidence_type,confidence_score,last_verified_at)
SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','Mobile availability and scope have not yet been verified from current first-party evidence.',NULL,'not_yet_verified',0.000,NULL
FROM cat90_products cp JOIN products p ON p.slug=cp.product_slug
CROSS JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') x
WHERE NOT EXISTS(SELECT 1 FROM product_mobile_access pma WHERE pma.product_id=p.id AND pma.platform=x.platform);

DROP TEMPORARY TABLE IF EXISTS cat90_facts;
DROP TEMPORARY TABLE IF EXISTS cat90_sources;
DROP TEMPORARY TABLE IF EXISTS cat90_products;
COMMIT;
