-- TechSelectAI catalog expansion batch 2 for #96 / #224
-- Adds Endpoint Security, Backup & Disaster Recovery, BI & Analytics, and Project & Work Management.
-- Product facts are intentionally conservative and use official vendor-owned sources only.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('Endpoint Security','endpoint-security','Endpoint protection, EDR/XDR, threat prevention, investigation and response for enterprise devices and workloads.',1),
('Backup & Disaster Recovery','backup-disaster-recovery','Backup, recovery, cyber resilience and disaster recovery software for enterprise workloads, cloud services and business data.',1),
('Business Intelligence & Analytics','business-intelligence-analytics','Business intelligence, reporting, dashboards, self-service analytics, data visualization and governed insight platforms.',1),
('Project & Work Management','project-management','Project, task, portfolio and collaborative work management software for teams and enterprises.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

-- Modules
INSERT INTO modules(category_id,name,slug,description,is_active)
SELECT c.id,x.name,x.slug,x.description,1 FROM categories c JOIN (
 SELECT 'endpoint-security' cat,'Protection & Detection' name,'endpoint-protection' slug,'Malware, ransomware, exploit and behavioral threat prevention and detection.' description UNION ALL
 SELECT 'endpoint-security','Investigation & Response','endpoint-response','Endpoint investigation, EDR, incident response and remediation.' UNION ALL
 SELECT 'backup-disaster-recovery','Backup & Protection','backup-protection','Backup coverage, policy, workload protection and cyber-resilient copies.' UNION ALL
 SELECT 'backup-disaster-recovery','Recovery & Resilience','backup-recovery','Recovery, restore, disaster recovery and resilience operations.' UNION ALL
 SELECT 'business-intelligence-analytics','Analytics & Visualization','bi-analytics','Dashboards, reports, visualization and self-service analytics.' UNION ALL
 SELECT 'business-intelligence-analytics','Data & Governance','bi-data-governance','Data connectivity, semantic modeling, collaboration and governance.' UNION ALL
 SELECT 'project-management','Projects & Tasks','pm-projects','Projects, tasks, dependencies, schedules and execution tracking.' UNION ALL
 SELECT 'project-management','Workflows & Portfolio','pm-workflows','Workflow automation, portfolio visibility, collaboration and reporting.'
) x ON x.cat=c.slug
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

-- Capabilities
INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.sec,1 FROM modules m JOIN (
 SELECT 'endpoint-protection' ms,'Malware & ransomware protection' name,'endpoint-malware-ransomware' slug,'Prevention and detection of malware and ransomware on protected endpoints.' description,1 sec UNION ALL
 SELECT 'endpoint-protection','Behavioral / exploit protection','endpoint-behavior-exploit','Behavioral, exploit or advanced threat protection beyond signature-only antivirus.',1 UNION ALL
 SELECT 'endpoint-response','Endpoint detection & response (EDR)','endpoint-edr','Endpoint telemetry, investigation and response capabilities.',1 UNION ALL
 SELECT 'endpoint-response','Centralized security management','endpoint-central-management','Central policy, alert and endpoint security management.',1 UNION ALL
 SELECT 'endpoint-response','Automated remediation / response','endpoint-automated-response','Automated containment, remediation or response workflows.',1 UNION ALL
 SELECT 'endpoint-response','Cross-platform endpoint coverage','endpoint-cross-platform','Protection across more than one major endpoint operating system.',1 UNION ALL
 SELECT 'backup-protection','Backup & restore','backup-core','Backup creation and restore of protected workloads or data.',0 UNION ALL
 SELECT 'backup-protection','Cloud / SaaS workload protection','backup-cloud-saas','Protection for public-cloud, SaaS or cloud-hosted workloads.',0 UNION ALL
 SELECT 'backup-protection','Ransomware / cyber-resilience protection','backup-ransomware-resilience','Capabilities designed to protect backup data and improve cyber recovery readiness.',1 UNION ALL
 SELECT 'backup-recovery','Disaster / rapid recovery','backup-disaster-recovery-capability','Recovery workflows designed to restore workloads and business services after disruption.',0 UNION ALL
 SELECT 'backup-recovery','Centralized backup management','backup-central-management','Central management, policy and visibility for backup operations.',0 UNION ALL
 SELECT 'backup-recovery','Hybrid / multi-environment protection','backup-hybrid-multicloud','Protection spanning multiple infrastructure, cloud or workload environments.',0 UNION ALL
 SELECT 'bi-analytics','Interactive dashboards & reports','bi-dashboards-reports','Interactive dashboards, reports and visual analysis.',0 UNION ALL
 SELECT 'bi-analytics','Self-service analytics','bi-self-service','Business-user exploration and self-service analysis capabilities.',0 UNION ALL
 SELECT 'bi-analytics','Data visualization','bi-data-visualization','Charts, visualizations and interactive analytical experiences.',0 UNION ALL
 SELECT 'bi-data-governance','Multiple data-source connectivity','bi-data-connectivity','Connectivity to multiple data sources for analysis.',0 UNION ALL
 SELECT 'bi-data-governance','Sharing & collaboration','bi-sharing-collaboration','Sharing, collaboration or governed distribution of analytical content.',0 UNION ALL
 SELECT 'bi-data-governance','Governed analytics / access control','bi-governance','Governance, permissions or managed analytical content.',1 UNION ALL
 SELECT 'pm-projects','Task & project management','pm-task-project-management','Create, organize, assign and track work across tasks and projects.',0 UNION ALL
 SELECT 'pm-projects','Timeline / schedule views','pm-timeline-schedule','Timeline, calendar, Gantt or schedule-oriented project views.',0 UNION ALL
 SELECT 'pm-projects','Dependencies & milestones','pm-dependencies-milestones','Dependency, milestone or critical project relationship tracking.',0 UNION ALL
 SELECT 'pm-workflows','Workflow automation','pm-workflow-automation','Rules, automation or workflow capabilities for recurring work.',0 UNION ALL
 SELECT 'pm-workflows','Dashboards & reporting','pm-dashboards-reporting','Project, portfolio or work reporting and dashboards.',0 UNION ALL
 SELECT 'pm-workflows','Team collaboration','pm-team-collaboration','Shared workspaces, comments, updates or collaborative execution.',0
) x ON x.ms=m.slug
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

-- Vendors
INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Microsoft','microsoft','https://www.microsoft.com/','Enterprise software, cloud, security and analytics vendor.','active'),
('CrowdStrike','crowdstrike','https://www.crowdstrike.com/','Cybersecurity platform vendor.','active'),
('SentinelOne','sentinelone','https://www.sentinelone.com/','AI-powered cybersecurity platform vendor.','active'),
('Sophos','sophos','https://www.sophos.com/','Cybersecurity software and managed security vendor.','active'),
('Veeam','veeam','https://www.veeam.com/','Backup, recovery and data resilience software vendor.','active'),
('Acronis','acronis','https://www.acronis.com/','Cyber protection, backup and recovery software vendor.','active'),
('Cohesity','cohesity','https://www.cohesity.com/','Enterprise data security and management vendor.','active'),
('Commvault','commvault','https://www.commvault.com/','Enterprise cyber resilience and data protection vendor.','active'),
('Salesforce','salesforce','https://www.salesforce.com/','Enterprise cloud software and analytics vendor.','active'),
('Qlik','qlik','https://www.qlik.com/','Analytics and data integration software vendor.','active'),
('Google Cloud','google-cloud','https://cloud.google.com/','Cloud computing, data and analytics platform vendor.','active'),
('Asana','asana','https://asana.com/','Work management software vendor.','active'),
('monday.com','monday-com','https://monday.com/','Work management software vendor.','active'),
('Atlassian','atlassian','https://www.atlassian.com/','Collaboration, software development and work management vendor.','active'),
('Smartsheet','smartsheet','https://www.smartsheet.com/','Enterprise work management software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

-- Products
DROP TEMPORARY TABLE IF EXISTS cat38_products;
CREATE TEMPORARY TABLE cat38_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,source_url TEXT,source_title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat38_products VALUES
('microsoft','endpoint-security','Microsoft Defender for Endpoint','microsoft-defender-endpoint','Enterprise endpoint security for prevention, detection, investigation and response across supported endpoint platforms.','https://www.microsoft.com/en-us/security/business/endpoint-security/microsoft-defender-endpoint','Microsoft Defender for Endpoint','Microsoft'),
('crowdstrike','endpoint-security','CrowdStrike Falcon Endpoint Security','crowdstrike-falcon-endpoint','Cloud-native endpoint security built around Falcon prevention, detection and response capabilities.','https://www.crowdstrike.com/en-us/platform/endpoint-security/','CrowdStrike Endpoint Security','CrowdStrike'),
('sentinelone','endpoint-security','SentinelOne Singularity Endpoint','sentinelone-singularity-endpoint','AI-powered endpoint protection, detection and response across enterprise endpoint environments.','https://www.sentinelone.com/platform/singularity-endpoint/','Singularity Endpoint','SentinelOne'),
('sophos','endpoint-security','Sophos Endpoint','sophos-endpoint','Endpoint protection and EDR capabilities managed through Sophos Central.','https://www.sophos.com/en-us/products/endpoint','Sophos Endpoint','Sophos'),
('veeam','backup-disaster-recovery','Veeam Data Platform','veeam-data-platform','Data resilience platform for backup, recovery and protection across enterprise workloads.','https://www.veeam.com/products/veeam-data-platform.html','Veeam Data Platform','Veeam'),
('acronis','backup-disaster-recovery','Acronis Cyber Protect','acronis-cyber-protect','Integrated backup, recovery and cyber protection platform for business workloads.','https://www.acronis.com/en-us/products/cyber-protect/','Acronis Cyber Protect','Acronis'),
('cohesity','backup-disaster-recovery','Cohesity Data Cloud','cohesity-data-cloud','Enterprise data security and management platform spanning backup, recovery and cyber resilience.','https://www.cohesity.com/products/data-cloud/','Cohesity Data Cloud','Cohesity'),
('commvault','backup-disaster-recovery','Commvault Cloud','commvault-cloud','Cloud-based cyber resilience and data protection platform for enterprise workloads and data.','https://www.commvault.com/platform','Commvault Cloud','Commvault'),
('microsoft','business-intelligence-analytics','Microsoft Power BI','microsoft-power-bi','Business intelligence and visualization platform for data preparation, modeling, reports and dashboards.','https://learn.microsoft.com/en-us/power-bi/fundamentals/power-bi-overview','What is Power BI?','Microsoft'),
('salesforce','business-intelligence-analytics','Tableau','tableau','Visual analytics and business intelligence platform for governed data exploration, dashboards and sharing.','https://www.tableau.com/products/tableau','Tableau','Tableau / Salesforce'),
('qlik','business-intelligence-analytics','Qlik Cloud Analytics','qlik-cloud-analytics','Cloud analytics platform for interactive analytics, reporting, AI-assisted insight and governed collaboration.','https://help.qlik.com/en-US/evaluation-guides/Content/analytics/analytics.htm','Qlik Cloud Analytics','Qlik'),
('google-cloud','business-intelligence-analytics','Looker','google-looker','Google Cloud business intelligence platform for governed analytics, dashboards, exploration and embedded insights.','https://cloud.google.com/looker','Looker','Google Cloud'),
('asana','project-management','Asana','asana','Work management platform for projects, tasks, workflows, goals and cross-team collaboration.','https://asana.com/product','Asana Work Management','Asana'),
('monday-com','project-management','monday work management','monday-work-management','Work management platform for projects, processes, workflows and team collaboration.','https://monday.com/work-management','monday work management','monday.com'),
('atlassian','project-management','Jira','jira','Atlassian work management and issue tracking platform for project planning, execution and team workflows.','https://www.atlassian.com/software/jira','Jira','Atlassian'),
('smartsheet','project-management','Smartsheet','smartsheet','Enterprise work management platform for projects, workflows, resource visibility, dashboards and collaboration.','https://www.smartsheet.com/','Smartsheet','Smartsheet');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.source_url,'active',NOW()
FROM cat38_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',x.source_url,x.source_title,x.publisher,1,'verified','high',NOW()
FROM cat38_products x JOIN products p ON p.slug=x.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=x.source_url);

-- Conservative product capability facts. These are broad capabilities directly represented by the official product pages above.
DROP TEMPORARY TABLE IF EXISTS cat38_facts;
CREATE TEMPORARY TABLE cat38_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3));

