-- TechSelectAI catalog expansion: Project Management, BI / Analytics, Collaboration
-- First-party vendor evidence reviewed Sep 2026. Unknown remains not_yet_verified.
SET NAMES utf8mb4;
START TRANSACTION;

-- ---------------------------------------------------------------------------
-- Categories, modules and capabilities
-- ---------------------------------------------------------------------------
INSERT INTO categories(name,slug,description,is_active) VALUES
('Project Management','project-management','Project and work management software for planning, task execution, collaboration, portfolio visibility and reporting.',1),
('Business Intelligence & Analytics','business-intelligence','Business intelligence, analytics and data visualization platforms for dashboards, analysis, governed reporting and embedded insights.',1),
('Collaboration & Workspaces','collaboration','Team collaboration and digital workspace platforms for messaging, meetings, files, shared work and knowledge.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

SET @pm_cat=(SELECT id FROM categories WHERE slug='project-management' LIMIT 1);
SET @bi_cat=(SELECT id FROM categories WHERE slug='business-intelligence' LIMIT 1);
SET @co_cat=(SELECT id FROM categories WHERE slug='collaboration' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@pm_cat,'Planning & Execution','pm-planning','Task, project, timeline and workflow execution.',1),
(@pm_cat,'Portfolio & Reporting','pm-portfolio','Portfolio visibility, dashboards, reporting and automation.',1),
(@bi_cat,'Analytics & Visualization','bi-analytics','Dashboards, reports, exploration and visualization.',1),
(@bi_cat,'Governance & Embedding','bi-enterprise','Governance, semantic models, APIs and embedded analytics.',1),
(@co_cat,'Communication','collab-communication','Team messaging, channels, meetings and calls.',1),
(@co_cat,'Workspace & Knowledge','collab-workspace','Files, shared workspaces, knowledge and collaboration.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.security,1
FROM modules m JOIN (
 SELECT 'pm-planning' module_slug,'Task & project management' name,'pm-task-project-management' slug,'Create, assign, organize and track tasks and projects.' description,0 security UNION ALL
 SELECT 'pm-planning','Timeline / Gantt planning','pm-timeline-gantt','Timeline, dependency or Gantt-style project planning.',0 UNION ALL
 SELECT 'pm-portfolio','Dashboards & reporting','pm-dashboards-reporting','Project, team or portfolio dashboards and reporting.',0 UNION ALL
 SELECT 'pm-portfolio','Workflow automation','pm-workflow-automation','Rules, automations or workflow builders for repetitive work.',0 UNION ALL
 SELECT 'bi-analytics','Interactive dashboards','bi-interactive-dashboards','Interactive dashboards and visual reports.',0 UNION ALL
 SELECT 'bi-analytics','Self-service data exploration','bi-self-service-analysis','Business-user data exploration and ad-hoc analysis.',0 UNION ALL
 SELECT 'bi-enterprise','Governed semantic / data model','bi-governed-model','Governed data or semantic model capabilities for consistent analytics.',1 UNION ALL
 SELECT 'bi-enterprise','Embedded analytics / API','bi-embedded-api','Embedding, APIs or developer capabilities for analytics experiences.',0 UNION ALL
 SELECT 'collab-communication','Team messaging & channels','collab-messaging-channels','Persistent team messaging, channels or spaces.',0 UNION ALL
 SELECT 'collab-communication','Meetings & video collaboration','collab-meetings-video','Online meetings, video calls or conferencing.',0 UNION ALL
 SELECT 'collab-workspace','File & content collaboration','collab-file-content','Shared files, documents or collaborative content.',0 UNION ALL
 SELECT 'collab-workspace','Shared workspace / knowledge','collab-workspace-knowledge','Shared workspace, knowledge base or team information organization.',0
) x ON x.module_slug=m.slug
WHERE m.category_id IN(@pm_cat,@bi_cat,@co_cat)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

-- ---------------------------------------------------------------------------
-- Vendors and products
-- ---------------------------------------------------------------------------
INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Asana','asana','https://asana.com/','Work and project management software vendor.','active'),
('monday.com','monday','https://monday.com/','Work management platform vendor.','active'),
('ClickUp','clickup','https://clickup.com/','Productivity and work management software vendor.','active'),
('Wrike','wrike','https://www.wrike.com/','Collaborative work management software vendor.','active'),
('Smartsheet','smartsheet','https://www.smartsheet.com/','Enterprise work management platform vendor.','active'),
('Zoho','zoho','https://www.zoho.com/','Business software suite vendor.','active'),
('Microsoft','microsoft','https://www.microsoft.com/','Enterprise software and cloud platform vendor.','active'),
('Salesforce','salesforce','https://www.salesforce.com/','Enterprise cloud software vendor and owner of Tableau.','active'),
('Qlik','qlik','https://www.qlik.com/','Analytics and data integration software vendor.','active'),
('Google','google','https://www.google.com/','Cloud, productivity and analytics software vendor.','active'),
('Slack','slack','https://slack.com/','Business messaging and collaboration platform vendor.','active'),
('Zoom','zoom','https://www.zoom.com/','Video communications and workplace collaboration vendor.','active'),
('Notion','notion','https://www.notion.com/','Connected workspace and knowledge collaboration vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,x.category_id,x.name,x.slug,x.description,x.url,'active',NOW()
FROM vendors v JOIN (
 SELECT 'asana' vendor_slug,@pm_cat category_id,'Asana' name,'asana' slug,'Work management platform for projects, tasks, goals, workflows and reporting.' description,'https://asana.com/product' url UNION ALL
 SELECT 'monday',@pm_cat,'monday work management','monday-work-management','Work management platform for planning, tracking, workflows, dashboards and portfolio visibility.','https://monday.com/work-management' UNION ALL
 SELECT 'clickup',@pm_cat,'ClickUp','clickup','Work management platform combining tasks, projects, docs, dashboards and automations.','https://clickup.com/features' UNION ALL
 SELECT 'wrike',@pm_cat,'Wrike','wrike','Collaborative work management platform for projects, workflows, planning and reporting.','https://www.wrike.com/features/' UNION ALL
 SELECT 'smartsheet',@pm_cat,'Smartsheet','smartsheet','Enterprise work management platform with grid, project, automation, dashboard and portfolio capabilities.','https://www.smartsheet.com/platform' UNION ALL
 SELECT 'zoho',@pm_cat,'Zoho Projects','zoho-projects','Online project management software for tasks, milestones, Gantt planning, automation and reporting.','https://www.zoho.com/projects/' UNION ALL
 SELECT 'microsoft',@bi_cat,'Microsoft Power BI','microsoft-power-bi','Microsoft business intelligence platform for dashboards, reporting, semantic models and embedded analytics.','https://www.microsoft.com/en-us/power-platform/products/power-bi' UNION ALL
 SELECT 'salesforce',@bi_cat,'Tableau','tableau','Visual analytics platform for interactive dashboards, data exploration and governed enterprise analytics.','https://www.tableau.com/products/tableau' UNION ALL
 SELECT 'qlik',@bi_cat,'Qlik Sense','qlik-sense','Analytics platform for interactive dashboards, self-service exploration and governed analytics.','https://www.qlik.com/us/products/qlik-sense' UNION ALL
 SELECT 'google',@bi_cat,'Looker','looker','Google Cloud business intelligence platform for governed semantic modeling, exploration and embedded analytics.','https://cloud.google.com/looker' UNION ALL
 SELECT 'microsoft',@co_cat,'Microsoft Teams','microsoft-teams','Microsoft collaboration platform for chat, channels, meetings, calling and shared work.','https://www.microsoft.com/en-us/microsoft-teams/group-chat-software' UNION ALL
 SELECT 'slack',@co_cat,'Slack','slack','Business messaging and collaboration platform organized around channels, messaging and connected workflows.','https://slack.com/features' UNION ALL
 SELECT 'google',@co_cat,'Google Workspace','google-workspace','Cloud productivity and collaboration suite including Gmail, Drive, Docs, Meet and shared workspaces.','https://workspace.google.com/' UNION ALL
 SELECT 'zoom',@co_cat,'Zoom Workplace','zoom-workplace','Collaboration platform combining meetings, team chat, phone and workplace productivity tools.','https://www.zoom.com/en/products/collaboration-tools/' UNION ALL
 SELECT 'notion',@co_cat,'Notion','notion','Connected workspace for docs, knowledge, projects and collaborative work.','https://www.notion.com/product'
) x ON x.vendor_slug=v.slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

-- ---------------------------------------------------------------------------
-- Official evidence
-- ---------------------------------------------------------------------------
INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',x.url,x.title,x.publisher,1,'verified','high',NOW()
FROM products p JOIN (
 SELECT 'asana' product_slug,'https://asana.com/product' url,'Asana product overview' title,'Asana' publisher UNION ALL
 SELECT 'monday-work-management','https://monday.com/work-management','monday work management','monday.com' UNION ALL
 SELECT 'clickup','https://clickup.com/features','ClickUp features','ClickUp' UNION ALL
 SELECT 'wrike','https://www.wrike.com/features/','Wrike features','Wrike' UNION ALL
 SELECT 'smartsheet','https://www.smartsheet.com/platform','Smartsheet platform','Smartsheet' UNION ALL
 SELECT 'zoho-projects','https://www.zoho.com/projects/','Zoho Projects','Zoho' UNION ALL
 SELECT 'microsoft-power-bi','https://www.microsoft.com/en-us/power-platform/products/power-bi','Microsoft Power BI','Microsoft' UNION ALL
 SELECT 'tableau','https://www.tableau.com/products/tableau','Tableau product overview','Tableau' UNION ALL
 SELECT 'qlik-sense','https://www.qlik.com/us/products/qlik-sense','Qlik Sense','Qlik' UNION ALL
 SELECT 'looker','https://cloud.google.com/looker','Looker','Google Cloud' UNION ALL
 SELECT 'microsoft-teams','https://www.microsoft.com/en-us/microsoft-teams/group-chat-software','Microsoft Teams','Microsoft' UNION ALL
 SELECT 'slack','https://slack.com/features','Slack features','Slack' UNION ALL
 SELECT 'google-workspace','https://workspace.google.com/','Google Workspace','Google' UNION ALL
 SELECT 'zoom-workplace','https://www.zoom.com/en/products/collaboration-tools/','Zoom Workplace collaboration tools','Zoom' UNION ALL
 SELECT 'notion','https://www.notion.com/product','Notion product overview','Notion'
) x ON x.product_slug=p.slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=x.url);

-- ---------------------------------------------------------------------------
-- Known facts. Anything not listed below is explicitly seeded as unknown.
-- ---------------------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS catalog69_facts;
CREATE TEMPORARY TABLE catalog69_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO catalog69_facts VALUES
-- Project management
('asana','pm-task-project-management','supported',0.99,NULL,'https://asana.com/product'),
('asana','pm-timeline-gantt','supported',0.95,'Timeline and dependency features can vary by plan.','https://asana.com/product'),
('asana','pm-dashboards-reporting','supported',0.95,NULL,'https://asana.com/product'),
('asana','pm-workflow-automation','supported',0.95,'Automation depth varies by plan and configuration.','https://asana.com/product'),
('monday-work-management','pm-task-project-management','supported',0.99,NULL,'https://monday.com/work-management'),
('monday-work-management','pm-timeline-gantt','supported',0.95,NULL,'https://monday.com/work-management'),
('monday-work-management','pm-dashboards-reporting','supported',0.98,NULL,'https://monday.com/work-management'),
('monday-work-management','pm-workflow-automation','supported',0.98,NULL,'https://monday.com/work-management'),
('clickup','pm-task-project-management','supported',0.99,NULL,'https://clickup.com/features'),
('clickup','pm-timeline-gantt','supported',0.95,NULL,'https://clickup.com/features'),
('clickup','pm-dashboards-reporting','supported',0.95,NULL,'https://clickup.com/features'),
('clickup','pm-workflow-automation','supported',0.95,NULL,'https://clickup.com/features'),
('wrike','pm-task-project-management','supported',0.99,NULL,'https://www.wrike.com/features/'),
('wrike','pm-timeline-gantt','supported',0.95,NULL,'https://www.wrike.com/features/'),
('wrike','pm-dashboards-reporting','supported',0.95,NULL,'https://www.wrike.com/features/'),
('smartsheet','pm-task-project-management','supported',0.98,NULL,'https://www.smartsheet.com/platform'),
('smartsheet','pm-timeline-gantt','supported',0.95,NULL,'https://www.smartsheet.com/platform'),
('smartsheet','pm-dashboards-reporting','supported',0.98,NULL,'https://www.smartsheet.com/platform'),
('smartsheet','pm-workflow-automation','supported',0.98,NULL,'https://www.smartsheet.com/platform'),
('zoho-projects','pm-task-project-management','supported',0.99,NULL,'https://www.zoho.com/projects/'),
('zoho-projects','pm-timeline-gantt','supported',0.98,NULL,'https://www.zoho.com/projects/'),
('zoho-projects','pm-dashboards-reporting','supported',0.92,NULL,'https://www.zoho.com/projects/'),
('zoho-projects','pm-workflow-automation','supported',0.92,'Automation capabilities can vary by edition.','https://www.zoho.com/projects/'),
-- BI
('microsoft-power-bi','bi-interactive-dashboards','supported',0.99,NULL,'https://www.microsoft.com/en-us/power-platform/products/power-bi'),
('microsoft-power-bi','bi-self-service-analysis','supported',0.99,NULL,'https://www.microsoft.com/en-us/power-platform/products/power-bi'),
('microsoft-power-bi','bi-governed-model','supported',0.95,'Governance depth depends on Power BI / Fabric licensing and tenant configuration.','https://www.microsoft.com/en-us/power-platform/products/power-bi'),
('microsoft-power-bi','bi-embedded-api','supported',0.95,'Embedded capabilities require appropriate licensing and implementation.','https://www.microsoft.com/en-us/power-platform/products/power-bi'),
('tableau','bi-interactive-dashboards','supported',0.99,NULL,'https://www.tableau.com/products/tableau'),
('tableau','bi-self-service-analysis','supported',0.99,NULL,'https://www.tableau.com/products/tableau'),
('tableau','bi-governed-model','supported',0.92,'Governance capabilities depend on Tableau deployment and licensed services.','https://www.tableau.com/products/tableau'),
('qlik-sense','bi-interactive-dashboards','supported',0.99,NULL,'https://www.qlik.com/us/products/qlik-sense'),
('qlik-sense','bi-self-service-analysis','supported',0.99,NULL,'https://www.qlik.com/us/products/qlik-sense'),
('qlik-sense','bi-governed-model','supported',0.92,NULL,'https://www.qlik.com/us/products/qlik-sense'),
('looker','bi-interactive-dashboards','supported',0.98,NULL,'https://cloud.google.com/looker'),
('looker','bi-self-service-analysis','supported',0.95,NULL,'https://cloud.google.com/looker'),
('looker','bi-governed-model','supported',0.99,'LookML semantic modeling requires implementation and governance design.','https://cloud.google.com/looker'),
('looker','bi-embedded-api','supported',0.98,NULL,'https://cloud.google.com/looker'),
-- Collaboration
('microsoft-teams','collab-messaging-channels','supported',0.99,NULL,'https://www.microsoft.com/en-us/microsoft-teams/group-chat-software'),
('microsoft-teams','collab-meetings-video','supported',0.99,NULL,'https://www.microsoft.com/en-us/microsoft-teams/group-chat-software'),
('microsoft-teams','collab-file-content','supported',0.95,'File collaboration relies on Microsoft 365 services such as SharePoint and OneDrive.','https://www.microsoft.com/en-us/microsoft-teams/group-chat-software'),
('slack','collab-messaging-channels','supported',0.99,NULL,'https://slack.com/features'),
('slack','collab-workspace-knowledge','supported',0.92,'Knowledge and canvas capabilities depend on plan and configuration.','https://slack.com/features'),
('google-workspace','collab-meetings-video','supported',0.99,NULL,'https://workspace.google.com/'),
('google-workspace','collab-file-content','supported',0.99,NULL,'https://workspace.google.com/'),
('google-workspace','collab-workspace-knowledge','supported',0.95,'Workspace collaboration is distributed across Drive, Docs, Sites and related apps.','https://workspace.google.com/'),
('zoom-workplace','collab-messaging-channels','supported',0.95,NULL,'https://www.zoom.com/en/products/collaboration-tools/'),
('zoom-workplace','collab-meetings-video','supported',0.99,NULL,'https://www.zoom.com/en/products/collaboration-tools/'),
('zoom-workplace','collab-file-content','supported',0.90,'Content collaboration capabilities vary across Zoom Workplace components and plans.','https://www.zoom.com/en/products/collaboration-tools/'),
('notion','collab-file-content','supported',0.95,NULL,'https://www.notion.com/product'),
('notion','collab-workspace-knowledge','supported',0.99,NULL,'https://www.notion.com/product');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM catalog69_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,f.limitations
FROM catalog69_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Explicit unknowns ensure absence of evidence never becomes "unsupported".
INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,c.id,NULL,'not_yet_verified',0
FROM products p JOIN capabilities c JOIN modules m ON m.id=c.module_id
WHERE ((p.category_id=@pm_cat AND m.category_id=@pm_cat) OR (p.category_id=@bi_cat AND m.category_id=@bi_cat) OR (p.category_id=@co_cat AND m.category_id=@co_cat))
AND p.slug IN('asana','monday-work-management','clickup','wrike','smartsheet','zoho-projects','microsoft-power-bi','tableau','qlik-sense','looker','microsoft-teams','slack','google-workspace','zoom-workplace','notion')
AND NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL);

-- All products in this batch have an official cloud/SaaS offering.
INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.95
FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug IN('asana','monday-work-management','clickup','wrike','smartsheet','zoho-projects','microsoft-power-bi','tableau','qlik-sense','looker','microsoft-teams','slack','google-workspace','zoom-workplace','notion')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

-- Seed only integrations that are directly obvious from the vendor ecosystem; leave all others unknown.
INSERT INTO product_integrations(product_id,integration_id,support_status,confidence_score)
SELECT p.id,i.id,'supported',0.95
FROM products p JOIN integrations i
WHERE (p.slug='microsoft-teams' AND i.slug='microsoft-365')
   OR (p.slug='microsoft-power-bi' AND i.slug='microsoft-365')
   OR (p.slug='google-workspace' AND i.slug='google-workspace')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

COMMIT;
