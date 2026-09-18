-- TechSelectAI Marine Planned Maintenance & Technical Management Systems catalog expansion.
-- Adds one canonical marine PMS / technical-management category and five evidence-backed current products.
-- Official first-party evidence reviewed Sep 2026. Presence is not an endorsement.
-- Unknown != Unsupported. No Fit Score, recommendation ranking, review score, follower/community popularity or commercial placement logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('Marine Planned Maintenance & Technical Management Systems','marine-planned-maintenance-technical-management','Specialized software for shipboard and shoreside technical management, including planned and corrective maintenance, equipment hierarchies, defects, spares, procurement links, dry-dock projects, compliance, analytics and fleet-wide maintenance governance.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @marine_pms_cat=(SELECT id FROM categories WHERE slug='marine-planned-maintenance-technical-management' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@marine_pms_cat,'Maintenance & Asset Control','marine-pms-maintenance-assets','Planned and corrective maintenance, equipment/component structures, condition-based maintenance and defect workflows.',1),
(@marine_pms_cat,'Fleet Support, Compliance & Integration','marine-pms-fleet-support','Spares, procurement, dry-docking, class/compliance, fleet analytics and connected ship-shore technical workflows.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.sec,1
FROM modules m JOIN (
 SELECT 'marine-pms-maintenance-assets' module_slug,'Planned maintenance scheduling & execution' name,'marine-pms-scheduling-execution' slug,'Plan, schedule, execute and document recurring maintenance jobs using calendar, counter, running-hour or other supported maintenance triggers.' description,0 sec UNION ALL
 SELECT 'marine-pms-maintenance-assets','Equipment registry & component hierarchy','marine-pms-equipment-hierarchy','Maintain vessel equipment, machinery and component structures with associated technical records, job history, documents and lifecycle data.',0 UNION ALL
 SELECT 'marine-pms-maintenance-assets','Defect & corrective maintenance management','marine-pms-defect-corrective','Record defects, breakdowns or non-routine work and convert or link them to corrective maintenance, follow-up and history.',0 UNION ALL
 SELECT 'marine-pms-maintenance-assets','Condition-based / predictive maintenance','marine-pms-condition-predictive','Use condition data, measurements, counters, analytics or predictive methods to trigger or improve maintenance planning beyond fixed calendar intervals.',0 UNION ALL
 SELECT 'marine-pms-fleet-support','Spare parts & inventory linkage','marine-pms-spares-inventory','Link maintenance jobs and equipment to spare parts, stock, consumption, reorder information or vessel/fleet inventory.',0 UNION ALL
 SELECT 'marine-pms-fleet-support','Procurement & requisition integration','marine-pms-procurement-integration','Create, connect or track requisitions, purchasing and supplier workflows from maintenance and spare-parts requirements.',0 UNION ALL
 SELECT 'marine-pms-fleet-support','Dry-dock & technical project management','marine-pms-drydock-projects','Plan and control dry-docking, repair, retrofit or other technical projects including work scopes, tenders, schedules, costs or progress where supported.',0 UNION ALL
 SELECT 'marine-pms-fleet-support','Class, survey & maintenance compliance','marine-pms-class-compliance','Support class-related maintenance, surveys, criticality, certificates, audit evidence or other technical compliance requirements.',0 UNION ALL
 SELECT 'marine-pms-fleet-support','Fleet dashboards, KPIs & maintenance analytics','marine-pms-analytics-kpis','Provide fleet-wide maintenance visibility, overdue status, downtime, trends, KPIs, reporting or decision-support analytics.',0 UNION ALL
 SELECT 'marine-pms-fleet-support','Ship-shore synchronization & system integration','marine-pms-shipshore-integration','Synchronize technical data between vessel and office and integrate with adjacent maritime, ERP, procurement, analytics or equipment-data systems.',0
) x ON x.module_slug=m.slug
WHERE m.category_id=@marine_pms_cat
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('DNV','dnv','https://www.dnv.com/','Classification, assurance and maritime software provider.','active'),
('BASS Software','bass-software','https://www.bassnet.no/','Maritime fleet-management and ship-management software vendor.','active'),
('MariApps Marine Solutions','mariapps','https://www.mariapps.com/','Maritime ERP, ship-management and fleet digitalization software vendor.','active'),
('SERTICA','sertica','https://www.sertica.com/','Maritime maintenance, procurement, compliance, performance and fleet-management software provider.','active'),
('Hanseaticsoft','hanseaticsoft','https://hanseaticsoft.com/','Cloud-based ship-management software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat120_products;
CREATE TEMPORARY TABLE cat120_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO cat120_products VALUES
('dnv','marine-planned-maintenance-technical-management','DNV ShipManager Technical','dnv-shipmanager-technical','Technical ship-management and planned-maintenance system for planned/unplanned maintenance, equipment and lifecycle data, defects, spares, class-related workflows, analytics and connected ShipManager modules.','https://www.dnv.com/services/planned-maintenance-system-for-technical-ship-management-shipmanager-technical-1509/'),
('bass-software','marine-planned-maintenance-technical-management','BASSnet Neo Maintenance','bassnet-neo-maintenance','Cloud-native maritime maintenance and fleet-management solution covering planned maintenance, equipment hierarchy, defects, materials, procurement-linked workflows, projects/dry-docking, compliance and fleet analytics.','https://www.bassnet.no/solution/technical-planned-maintenance-system/'),
('mariapps','marine-planned-maintenance-technical-management','smartPAL Maintenance','smartpal-maintenance','Maritime planned-maintenance system within the smartPAL technical suite for equipment and spare tracking, job planning, predictive/preventive maintenance, compliance, dry-dock linkage, analytics and connected ship-management workflows.','https://www.mariapps.com/cn/smartpal/planned-maintenance-system/'),
('sertica','marine-planned-maintenance-technical-management','SERTICA Maintenance','sertica-maintenance','Maritime CMMS and ship-maintenance system for recurring and corrective maintenance, component-based asset control, inventory linkage, procurement, compliance, analytics and synchronized fleet-wide execution.','https://www.sertica.com/maintenance/'),
('hanseaticsoft','marine-planned-maintenance-technical-management','Cloud Fleet Manager Maintenance','cloud-fleet-manager-maintenance','Cloud-based planned-maintenance module for fleet-wide job planning, equipment and spares, overdue/critical maintenance visibility, purchase integration, ship-shore synchronization and web-based fleet management.','https://hanseaticsoft.com/cloud-maintenance/maintenance/');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat120_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS cat120_sources;
CREATE TEMPORARY TABLE cat120_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat120_sources VALUES
('dnv-shipmanager-technical','https://www.dnv.com/services/planned-maintenance-system-for-technical-ship-management-shipmanager-technical-1509/','DNV ShipManager Technical','DNV'),
('bassnet-neo-maintenance','https://www.bassnet.no/','BASSnet Neo','BASS Software'),
('bassnet-neo-maintenance','https://www.bassnet.no/solution/technical-planned-maintenance-system/','BASSnet Technical Planned Maintenance System','BASS Software'),
('bassnet-neo-maintenance','https://www.bassnet.no/solution/fleet-management/','BASSnet Fleet Management','BASS Software'),
('bassnet-neo-maintenance','https://www.bassnet.no/service/software-as-a-service/','BASSnet Software as a Service','BASS Software'),
('bassnet-neo-maintenance','https://www.bassnet.no/insight/bassnet-neo-launching-a-unified-fully-managed-maritime-saas-solution/','BASSnet Neo Cloud-native SaaS','BASS Software'),
('smartpal-maintenance','https://www.mariapps.com/smartpal/','smartPAL Ship Management Software','MariApps Marine Solutions'),
('smartpal-maintenance','https://www.mariapps.com/cn/smartpal/planned-maintenance-system/','smartPAL Planned Maintenance System','MariApps Marine Solutions'),
('smartpal-maintenance','https://www.mariapps.com/smartpal/data-library/','smartPAL Data Library','MariApps Marine Solutions'),
('smartpal-maintenance','https://www.mariapps.com/smartpal/drydock-software/','smartPAL Drydock Software','MariApps Marine Solutions'),
('sertica-maintenance','https://www.sertica.com/maintenance/','SERTICA Maintenance','SERTICA'),
('sertica-maintenance','https://www.sertica.com/products/','SERTICA Products','SERTICA'),
('sertica-maintenance','https://www.sertica.com/modules/','SERTICA Modules','SERTICA'),
('sertica-maintenance','https://www.sertica.com/ship-management-software/','SERTICA Ship Management Software','SERTICA'),
('cloud-fleet-manager-maintenance','https://hanseaticsoft.com/','Cloud Fleet Manager','Hanseaticsoft'),
('cloud-fleet-manager-maintenance','https://hanseaticsoft.com/cloud-maintenance/maintenance/','CFM Maintenance','Hanseaticsoft'),
('cloud-fleet-manager-maintenance','https://hanseaticsoft.com/new-features/cfm-updates-august-2026/','CFM Updates August 2026','Hanseaticsoft'),
('cloud-fleet-manager-maintenance','https://hanseaticsoft.com/new-features/cfm-updates-june-2026/','CFM Updates June 2026','Hanseaticsoft'),
('cloud-fleet-manager-maintenance','https://hanseaticsoft.com/new-features/cfm-updates-january-2026/','CFM Updates January 2026','Hanseaticsoft'),
('cloud-fleet-manager-maintenance','https://hanseaticsoft.com/new-features/cfm-updates-february-2026/','CFM Updates February 2026','Hanseaticsoft');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM cat120_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS cat120_facts;
CREATE TEMPORARY TABLE cat120_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat120_facts VALUES
-- DNV ShipManager Technical
('dnv-shipmanager-technical','marine-pms-scheduling-execution','supported',0.990,'DNV documents planned and unplanned maintenance with calendar-, counter- and condition-based scheduling and onboard/office task lists.','https://www.dnv.com/services/planned-maintenance-system-for-technical-ship-management-shipmanager-technical-1509/'),
('dnv-shipmanager-technical','marine-pms-equipment-hierarchy','supported',0.990,'ShipManager Technical centrally manages fleet-wide equipment, lifecycle records and technical asset/data information.','https://www.dnv.com/services/planned-maintenance-system-for-technical-ship-management-shipmanager-technical-1509/'),
('dnv-shipmanager-technical','marine-pms-defect-corrective','supported',0.990,'DNV explicitly documents defect management plus planned and unplanned maintenance workflows.','https://www.dnv.com/services/planned-maintenance-system-for-technical-ship-management-shipmanager-technical-1509/'),
('dnv-shipmanager-technical','marine-pms-condition-predictive','supported',0.990,'ShipManager Technical supports counter-, calendar- and condition-based tasks; this row does not infer separate AI predictive-maintenance functionality.','https://www.dnv.com/services/planned-maintenance-system-for-technical-ship-management-shipmanager-technical-1509/'),
('dnv-shipmanager-technical','marine-pms-spares-inventory','supported',0.990,'DNV documents stock-count updates from spare-parts consumption and integration of the PMS with Fleet Equipment Register, Order Management and Stock Control.','https://www.dnv.com/services/planned-maintenance-system-for-technical-ship-management-shipmanager-technical-1509/'),
('dnv-shipmanager-technical','marine-pms-procurement-integration','partially_supported',0.970,'ShipManager Technical is designed to integrate with the separate ShipManager Procurement module; procurement is not treated as universally included in the Technical module.','https://www.dnv.com/services/planned-maintenance-system-for-technical-ship-management-shipmanager-technical-1509/'),
('dnv-shipmanager-technical','marine-pms-drydock-projects','partially_supported',0.960,'DNV offers ShipManager Drydock as a related technical-project product; dry-dock management is not treated as universally included in ShipManager Technical.','https://www.dnv.com/services/planned-maintenance-system-for-technical-ship-management-shipmanager-technical-1509/'),
('dnv-shipmanager-technical','marine-pms-class-compliance','supported',0.990,'ShipManager Technical is DNV type approved, supports class-relevant job categorization and interfaces with Machinery Maintenance Connect for fleet audit workflows.','https://www.dnv.com/services/planned-maintenance-system-for-technical-ship-management-shipmanager-technical-1509/'),
('dnv-shipmanager-technical','marine-pms-analytics-kpis','partially_supported',0.970,'Fleet-wide management reporting is supported through the connected ShipManager Analyzer business-intelligence product rather than assumed as core Technical entitlement.','https://www.dnv.com/services/planned-maintenance-system-for-technical-ship-management-shipmanager-technical-1509/'),
('dnv-shipmanager-technical','marine-pms-shipshore-integration','supported',0.990,'DNV documents a common ship/shore interface and integration with other ShipManager modules.','https://www.dnv.com/services/planned-maintenance-system-for-technical-ship-management-shipmanager-technical-1509/'),

-- BASSnet Neo Maintenance
('bassnet-neo-maintenance','marine-pms-scheduling-execution','supported',0.990,'BASSnet Maintenance supports scheduled jobs, planners, job orders, job history, counters and routine maintenance tracking across vessel and shore.','https://www.bassnet.no/solution/technical-planned-maintenance-system/'),
('bassnet-neo-maintenance','marine-pms-equipment-hierarchy','supported',0.990,'BASSnet documents flexible component/equipment hierarchies and centralized fleet-wide equipment libraries with linked jobs, materials and documents.','https://www.bassnet.no/solution/fleet-management/'),
('bassnet-neo-maintenance','marine-pms-defect-corrective','supported',0.990,'BASSnet provides defect management linked to job orders, requisitions, claims, documents and dry-dock projects.','https://www.bassnet.no/solution/technical-planned-maintenance-system/'),
('bassnet-neo-maintenance','marine-pms-condition-predictive','supported',0.980,'BASSnet documents condition monitoring plus counter-based maintenance and AI suggestions using historical and forecast data; exact AI scope depends on configuration/version.','https://www.bassnet.no/solution/technical-planned-maintenance-system/'),
('bassnet-neo-maintenance','marine-pms-spares-inventory','supported',0.990,'BASSnet Materials provides fleet-wide inventory and spare-parts control tightly connected to maintenance and equipment.','https://www.bassnet.no/solution/technical-planned-maintenance-system/'),
('bassnet-neo-maintenance','marine-pms-procurement-integration','supported',0.990,'BASSnet Neo unifies Maintenance, Procurement and Materials within the same cloud-native suite and links defects/jobs to requisitions and purchase orders.','https://www.bassnet.no/insight/bassnet-neo-launching-a-unified-fully-managed-maritime-saas-solution/'),
('bassnet-neo-maintenance','marine-pms-drydock-projects','supported',0.990,'BASSnet Projects supports dry-docking and technical projects with specifications, schedules, resources, tenders, cost control and progress management.','https://www.bassnet.no/solution/technical-planned-maintenance-system/'),
('bassnet-neo-maintenance','marine-pms-class-compliance','supported',0.990,'BASSnet Neo has current RINA type approval for ship management/planned maintenance and supports compliance-oriented maintenance tracking.','https://www.bassnet.no/'),
('bassnet-neo-maintenance','marine-pms-analytics-kpis','supported',0.990,'BASSnet provides fleet-wide operational visibility, maintenance status, analytics and dashboards across centralized equipment and maintenance data.','https://www.bassnet.no/solution/fleet-management/'),
('bassnet-neo-maintenance','marine-pms-shipshore-integration','supported',0.990,'BASSnet supports vessel/office operation plus third-party API integration in its cloud-native fleet-management platform.','https://www.bassnet.no/'),

-- smartPAL Maintenance
('smartpal-maintenance','marine-pms-scheduling-execution','supported',0.990,'smartPAL PMS supports pre-planning, scheduling and execution of maintenance jobs with cost, time, resource and spare-part projections.','https://www.mariapps.com/cn/smartpal/planned-maintenance-system/'),
('smartpal-maintenance','marine-pms-equipment-hierarchy','supported',0.990,'smartPAL tracks assets, assemblies, spare parts, vessel equipment and job data through its Maintenance and Data Library modules.','https://www.mariapps.com/smartpal/data-library/'),
('smartpal-maintenance','marine-pms-defect-corrective','supported',0.980,'smartPAL documents detailed breakdown/defect reporting and corrective follow-up within the planned-maintenance workflow.','https://www.mariapps.com/cn/smartpal/planned-maintenance-system/'),
('smartpal-maintenance','marine-pms-condition-predictive','supported',0.990,'smartPAL documents Condition-Based Maintenance Data plus predictive and preventive maintenance routines using historical data and trends.','https://www.mariapps.com/cn/smartpal/planned-maintenance-system/'),
('smartpal-maintenance','marine-pms-spares-inventory','supported',0.990,'smartPAL links maintenance planning to real-time spare-parts tracking and inventory management.','https://www.mariapps.com/cn/smartpal/planned-maintenance-system/'),
('smartpal-maintenance','marine-pms-procurement-integration','supported',0.990,'MariApps documents direct integration between Maintenance, Procurement and Data Library workflows across the smartPAL suite.','https://www.mariapps.com/smartpal/'),
('smartpal-maintenance','marine-pms-drydock-projects','supported',0.990,'smartPAL Drydock provides standardized planning, specifications, repairs, reporting, tender comparison, budget/cost control and integration with Maintenance and Procurement.','https://www.mariapps.com/smartpal/drydock-software/'),
('smartpal-maintenance','marine-pms-class-compliance','supported',0.990,'smartPAL PMS is documented as DNV type approved and configurable to manufacturer and Class requirements with audit/compliance reporting.','https://www.mariapps.com/cn/smartpal/planned-maintenance-system/'),
('smartpal-maintenance','marine-pms-analytics-kpis','supported',0.980,'smartPAL provides fleet-wide maintenance reports, dashboards, condition data and BI reporting for maintenance performance and defects.','https://www.mariapps.com/cn/smartpal/planned-maintenance-system/'),
('smartpal-maintenance','marine-pms-shipshore-integration','supported',0.980,'smartPAL provides centralized fleet data and API/data integration across ERP, accounting and legacy maritime systems; exact interfaces depend on implementation.','https://www.mariapps.com/smartpal/'),

-- SERTICA Maintenance
('sertica-maintenance','marine-pms-scheduling-execution','supported',0.990,'SERTICA Maintenance supports recurring, calendar-, usage- and condition-triggered jobs plus planned and corrective maintenance execution.','https://www.sertica.com/maintenance/'),
('sertica-maintenance','marine-pms-equipment-hierarchy','supported',0.990,'SERTICA uses a component-based vessel hierarchy linking jobs, history, documents and spare parts to technical assets.','https://www.sertica.com/maintenance/'),
('sertica-maintenance','marine-pms-defect-corrective','supported',0.990,'SERTICA includes dedicated defect reporting and conversion of issues into corrective jobs with responsibility and status tracking.','https://www.sertica.com/maintenance/'),
('sertica-maintenance','marine-pms-condition-predictive','supported',0.980,'SERTICA documents preventive, predictive and corrective maintenance strategies using calendar, running hours and condition-based indicators.','https://www.sertica.com/maintenance/'),
('sertica-maintenance','marine-pms-spares-inventory','supported',0.990,'SERTICA links maintenance jobs to spare-parts inventory, consumption, stock levels and requisitions.','https://www.sertica.com/maintenance/'),
('sertica-maintenance','marine-pms-procurement-integration','supported',0.990,'SERTICA Maintenance integrates with SERTICA Procurement for inventory-aware maintenance and purchasing workflows.','https://www.sertica.com/maintenance/'),
('sertica-maintenance','marine-pms-class-compliance','supported',0.980,'SERTICA documents audit-ready logs, digital validation, role-based access and structured maintenance workflows supporting inspection and regulatory compliance.','https://www.sertica.com/maintenance/'),
('sertica-maintenance','marine-pms-analytics-kpis','supported',0.990,'SERTICA provides fleet-wide maintenance dashboards, KPIs, overdue-job views, defect statistics and advanced analytics.','https://www.sertica.com/maintenance/'),
('sertica-maintenance','marine-pms-shipshore-integration','supported',0.990,'SERTICA synchronizes maintenance data between ship and shore and provides SYNC/third-party system integration.','https://www.sertica.com/maintenance/'),

-- Cloud Fleet Manager Maintenance
('cloud-fleet-manager-maintenance','marine-pms-scheduling-execution','supported',0.990,'CFM Maintenance provides central planned-maintenance job creation, intervals, overdue tracking and fleet-wide planning.','https://hanseaticsoft.com/cloud-maintenance/maintenance/'),
('cloud-fleet-manager-maintenance','marine-pms-equipment-hierarchy','supported',0.990,'CFM Maintenance manages equipment/components and supports copying component structures across vessels for standardized fleet setup.','https://hanseaticsoft.com/new-features/cfm-updates-january-2026/'),
('cloud-fleet-manager-maintenance','marine-pms-defect-corrective','supported',0.980,'CFM Maintenance supports disturbance reports and maintenance follow-up directly from component workflows onboard.','https://hanseaticsoft.com/new-features/cfm-updates-june-2026/'),
('cloud-fleet-manager-maintenance','marine-pms-condition-predictive','partially_supported',0.950,'CFM documents condition status, counters and maintenance planning, but a full predictive-maintenance/AI capability is not inferred from the reviewed evidence.','https://hanseaticsoft.com/new-features/cfm-updates-february-2026/'),
('cloud-fleet-manager-maintenance','marine-pms-spares-inventory','supported',0.980,'CFM integrates maintenance with equipment/spares and fleet inventory workflows; detailed stock functionality is delivered through connected CFM modules.','https://hanseaticsoft.com/'),
('cloud-fleet-manager-maintenance','marine-pms-procurement-integration','supported',0.990,'CFM Maintenance is deeply integrated with CFM Purchase, and the broader platform supports shared requisition/inventory workflows.','https://hanseaticsoft.com/'),
('cloud-fleet-manager-maintenance','marine-pms-class-compliance','supported',0.980,'CFM Maintenance distinguishes critical/class-relevant work and holds current planned-maintenance software conformity/type-approval evidence.','https://hanseaticsoft.com/cloud-maintenance/maintenance/'),
('cloud-fleet-manager-maintenance','marine-pms-analytics-kpis','supported',0.980,'CFM Maintenance provides dashboards and fleet-wide status visibility for critical, overdue and completed jobs; broader KPIs are available across Cloud Fleet Manager.','https://hanseaticsoft.com/new-features/cfm-updates-august-2026/'),
('cloud-fleet-manager-maintenance','marine-pms-shipshore-integration','supported',0.990,'Cloud Fleet Manager is web-based ashore while Cloud Ship Manager supports onboard use with automatic synchronization and platform APIs/integrations.','https://hanseaticsoft.com/');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat120_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat120_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party vendor documentation supporting this capability.'
FROM cat120_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Promote deployment only where current product-specific evidence is explicit.
INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.990
FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug IN('bassnet-neo-maintenance','cloud-fleet-manager-maintenance')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

-- Do not infer Android/iOS/mobile-web support from generic app, smartphone, tablet or browser claims.
INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000
FROM products p CROSS JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') x
WHERE p.slug IN('dnv-shipmanager-technical','bassnet-neo-maintenance','smartpal-maintenance','sertica-maintenance','cloud-fleet-manager-maintenance')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

COMMIT;