-- Endpoint: all four products evidence prevention, endpoint detection/response and central management.
INSERT INTO cat38_facts
SELECT p.product_slug,c.capability_slug,'supported',0.90 FROM
(SELECT 'microsoft-defender-endpoint' product_slug UNION ALL SELECT 'crowdstrike-falcon-endpoint' UNION ALL SELECT 'sentinelone-singularity-endpoint' UNION ALL SELECT 'sophos-endpoint') p
CROSS JOIN
(SELECT 'endpoint-malware-ransomware' capability_slug UNION ALL SELECT 'endpoint-behavior-exploit' UNION ALL SELECT 'endpoint-edr' UNION ALL SELECT 'endpoint-central-management') c;

-- Backup/DR: all four products evidence backup/recovery, cyber resilience and centralized multi-environment protection positioning.
INSERT INTO cat38_facts
SELECT p.product_slug,c.capability_slug,'supported',0.88 FROM
(SELECT 'veeam-data-platform' product_slug UNION ALL SELECT 'acronis-cyber-protect' UNION ALL SELECT 'cohesity-data-cloud' UNION ALL SELECT 'commvault-cloud') p
CROSS JOIN
(SELECT 'backup-core' capability_slug UNION ALL SELECT 'backup-ransomware-resilience' UNION ALL SELECT 'backup-central-management' UNION ALL SELECT 'backup-hybrid-multicloud') c;

