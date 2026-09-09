-- TechSelectAI catalog expansion: Project Management batch 1
-- Adds Microsoft Planner / Project, Asana, monday.com, ClickUp, Jira, Smartsheet and Wrike
-- using official vendor documentation reviewed in Sep 2026.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('Project Management','project-management','Project and work management software for tasks, timelines, dependencies, portfolios, resources, automation, reporting and collaboration.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @cat_id=(SELECT id FROM categories WHERE slug='project-management' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@cat_id,'Planning & Execution','pm-planning-execution','Tasks, schedules, timelines, dependencies and agile execution.',1),
(@cat_id,'Portfolio & Resources','pm-portfolio-resources','Portfolio visibility, goals, resource and workload management.',1),
(@cat_id,'Automation & Reporting','pm-automation-reporting','Workflow automation, dashboards, reporting and intake.',1),
(@cat_id,'Enterprise & Integration','pm-enterprise-integration','APIs, enterprise access and extensibility.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.security,1
FROM modules m JOIN (
 SELECT 'pm-planning-execution' module_slug,'Task management' name,'pm-task-management' slug,'Create, assign, prioritize and track project tasks.' description,0 security UNION ALL
 SELECT 'pm-planning-execution','Timeline / Gantt planning','pm-timeline-gantt','Plan work on timelines or Gantt-style schedules.',0 UNION ALL
 SELECT 'pm-planning-execution','Dependencies & milestones','pm-dependencies-milestones','Track task dependencies, milestones and critical sequencing.',0 UNION ALL
 SELECT 'pm-planning-execution','Agile / sprint planning','pm-agile-sprints','Support agile boards, sprints or iterative delivery planning.',0 UNION ALL
 SELECT 'pm-portfolio-resources','Project portfolio management','pm-project-portfolio','Monitor and govern multiple projects, programs or initiatives.',0 UNION ALL
 SELECT 'pm-portfolio-resources','Resource & workload management','pm-resource-workload','Plan capacity, workload and resource allocation across work.',0 UNION ALL
 SELECT 'pm-portfolio-resources','Goals / OKR alignment','pm-goals-okrs','Connect work to goals, objectives or strategic outcomes.',0 UNION ALL
 SELECT 'pm-automation-reporting','Workflow automation','pm-workflow-automation','Automate project routing, updates, reminders and workflow actions.',0 UNION ALL
 SELECT 'pm-automation-reporting','Dashboards & reporting','pm-dashboards-reporting','Provide project, portfolio or operational dashboards and reports.',0 UNION ALL
 SELECT 'pm-automation-reporting','Forms / work intake','pm-forms-intake','Capture structured work requests or project intake through forms.',0 UNION ALL
 SELECT 'pm-enterprise-integration','API access','pm-api-access','Vendor-supported API access for integrations and custom automation.',0 UNION ALL
 SELECT 'pm-enterprise-integration','Single sign-on (SSO)','pm-sso','Enterprise single sign-on for work management users.',1
) x ON x.module_slug=m.slug
WHERE m.category_id=@cat_id
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Microsoft','microsoft','https://www.microsoft.com/','Enterprise software and cloud platform vendor.','active'),
('Asana','asana','https://asana.com/','Work management and project collaboration software vendor.','active'),
('monday.com','monday','https://monday.com/','Work management, project and workflow platform vendor.','active'),
('ClickUp','clickup','https://clickup.com/','Project, work management and collaboration software vendor.','active'),
('Atlassian','atlassian','https://www.atlassian.com/','Collaboration, development and work management software vendor.','active'),
('Smartsheet','smartsheet','https://www.smartsheet.com/','Collaborative work management and project execution platform vendor.','active'),
('Wrike','wrike','https://www.wrike.com/','Enterprise work management and project collaboration software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,@cat_id,x.name,x.slug,x.description,x.url,'active',NOW()
FROM vendors v JOIN (
 SELECT 'microsoft' vendor_slug,'Microsoft Planner / Project' name,'microsoft-planner-project' slug,'Microsoft work and project management experience combining Planner with Project capabilities for tasks, schedules, resources, dashboards and portfolio planning.' description,'https://www.microsoft.com/en-us/microsoft-365/planner/microsoft-planner' url UNION ALL
 SELECT 'asana','Asana','asana','Work management platform for tasks, projects, goals, portfolios, workflows, resource visibility and reporting.','https://asana.com/product' UNION ALL
 SELECT 'monday','monday work management','monday-work-management','Flexible work management platform for projects, workflows, dashboards, resource planning, automations and integrations.','https://monday.com/' UNION ALL
 SELECT 'clickup','ClickUp','clickup','Work management platform for tasks, projects, sprints, goals, dashboards, automations and collaboration.','https://clickup.com/' UNION ALL
 SELECT 'atlassian','Jira','jira','Atlassian work and project management platform for planning, tracking, dependencies, automation, reporting and agile delivery.','https://www.atlassian.com/software/jira' UNION ALL
 SELECT 'smartsheet','Smartsheet','smartsheet','Collaborative work management platform with Gantt planning, portfolios, workload, dashboards, automation and enterprise controls.','https://www.smartsheet.com/' UNION ALL
 SELECT 'wrike','Wrike','wrike','Enterprise work management platform with Gantt, resource planning, dashboards, automation, integrations and portfolio visibility.','https://www.wrike.com/'
) x ON x.vendor_slug=v.slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

-- Official vendor evidence sources.
INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',x.url,x.title,x.publisher,1,'verified','high',NOW()
FROM products p JOIN (
 SELECT 'microsoft-planner-project' product_slug,'https://www.microsoft.com/en-us/microsoft-365/planner/microsoft-planner' url,'Microsoft Planner','Microsoft' publisher UNION ALL
 SELECT 'microsoft-planner-project','https://www.microsoft.com/en-us/microsoft-365/planner/project-plan-3','Planner and Project Plan 3','Microsoft' UNION ALL
 SELECT 'microsoft-planner-project','https://www.microsoft.com/en-us/microsoft-365/planner/project-portfolio-management','Microsoft Project portfolio management','Microsoft' UNION ALL
 SELECT 'asana','https://asana.com/features','Asana features','Asana' UNION ALL
 SELECT 'asana','https://asana.com/features/goals-reporting/portfolios','Asana portfolios','Asana' UNION ALL
 SELECT 'asana','https://help.asana.com/s/article/learn-about-asana-advanced-features','Asana Advanced features','Asana' UNION ALL
 SELECT 'monday-work-management','https://monday.com/projects/features','monday.com project features','monday.com' UNION ALL
 SELECT 'monday-work-management','https://monday.com/features/automations','monday.com automations','monday.com' UNION ALL
 SELECT 'monday-work-management','https://developer.monday.com/api-reference','monday.com Platform API','monday.com' UNION ALL
 SELECT 'clickup','https://clickup.com/features','ClickUp features','ClickUp' UNION ALL
 SELECT 'clickup','https://developer.clickup.com/docs/Getting%20Started','ClickUp API','ClickUp' UNION ALL
 SELECT 'clickup','https://help.clickup.com/hc/en-us/articles/6305043992343-Intro-to-single-sign-on-SSO','ClickUp single sign-on','ClickUp' UNION ALL
 SELECT 'jira','https://www.atlassian.com/software/jira/features','Jira features','Atlassian' UNION ALL
 SELECT 'jira','https://www.atlassian.com/software/jira/features/automation','Jira automation','Atlassian' UNION ALL
 SELECT 'jira','https://developer.atlassian.com/server/jira/platform/jira-rest-apis-7372883/','Jira REST APIs','Atlassian' UNION ALL
 SELECT 'smartsheet','https://www.smartsheet.com/platform/features','Smartsheet features','Smartsheet' UNION ALL
 SELECT 'smartsheet','https://developers.smartsheet.com/','Smartsheet Developers and API','Smartsheet' UNION ALL
 SELECT 'wrike','https://www.wrike.com/features/','Wrike features','Wrike' UNION ALL
 SELECT 'wrike','https://www.wrike.com/features/dashboards/','Wrike dashboards','Wrike'
) x ON x.product_slug=p.slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=x.url);

DROP TEMPORARY TABLE IF EXISTS pm13_facts;
CREATE TEMPORARY TABLE pm13_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO pm13_facts VALUES
-- Microsoft Planner / Project
('microsoft-planner-project','pm-task-management','supported',0.99,NULL,'https://www.microsoft.com/en-us/microsoft-365/planner/microsoft-planner'),
('microsoft-planner-project','pm-timeline-gantt','supported',0.98,'Advanced schedule features depend on Planner/Project plan level.','https://www.microsoft.com/en-us/microsoft-365/planner/project-plan-3'),
('microsoft-planner-project','pm-dependencies-milestones','supported',0.98,'Advanced dependencies, lead-lag and critical-path capabilities are plan-dependent.','https://www.microsoft.com/en-us/microsoft-365/planner/project-plan-3'),
('microsoft-planner-project','pm-agile-sprints','supported',0.95,NULL,'https://www.microsoft.com/en-us/microsoft-365/planner/microsoft-planner'),
('microsoft-planner-project','pm-project-portfolio','supported',0.95,'Portfolio management depth depends on the Microsoft Project/Planner offering used.','https://www.microsoft.com/en-us/microsoft-365/planner/project-portfolio-management'),
('microsoft-planner-project','pm-resource-workload','supported',0.95,'Advanced resource management is associated with premium Project/Planner capabilities.','https://www.microsoft.com/en-us/microsoft-365/planner/microsoft-planner'),
('microsoft-planner-project','pm-goals-okrs','supported',0.90,'Planner supports plan goals; enterprise strategic alignment depth should be confirmed by plan.','https://www.microsoft.com/en-us/microsoft-365/planner/microsoft-planner'),
('microsoft-planner-project','pm-dashboards-reporting','supported',0.95,NULL,'https://www.microsoft.com/en-us/microsoft-365/planner/microsoft-planner'),

-- Asana
('asana','pm-task-management','supported',0.99,NULL,'https://asana.com/features'),
('asana','pm-project-portfolio','supported',0.99,NULL,'https://asana.com/features/goals-reporting/portfolios'),
('asana','pm-resource-workload','supported',0.98,'Portfolio workload and resource management are plan-dependent.','https://help.asana.com/s/article/learn-about-asana-advanced-features'),
('asana','pm-goals-okrs','supported',0.99,NULL,'https://asana.com/features'),
('asana','pm-workflow-automation','supported',0.99,'Rules and advanced workflow capabilities vary by plan.','https://asana.com/features'),
('asana','pm-dashboards-reporting','supported',0.99,NULL,'https://asana.com/features'),
('asana','pm-forms-intake','supported',0.98,'Advanced branching and workflow functionality vary by plan.','https://help.asana.com/s/article/learn-about-asana-advanced-features'),

-- monday work management
('monday-work-management','pm-task-management','supported',0.98,NULL,'https://monday.com/projects/features'),
('monday-work-management','pm-timeline-gantt','supported',0.99,NULL,'https://monday.com/projects/features'),
('monday-work-management','pm-dependencies-milestones','supported',0.98,NULL,'https://monday.com/projects/features'),
('monday-work-management','pm-project-portfolio','supported',0.95,'Portfolio features and cross-project controls vary by plan.','https://support.monday.com/hc/en-us/p/work-management'),
('monday-work-management','pm-resource-workload','supported',0.99,NULL,'https://monday.com/projects/features'),
('monday-work-management','pm-workflow-automation','supported',0.99,NULL,'https://monday.com/features/automations'),
('monday-work-management','pm-dashboards-reporting','supported',0.99,NULL,'https://monday.com/projects/features'),
('monday-work-management','pm-api-access','supported',0.99,'API access and permissions depend on account role, authentication method and product support.','https://developer.monday.com/api-reference'),

-- ClickUp
('clickup','pm-task-management','supported',0.99,NULL,'https://clickup.com/features'),
('clickup','pm-agile-sprints','supported',0.99,NULL,'https://clickup.com/features'),
('clickup','pm-goals-okrs','supported',0.98,NULL,'https://clickup.com/features'),
('clickup','pm-dependencies-milestones','supported',0.98,'ClickUp documents milestones and task relationships; exact dependency controls should be confirmed by plan.','https://clickup.com/features'),
('clickup','pm-dashboards-reporting','supported',0.98,NULL,'https://clickup.com/features'),
('clickup','pm-api-access','supported',0.99,'API endpoints and rate limits vary by Workspace plan.','https://developer.clickup.com/docs/Getting%20Started'),
('clickup','pm-sso','supported',0.99,'Google SSO is Business+; Microsoft, Okta and custom SAML are Enterprise features.','https://help.clickup.com/hc/en-us/articles/6305043992343-Intro-to-single-sign-on-SSO'),

-- Jira
('jira','pm-task-management','supported',0.99,NULL,'https://www.atlassian.com/software/jira/features'),
('jira','pm-timeline-gantt','supported',0.95,'Jira provides timeline and planning views; dedicated Gantt depth may depend on edition/apps.','https://www.atlassian.com/software/jira/features'),
('jira','pm-dependencies-milestones','supported',0.98,'Dependency planning is supported; milestone semantics may differ from traditional PPM tools.','https://www.atlassian.com/software/jira/features'),
('jira','pm-agile-sprints','supported',0.99,NULL,'https://www.atlassian.com/software/jira/features'),
('jira','pm-workflow-automation','supported',0.99,NULL,'https://www.atlassian.com/software/jira/features/automation'),
('jira','pm-dashboards-reporting','supported',0.98,NULL,'https://www.atlassian.com/software/jira/features'),
('jira','pm-forms-intake','supported',0.95,'Forms and request-style intake are available in Jira experiences; exact availability depends on configuration/product plan.','https://www.atlassian.com/software/jira/features'),
('jira','pm-api-access','supported',0.99,NULL,'https://developer.atlassian.com/server/jira/platform/jira-rest-apis-7372883/'),

-- Smartsheet
('smartsheet','pm-task-management','supported',0.95,'Task execution is modeled through sheets, rows and project templates rather than a single universal task object.','https://www.smartsheet.com/platform/features'),
('smartsheet','pm-timeline-gantt','supported',0.99,NULL,'https://www.smartsheet.com/platform/features'),
('smartsheet','pm-dependencies-milestones','supported',0.99,NULL,'https://www.smartsheet.com/platform/features'),
('smartsheet','pm-project-portfolio','supported',0.98,NULL,'https://www.smartsheet.com/platform/features'),
('smartsheet','pm-resource-workload','supported',0.98,NULL,'https://www.smartsheet.com/platform/features'),
('smartsheet','pm-workflow-automation','supported',0.99,NULL,'https://www.smartsheet.com/platform/features'),
('smartsheet','pm-dashboards-reporting','supported',0.99,NULL,'https://www.smartsheet.com/platform/features'),
('smartsheet','pm-api-access','supported',0.99,NULL,'https://developers.smartsheet.com/'),
('smartsheet','pm-sso','supported',0.98,'SAML-based SSO is listed among enterprise controls; plan requirements should be confirmed.','https://www.smartsheet.com/platform/features'),

-- Wrike
('wrike','pm-task-management','supported',0.99,NULL,'https://www.wrike.com/features/'),
('wrike','pm-timeline-gantt','supported',0.99,NULL,'https://www.wrike.com/features/'),
('wrike','pm-dependencies-milestones','supported',0.99,NULL,'https://www.wrike.com/features/'),
('wrike','pm-project-portfolio','supported',0.95,'Wrike supports program/project visibility and portfolio-style reporting; exact PPM depth depends on plan and configuration.','https://www.wrike.com/features/dashboards/'),
('wrike','pm-resource-workload','supported',0.99,NULL,'https://www.wrike.com/features/'),
('wrike','pm-workflow-automation','supported',0.99,NULL,'https://www.wrike.com/features/'),
('wrike','pm-dashboards-reporting','supported',0.99,NULL,'https://www.wrike.com/features/dashboards/'),
('wrike','pm-api-access','supported',0.95,'Wrike documents an open API; confirm endpoint and plan-specific limits for the target implementation.','https://www.wrike.com/features/'),
('wrike','pm-sso','supported',0.99,'Wrike lists enterprise SSO with providers including Microsoft Azure, Google, Okta and OneLogin.','https://www.wrike.com/features/');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM pm13_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,c.id,NULL,'not_yet_verified',0
FROM products p CROSS JOIN capabilities c JOIN modules m ON m.id=c.module_id
WHERE p.slug IN('microsoft-planner-project','asana','monday-work-management','clickup','jira','smartsheet','wrike')
AND m.category_id=@cat_id
AND NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,f.limitations
FROM pm13_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.95
FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug IN('microsoft-planner-project','asana','monday-work-management','clickup','jira','smartsheet','wrike')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

-- Integration-level API facts only where explicitly verified in this evidence batch.
INSERT INTO product_integrations(product_id,integration_id,support_status,confidence_score)
SELECT p.id,i.id,
CASE WHEN i.slug='api' AND p.slug IN('monday-work-management','clickup','jira','smartsheet','wrike') THEN 'supported'
ELSE 'not_yet_verified' END,
CASE WHEN i.slug='api' AND p.slug IN('monday-work-management','clickup','jira','smartsheet','wrike') THEN 0.95 ELSE 0 END
FROM products p JOIN integrations i
WHERE p.slug IN('microsoft-planner-project','asana','monday-work-management','clickup','jira','smartsheet','wrike')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

DROP TEMPORARY TABLE IF EXISTS pm13_facts;
COMMIT;
