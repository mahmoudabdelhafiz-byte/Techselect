-- TechSelectAI Digital Permit-to-Work & Control of Work catalog expansion.
-- Adds one canonical specialized CoW/PTW category and five evidence-backed current products.
-- Official first-party evidence reviewed Sep 2026. Presence is not an endorsement.
-- Unknown != Unsupported. No Fit Score, recommendation ranking, review score, follower/community popularity or commercial placement logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('Digital Permit-to-Work & Control of Work Software','digital-permit-control-of-work','Specialized software for planning, authorizing, coordinating and monitoring hazardous work through digital permits, risk assessments, isolations, SIMOPS controls, field execution, work-area visibility, handover and audit-ready work-control records.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @cow_cat=(SELECT id FROM categories WHERE slug='digital-permit-control-of-work' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@cow_cat,'Safe Work Authorization & Risk Control','cow-safe-work-authorization','Digital permit lifecycle, job risk/JSA, isolations/LOTO, worker authorization and safe execution of hazardous work.',1),
(@cow_cat,'Work Coordination, Visibility & Integration','cow-coordination-visibility','SIMOPS and conflict management, mobile field execution, work-area visualization, handover, enterprise integration and permit analytics.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.sec,1
FROM modules m JOIN (
 SELECT 'cow-safe-work-authorization' module_slug,'Digital permit lifecycle & authorization' name,'cow-permit-lifecycle' slug,'Request, review, approve, issue, extend, suspend, hand back, cancel and close hazardous-work permits with controlled authorization and traceable status.' description,0 sec UNION ALL
 SELECT 'cow-safe-work-authorization','Hazard identification, JSA/JHA & risk assessment','cow-risk-jsa','Identify hazards and controls, attach or execute task/job safety assessments, risk assessments, method statements or pre-job safety checks before work authorization.' description,0 UNION ALL
 SELECT 'cow-safe-work-authorization','Isolation & lockout/tagout coordination','cow-isolation-loto','Plan, authorize, track and release energy or process isolations, LOTO points, certificates and dependencies linked to safe-work permits where explicitly supported.',0 UNION ALL
 SELECT 'cow-safe-work-authorization','Worker/contractor competency & authorization checks','cow-worker-authorization','Verify or reference worker/contractor qualifications, training, certification, access status or responsibility before hazardous work is authorized where explicitly supported.',0 UNION ALL
 SELECT 'cow-coordination-visibility','SIMOPS, overlapping-work & conflict detection','cow-simops-conflict','Identify simultaneous or overlapping work, spatial/operational conflicts, incompatible permits or elevated combined risk before or during execution.',0 UNION ALL
 SELECT 'cow-coordination-visibility','Mobile & field permit execution','cow-mobile-field','Execute permit, checklist, risk-control or field-verification steps on mobile or portable devices at the job site where explicitly documented.',0 UNION ALL
 SELECT 'cow-coordination-visibility','Site, plot-plan & work-location visualization','cow-site-visualization','Visualize permit locations, work areas, hazards, isolations or concurrent jobs using maps, plot plans, diagrams, P&IDs, 3D models or comparable visual context.',0 UNION ALL
 SELECT 'cow-coordination-visibility','Shift handover & work coordination','cow-handover-coordination','Carry forward permit/work status between shifts or coordinate planned and active hazardous work through handover-oriented workflows where supported.',0 UNION ALL
 SELECT 'cow-coordination-visibility','EAM/CMMS/work-order integration','cow-eam-workorder-integration','Integrate permits and control-of-work workflows with EAM, CMMS, maintenance work orders or other operational systems through supported interfaces.',0 UNION ALL
 SELECT 'cow-coordination-visibility','Audit trail, dashboards & permit analytics','cow-audit-analytics','Maintain auditable permit/work histories and provide dashboards, reports, trends, status views or performance analytics for hazardous-work control.',0
) x ON x.module_slug=m.slug
WHERE m.category_id=@cow_cat
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Wolters Kluwer','wolters-kluwer','https://www.wolterskluwer.com/','Enterprise information and software provider and owner of Enablon.','active'),
('Sphera','sphera','https://sphera.com/','Process safety, operational risk, EHS and sustainability software vendor.','active'),
('Hexagon','hexagon','https://hexagon.com/','Industrial asset lifecycle, operations and engineering software vendor.','active'),
('Intelex','intelex','https://www.intelex.com/','Enterprise EHS, quality, ESG and operational-risk software vendor.','active'),
('EcoOnline','ecoonline','https://www.ecoonline.com/','EHS, chemical safety and control-of-work software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat134_products;
CREATE TEMPORARY TABLE cat134_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO cat134_products VALUES
('wolters-kluwer','digital-permit-control-of-work','Enablon Control of Work','enablon-control-of-work','Industrial control-of-work solution connecting digital permit-to-work, risk assessment/JHA, isolation management, SIMOPS, mobile field execution, work-area visibility and coordinated hazardous-work operations.','https://www.wolterskluwer.com/en/solutions/enablon/control-of-work-software'),
('sphera','digital-permit-control-of-work','Sphera Control of Work','sphera-control-of-work','Integrated control-of-work suite combining permit-to-work, risk/JHA, isolation management, SIMOPS and job-conflict visualization with mobile execution, operational dashboards and connected enterprise workflows.','https://sphera.com/solutions/process-safety-management/control-of-work/'),
('hexagon','digital-permit-control-of-work','j5 Control of Work','hexagon-j5-control-of-work','Industrial permit and control-of-work application for configurable permit workflows, isolations, certificates, risk management, mobile execution, visual work planning and CMMS/EAM-connected operations.','https://aliresources.hexagon.com/operations-maintenance/j5-control-of-work-overview'),
('intelex','digital-permit-control-of-work','Intelex Permit to Work','intelex-permit-to-work','Configurable permit-to-work application for hazardous-work request, review and authorization with hazard/control data, JSA integration, permit dashboards and platform-level mobile/offline and integration capabilities.','https://www.intelex.com/products/applications/permit-work-software/'),
('ecoonline','digital-permit-control-of-work','EcoOnline Permit to Work','ecoonline-permit-to-work','Digital permit-to-work solution for hazardous-work templates, approvals, handback, risk documentation, energy-isolation work types, contractor participation and real-time permit visibility within EcoOnline Control of Work.','https://www.ecoonline.com/ehs-software/control-of-work/permit-to-work-software/');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat134_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS cat134_sources;
CREATE TEMPORARY TABLE cat134_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat134_sources VALUES
('enablon-control-of-work','https://www.wolterskluwer.com/en/solutions/enablon/control-of-work-software','Enablon Control of Work','Wolters Kluwer'),
('enablon-control-of-work','https://www.wolterskluwer.com/en/solutions/enablon/process-safety-software','Enablon Process Safety Management','Wolters Kluwer'),
('sphera-control-of-work','https://sphera.com/solutions/process-safety-management/control-of-work/','Sphera Control of Work','Sphera'),
('sphera-control-of-work','https://sphera.com/solutions/process-safety-management/control-of-work/permit-to-work/','Sphera Permit to Work','Sphera'),
('sphera-control-of-work','https://sphera.com/solutions/process-safety-management/control-of-work/isolation-management/','Sphera Isolation Management','Sphera'),
('hexagon-j5-control-of-work','https://aliresources.hexagon.com/operations-maintenance/j5-control-of-work-overview','j5 Control of Work Overview','Hexagon'),
('hexagon-j5-control-of-work','https://aliresources.hexagon.com/operations-maintenance/configurable-control-of-work-2','Configurable j5 Control of Work','Hexagon'),
('hexagon-j5-control-of-work','https://aliresources.hexagon.com/articles-blogs/integrated-transparent-efficient-approach-to-operations-management','Integrated Operations Management with j5','Hexagon'),
('intelex-permit-to-work','https://www.intelex.com/products/applications/permit-work-software/','Intelex Permit to Work','Intelex'),
('intelex-permit-to-work','https://www.intelex.com/products/health-safety/applications/','Intelex Health and Safety Applications','Intelex'),
('ecoonline-permit-to-work','https://www.ecoonline.com/ehs-software/control-of-work/permit-to-work-software/','EcoOnline Permit to Work','EcoOnline'),
('ecoonline-permit-to-work','https://www.ecoonline.com/ehs-software/control-of-work/','EcoOnline Control of Work','EcoOnline'),
('ecoonline-permit-to-work','https://www.ecoonline.com/guides/permit-to-work-management-system/','EcoOnline Permit to Work Management Guide','EcoOnline'),
('ecoonline-permit-to-work','https://www.ecoonline.com/ehs-software/control-of-work/contractor-management-software/','EcoOnline Contractor Management','EcoOnline');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM cat134_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS cat134_facts;
CREATE TEMPORARY TABLE cat134_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat134_facts VALUES
-- Enablon Control of Work
('enablon-control-of-work','cow-permit-lifecycle','supported',0.990,'Enablon explicitly provides digital Permit to Work for planning, authorization and execution of high-risk work, including AI-assisted permit drafting and permit status visibility.','https://www.wolterskluwer.com/en/solutions/enablon/control-of-work-software'),
('enablon-control-of-work','cow-risk-jsa','supported',0.990,'Control of Work links permits with risk assessments and job hazard analyses so required controls are established before work begins.','https://www.wolterskluwer.com/en/solutions/enablon/control-of-work-software'),
('enablon-control-of-work','cow-isolation-loto','supported',0.990,'Enablon explicitly connects isolation management with permit-to-work and work-control workflows.','https://www.wolterskluwer.com/en/solutions/enablon/control-of-work-software'),
('enablon-control-of-work','cow-worker-authorization','supported',0.980,'Enablon Control of Work can ensure workers have necessary skills, qualifications and training for the task before execution.','https://www.wolterskluwer.com/en/solutions/enablon/control-of-work-software'),
('enablon-control-of-work','cow-simops-conflict','supported',0.990,'Enablon explicitly provides real-time SIMOPS coordination and warnings for interacting hazardous activities.','https://www.wolterskluwer.com/en/solutions/enablon/control-of-work-software'),
('enablon-control-of-work','cow-mobile-field','supported',0.990,'Enablon describes a fully mobile Control of Work experience for field execution of high-risk work.','https://www.wolterskluwer.com/en/solutions/enablon/control-of-work-software'),
('enablon-control-of-work','cow-site-visualization','supported',0.980,'Permit to Work integrates risk assessments with interactive site diagrams and visual work context for hazardous activities.','https://www.wolterskluwer.com/en/solutions/enablon/control-of-work-software'),
('enablon-control-of-work','cow-handover-coordination','partially_supported',0.970,'Enablon Control of Work includes shift-management and shutdown/turnaround coordination in the broader CoW solution, but these are specialized applications rather than assumed base permit entitlement.','https://www.wolterskluwer.com/en/solutions/enablon/control-of-work-software'),
('enablon-control-of-work','cow-audit-analytics','supported',0.980,'Enablon documents traceable risk/permit histories, operational visibility and management feedback across Control of Work.','https://www.wolterskluwer.com/en/solutions/enablon/control-of-work-software'),

-- Sphera Control of Work
('sphera-control-of-work','cow-permit-lifecycle','supported',0.990,'Sphera Permit to Work standardizes digital work permission, permit status, authorization and hazardous-work execution.','https://sphera.com/solutions/process-safety-management/control-of-work/permit-to-work/'),
('sphera-control-of-work','cow-risk-jsa','supported',0.990,'Sphera Control of Work integrates risk assessments, JHAs, hazards and permit workflows.','https://sphera.com/solutions/process-safety-management/control-of-work/'),
('sphera-control-of-work','cow-isolation-loto','supported',0.990,'Sphera Isolation Management supports multiphase isolation plans, isolation-point dependencies, work authorizations and permit-linked isolation workflows.','https://sphera.com/solutions/process-safety-management/control-of-work/isolation-management/'),
('sphera-control-of-work','cow-simops-conflict','supported',0.990,'Sphera explicitly manages SIMOPS and detects work conflicts through real-time work and risk visibility.','https://sphera.com/solutions/process-safety-management/control-of-work/'),
('sphera-control-of-work','cow-mobile-field','supported',0.990,'Sphera documents powerful mobile capabilities supporting Control of Work at the job site.','https://sphera.com/solutions/process-safety-management/control-of-work/'),
('sphera-control-of-work','cow-site-visualization','partially_supported',0.990,'Control of Work includes job-conflict visualization and offers Interactive P&ID as a dedicated suite module; full diagram/P&ID entitlement is therefore not assumed in every CoW package.','https://sphera.com/solutions/process-safety-management/control-of-work/'),
('sphera-control-of-work','cow-handover-coordination','partially_supported',0.990,'Operational Logbook and Shift Handover is a dedicated module inside the broader Control of Work suite rather than universal Permit to Work entitlement.','https://sphera.com/solutions/process-safety-management/control-of-work/'),
('sphera-control-of-work','cow-eam-workorder-integration','supported',0.980,'Sphera documents integration with ERP/work-order processes, including automatic generation of permits from work orders.','https://sphera.com/solutions/process-safety-management/control-of-work/'),
('sphera-control-of-work','cow-audit-analytics','supported',0.990,'Permit to Work maintains permit/isolation/hazard histories and provides dashboards, reporting, compliance and audit-readiness visibility.','https://sphera.com/solutions/process-safety-management/control-of-work/permit-to-work/'),

-- Hexagon j5 Control of Work
('hexagon-j5-control-of-work','cow-permit-lifecycle','supported',0.990,'j5 Control of Work provides configurable workflows for preparing, reviewing, approving, issuing and managing safety-critical permits.','https://aliresources.hexagon.com/operations-maintenance/configurable-control-of-work-2'),
('hexagon-j5-control-of-work','cow-risk-jsa','supported',0.980,'Hexagon documents j5 Control of Work functionality for risk management alongside permits, certificates and isolation workflows.','https://aliresources.hexagon.com/articles-blogs/integrated-transparent-efficient-approach-to-operations-management'),
('hexagon-j5-control-of-work','cow-isolation-loto','supported',0.990,'j5 Control of Work explicitly handles isolations and certificates alongside permit workflows.','https://aliresources.hexagon.com/articles-blogs/integrated-transparent-efficient-approach-to-operations-management'),
('hexagon-j5-control-of-work','cow-mobile-field','supported',0.980,'j5 Control of Work supports preparation and execution using desktop browsers and mobile computers; exact native mobile operating-system support is not inferred.','https://aliresources.hexagon.com/operations-maintenance/configurable-control-of-work-2'),
('hexagon-j5-control-of-work','cow-site-visualization','supported',0.980,'Hexagon documents visual work planning using 3D models and laser scans to improve Control of Work planning and site context.','https://aliresources.hexagon.com/operations-maintenance/configurable-control-of-work-2'),
('hexagon-j5-control-of-work','cow-eam-workorder-integration','supported',0.990,'j5 Control of Work can connect to CMMS/EAM software to improve visibility between permit and maintenance workflows.','https://aliresources.hexagon.com/operations-maintenance/configurable-control-of-work-2'),
('hexagon-j5-control-of-work','cow-audit-analytics','supported',0.980,'j5 provides dashboards, reports, views and digital workflows for permit status, operational visibility and auditability.','https://aliresources.hexagon.com/operations-maintenance/configurable-control-of-work-2'),

-- Intelex Permit to Work
('intelex-permit-to-work','cow-permit-lifecycle','supported',0.990,'Intelex manages permit request, review, authorization, status, start/end dates and reporting for hazardous work.','https://www.intelex.com/products/applications/permit-work-software/'),
('intelex-permit-to-work','cow-risk-jsa','supported',0.990,'Intelex Permit to Work integrates completed risk assessments from Job Safety Analysis and records hazards, controls, PPE and PSSR information.','https://www.intelex.com/products/applications/permit-work-software/'),
('intelex-permit-to-work','cow-isolation-loto','partially_supported',0.970,'LOTO can be configured as a hazardous work type in permit workflows, but a dedicated isolation-point planning and dependency-management engine is not inferred.','https://www.intelex.com/products/applications/permit-work-software/'),
('intelex-permit-to-work','cow-simops-conflict','partially_supported',0.970,'Intelex dashboards expose overlapping work in the same area, but automated SIMOPS incompatibility/risk-conflict logic is not inferred from the reviewed evidence.','https://www.intelex.com/products/applications/permit-work-software/'),
('intelex-permit-to-work','cow-mobile-field','partially_supported',0.970,'The Intelex platform provides mobile and offline capability, but the reviewed Permit to Work page does not establish that every permit workflow/configuration is available identically offline.','https://www.intelex.com/products/health-safety/applications/'),
('intelex-permit-to-work','cow-eam-workorder-integration','partially_supported',0.950,'The Intelex platform provides REST API access, but direct prebuilt CMMS/EAM work-order integration for Permit to Work is not established by the reviewed product evidence.','https://www.intelex.com/products/health-safety/applications/'),
('intelex-permit-to-work','cow-audit-analytics','supported',0.990,'Intelex provides permit dashboards, visualizations, status views, reporting, platform audit trail and business intelligence.','https://www.intelex.com/products/applications/permit-work-software/'),

-- EcoOnline Permit to Work
('ecoonline-permit-to-work','cow-permit-lifecycle','supported',0.990,'EcoOnline digitally creates, issues, reviews, approves, extends, hands back, cancels and tracks permits for hazardous work.','https://www.ecoonline.com/ehs-software/control-of-work/permit-to-work-software/'),
('ecoonline-permit-to-work','cow-risk-jsa','partially_supported',0.980,'Permits can attach risk assessments and method statements and link to broader EHS risk workflows, but a dedicated in-permit JSA engine is not inferred.','https://www.ecoonline.com/ehs-software/control-of-work/permit-to-work-software/'),
('ecoonline-permit-to-work','cow-isolation-loto','partially_supported',0.980,'EcoOnline includes lockout/tagout and energy-isolation permit templates, but dedicated isolation-point dependency planning is not inferred from the reviewed evidence.','https://www.ecoonline.com/ehs-software/control-of-work/permit-to-work-software/'),
('ecoonline-permit-to-work','cow-worker-authorization','partially_supported',0.980,'EcoOnline Control of Work can connect contractor credentials, qualifications and access/compliance status to permit processes, but this depends on companion contractor/access modules.','https://www.ecoonline.com/ehs-software/control-of-work/'),
('ecoonline-permit-to-work','cow-simops-conflict','partially_supported',0.960,'EcoOnline documents multi-permit visibility and guidance for flagging simultaneous-work conflicts, but a universal automated SIMOPS engine is not inferred from the core permit product.','https://www.ecoonline.com/guides/permit-to-work-management-system/'),
('ecoonline-permit-to-work','cow-mobile-field','supported',0.980,'EcoOnline Control of Work provides frictionless mobile access for contractors and frontline participation in work-control processes.','https://www.ecoonline.com/ehs-software/control-of-work/'),
('ecoonline-permit-to-work','cow-handover-coordination','partially_supported',0.970,'EcoOnline Permit to Work explicitly supports permit handback and improved handover, but a dedicated shift-handover/logbook application is not inferred.','https://www.ecoonline.com/ehs-software/control-of-work/permit-to-work-software/'),
('ecoonline-permit-to-work','cow-audit-analytics','supported',0.990,'EcoOnline provides permit tracking, Insights dashboards, live reporting and centralized documentation for audit and compliance visibility.','https://www.ecoonline.com/ehs-software/control-of-work/permit-to-work-software/');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat134_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat134_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party vendor documentation supporting this capability.'
FROM cat134_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Deployment remains not_yet_verified for all five products in this batch.
-- SaaS-enabled, web-based, mobile-enabled or marketplace availability does not by itself define this catalog's commercial deployment model.

-- Platform-specific mobile access remains unknown even where generic mobile/field capability is documented.
INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000
FROM products p CROSS JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') x
WHERE p.slug IN('enablon-control-of-work','sphera-control-of-work','hexagon-j5-control-of-work','intelex-permit-to-work','ecoonline-permit-to-work')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

COMMIT;