-- BI: all four products evidence dashboards/visualization, self-service exploration, connectivity and sharing/governance.
INSERT INTO cat38_facts
SELECT p.product_slug,c.capability_slug,'supported',0.90 FROM
(SELECT 'microsoft-power-bi' product_slug UNION ALL SELECT 'tableau' UNION ALL SELECT 'qlik-cloud-analytics' UNION ALL SELECT 'google-looker') p
CROSS JOIN
(SELECT 'bi-dashboards-reports' capability_slug UNION ALL SELECT 'bi-self-service' UNION ALL SELECT 'bi-data-visualization' UNION ALL SELECT 'bi-data-connectivity' UNION ALL SELECT 'bi-sharing-collaboration') c;

-- PM/work management: all four products evidence project/task management, schedule-style views, reporting and collaboration/workflows.
INSERT INTO cat38_facts
SELECT p.product_slug,c.capability_slug,'supported',0.88 FROM
(SELECT 'asana' product_slug UNION ALL SELECT 'monday-work-management' UNION ALL SELECT 'jira' UNION ALL SELECT 'smartsheet') p
CROSS JOIN
(SELECT 'pm-task-project-management' capability_slug UNION ALL SELECT 'pm-timeline-schedule' UNION ALL SELECT 'pm-dashboards-reporting' UNION ALL SELECT 'pm-team-collaboration') c;

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.confidence,NOW()
FROM cat38_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

-- Every unresearched capability stays explicitly not_yet_verified, never not_supported.
INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat38_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

-- Link researched capability facts to each product's official evidence source.
INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Official vendor-owned product documentation; broad category capability only.'
FROM cat38_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN cat38_products x ON x.product_slug=p.slug
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=x.source_url;

-- Only assert public SaaS deployment where the product is clearly offered as a cloud service; other deployment models remain unverified.
INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.90 FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug IN('microsoft-power-bi','tableau','qlik-cloud-analytics','google-looker','asana','monday-work-management','jira','smartsheet')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

COMMIT;
