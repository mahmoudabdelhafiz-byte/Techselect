-- TechSelectAI catalog expansion: Project Management gap completion
-- Adds Zoho Projects without duplicating the Project Management taxonomy created by 013/038.
-- Facts are conservative, first-party-evidenced, and preserve Unknown != Unsupported.
SET NAMES utf8mb4;
START TRANSACTION;

SET @cat_id=(SELECT id FROM categories WHERE slug='project-management' LIMIT 1);

-- Reuse the existing Zoho vendor when present; keep this migration safe for partial installs.
INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Zoho','zoho','https://www.zoho.com/','Business software vendor offering project management, CRM, finance, collaboration and other cloud applications.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,@cat_id,'Zoho Projects','zoho-projects',
'Online project management software for planning, task execution, Gantt scheduling, collaboration, workload visibility, automation and reporting.',
'https://www.zoho.com/projects/','active',NOW()
FROM vendors v
WHERE v.slug='zoho' AND @cat_id IS NOT NULL
ON DUPLICATE KEY UPDATE
 vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),short_description=VALUES(short_description),
 website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

-- Official first-party evidence reviewed in Sep 2026.
INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',x.url,x.title,'Zoho',1,'verified','high',NOW()
FROM products p JOIN (
 SELECT 'https://help.zoho.com/portal/en/kb/projects/zoho-projects-overview/articles/zoho-projects-overview' url,'Zoho Projects: An Overview' title UNION ALL
 SELECT 'https://www.zoho.com/projects/project-management/essential-features.html','Essential Features of Project Management Software - Zoho Projects' UNION ALL
 SELECT 'https://help.zoho.com/portal/en/kb/projects/settings-in-zoho-projects/developer-space/developer-space-folder/articles/developer-space-in-zoho-projects','Developer Space in Zoho Projects' UNION ALL
 SELECT 'https://help.zoho.com/portal/en/kb/projects/settings-in-zoho-projects/automation/task-automation/articles/task-automation-in-zoho-projects','Task Automation in Zoho Projects'
) x
WHERE p.slug='zoho-projects'
AND NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=x.url);

DROP TEMPORARY TABLE IF EXISTS cat69_facts;
CREATE TEMPORARY TABLE cat69_facts(
 product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),
 confidence DECIMAL(4,3),limitations TEXT,source_url TEXT
);
INSERT INTO cat69_facts VALUES
('zoho-projects','pm-task-management','supported',0.99,NULL,'https://help.zoho.com/portal/en/kb/projects/zoho-projects-overview/articles/zoho-projects-overview'),
('zoho-projects','pm-task-project-management','supported',0.99,NULL,'https://help.zoho.com/portal/en/kb/projects/zoho-projects-overview/articles/zoho-projects-overview'),
('zoho-projects','pm-timeline-gantt','supported',0.99,NULL,'https://www.zoho.com/projects/project-management/essential-features.html'),
('zoho-projects','pm-timeline-schedule','supported',0.98,NULL,'https://www.zoho.com/projects/project-management/essential-features.html'),
('zoho-projects','pm-dependencies-milestones','supported',0.99,'Zoho documents milestones, task dependencies and critical-path visualization; availability can vary by plan.','https://www.zoho.com/projects/project-management/essential-features.html'),
('zoho-projects','pm-resource-workload','supported',0.98,'Workload reporting is documented; exact resource controls can vary by plan.','https://www.zoho.com/projects/project-management/essential-features.html'),
('zoho-projects','pm-workflow-automation','supported',0.99,'Workflow rules automate task/project actions; exact automation limits can vary by plan.','https://help.zoho.com/portal/en/kb/projects/settings-in-zoho-projects/automation/task-automation/articles/task-automation-in-zoho-projects'),
('zoho-projects','pm-dashboards-reporting','supported',0.98,NULL,'https://www.zoho.com/projects/project-management/essential-features.html'),
('zoho-projects','pm-team-collaboration','supported',0.98,NULL,'https://help.zoho.com/portal/en/kb/projects/zoho-projects-overview/articles/zoho-projects-overview'),
('zoho-projects','pm-api-access','supported',0.99,'Zoho documents APIs, extensions and service hooks in Developer Space.','https://help.zoho.com/portal/en/kb/projects/settings-in-zoho-projects/developer-space/developer-space-folder/articles/developer-space-in-zoho-projects');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat69_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE
 support_status=VALUES(support_status),limitations=VALUES(limitations),
 confidence_score=VALUES(confidence_score),last_verified_at=NOW();

-- Every other Project Management capability is explicitly unknown until first-party evidence is reviewed.
INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,c.id,NULL,'not_yet_verified',0
FROM products p
JOIN categories cat ON cat.id=p.category_id
JOIN modules m ON m.category_id=cat.id AND m.is_active=1
JOIN capabilities c ON c.module_id=m.id AND c.is_active=1
WHERE p.slug='zoho-projects' AND cat.slug='project-management'
AND NOT EXISTS(
 SELECT 1 FROM product_capabilities pc
 WHERE pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
);

-- Link every asserted capability fact to the exact first-party source used to verify it.
INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,f.limitations
FROM cat69_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Zoho Projects is documented as online project management software. Other deployment models remain unverified.
INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.95
FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug='zoho-projects'
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

-- Only API integration is asserted here. Every other integration remains explicitly unverified.
INSERT INTO product_integrations(product_id,integration_id,support_status,confidence_score)
SELECT p.id,i.id,
 CASE WHEN i.slug='api' THEN 'supported' ELSE 'not_yet_verified' END,
 CASE WHEN i.slug='api' THEN 0.99 ELSE 0 END
FROM products p JOIN integrations i
WHERE p.slug='zoho-projects'
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

DROP TEMPORARY TABLE IF EXISTS cat69_facts;
COMMIT;
