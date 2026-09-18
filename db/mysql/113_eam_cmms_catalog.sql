-- TechSelectAI Enterprise Asset Management / CMMS catalog expansion.
-- Adds one canonical EAM/CMMS category and five evidence-backed products.
-- Official first-party evidence reviewed Sep 2026. Presence is not an endorsement.
-- Unknown != Unsupported. No Fit Score, recommendation ranking, review score, follower/community popularity or commercial placement logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('Enterprise Asset Management & CMMS','enterprise-asset-management-cmms','Software for managing physical asset records, maintenance work, preventive maintenance, spare parts, technician execution and maintenance performance across asset-intensive operations.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @eam_cat=(SELECT id FROM categories WHERE slug='enterprise-asset-management-cmms' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@eam_cat,'Assets & Maintenance Planning','eam-assets-planning','Asset records, work orders, preventive maintenance, condition-based triggers and maintenance planning.',1),
(@eam_cat,'Execution, Inventory & Insight','eam-execution-insight','Technician execution, spare-parts inventory, mobile workflows, reporting and integration with operational systems.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.sec,1
FROM modules m JOIN (
 SELECT 'eam-assets-planning' module_slug,'Asset registry & maintenance history' name,'eam-asset-registry-history' slug,'Maintain structured asset records, hierarchy, lifecycle context, maintenance history and related cost or condition information.' description,0 sec UNION ALL
 SELECT 'eam-assets-planning','Work order management','eam-work-orders','Create, assign, prioritize, track and complete corrective or planned maintenance work orders.',0 UNION ALL
 SELECT 'eam-assets-planning','Preventive / scheduled maintenance','eam-preventive-maintenance','Schedule recurring or meter-based preventive maintenance and automatically generate planned work.',0 UNION ALL
 SELECT 'eam-assets-planning','Condition-based / predictive maintenance','eam-condition-predictive','Use meter, sensor, condition or analytics signals to trigger or recommend maintenance before failure.',0 UNION ALL
 SELECT 'eam-execution-insight','Parts & maintenance inventory','eam-parts-inventory','Track spare parts, stock levels, consumption, reorder points and maintenance-related inventory.',0 UNION ALL
 SELECT 'eam-execution-insight','Mobile / offline technician execution','eam-mobile-technician','Allow technicians to access, update or complete maintenance work from mobile devices, including offline workflows where supported.',0 UNION ALL
 SELECT 'eam-execution-insight','Maintenance reporting & KPIs','eam-reporting-kpis','Provide dashboards, maintenance KPIs, backlog, downtime, cost, compliance or reliability reporting.',0 UNION ALL
 SELECT 'eam-execution-insight','Enterprise integrations / APIs','eam-enterprise-integrations','Connect maintenance and asset data with ERP, sensors, operational systems or external applications through APIs or packaged integrations.',0
) x ON x.module_slug=m.slug
WHERE m.category_id=@eam_cat
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('IBM','ibm','https://www.ibm.com/','Enterprise technology, cloud, data, AI and asset-management software vendor.','active'),
('MaintainX','maintainx','https://www.getmaintainx.com/','Maintenance, operations and asset-management software vendor.','active'),
('UpKeep','upkeep','https://upkeep.com/','Maintenance, CMMS and asset-operations software vendor.','active'),
('Rockwell Automation','rockwell-automation','https://www.rockwellautomation.com/','Industrial automation, manufacturing software and maintenance technology vendor.','active'),
('Fluke','fluke','https://www.fluke.com/','Industrial test, reliability and maintenance technology vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat113_products;
CREATE TEMPORARY TABLE cat113_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO cat113_products VALUES
('ibm','enterprise-asset-management-cmms','IBM Maximo Application Suite','ibm-maximo-application-suite','Enterprise asset management and maintenance suite for managing critical physical assets, maintenance work, reliability, inspections and lifecycle planning across asset-intensive operations.','https://www.ibm.com/products/maximo'),
('maintainx','enterprise-asset-management-cmms','MaintainX','maintainx-cmms','Cloud CMMS and maintenance platform for work orders, preventive and condition-based maintenance, asset records, parts inventory, technician workflows and maintenance reporting.','https://www.getmaintainx.com/use-cases/cmms-software'),
('upkeep','enterprise-asset-management-cmms','UpKeep CMMS','upkeep-cmms','Mobile-first CMMS for work orders, preventive maintenance, asset lifecycle tracking, parts inventory, technician mobility, analytics and maintenance automation.','https://upkeep.com/product/cmms-software/'),
('rockwell-automation','enterprise-asset-management-cmms','Fiix CMMS','fiix-cmms','Cloud-based AI-powered CMMS for work orders, preventive maintenance, assets, parts inventory, mobile maintenance, analytics and integrations across maintenance operations.','https://fiixsoftware.com/about-fiix/'),
('fluke','enterprise-asset-management-cmms','eMaint CMMS','emaint-cmms','Cloud CMMS and EAM software for work orders, preventive maintenance, asset management, parts inventory, analytics and connected reliability workflows.','https://www.emaint.com/cmms-software');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat113_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS cat113_sources;
CREATE TEMPORARY TABLE cat113_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat113_sources VALUES
('ibm-maximo-application-suite','https://www.ibm.com/products/maximo','IBM Maximo Application Suite','IBM'),
('ibm-maximo-application-suite','https://www.ibm.com/products/maximo/asset-management','IBM Maximo Asset Management','IBM'),
('ibm-maximo-application-suite','https://www.ibm.com/products/maximo/ai-asset-management','IBM Maximo AI Asset Management','IBM'),
('maintainx-cmms','https://www.getmaintainx.com/use-cases/cmms-software','MaintainX CMMS Software','MaintainX'),
('maintainx-cmms','https://help.getmaintainx.com/','MaintainX Help Center','MaintainX'),
('maintainx-cmms','https://help.getmaintainx.com/about-work-orders','MaintainX Work Orders','MaintainX'),
('upkeep-cmms','https://upkeep.com/product/cmms-software/','UpKeep CMMS','UpKeep'),
('upkeep-cmms','https://upkeep.com/features/','UpKeep Features','UpKeep'),
('upkeep-cmms','https://upkeep.com/product/mobile-cmms/','UpKeep Mobile CMMS','UpKeep'),
('fiix-cmms','https://fiixsoftware.com/about-fiix/','Fiix CMMS Overview','Fiix'),
('fiix-cmms','https://lp.fiixsoftware.com/preventive-maintenance-software-demo.html','Fiix Preventive Maintenance','Fiix'),
('fiix-cmms','https://www.rockwellautomation.com/en-us/capabilities/smart-manufacturing.html','Rockwell Automation Fiix CMMS','Rockwell Automation'),
('emaint-cmms','https://www.emaint.com/cmms-software','eMaint CMMS Software','eMaint'),
('emaint-cmms','https://www.emaint.com/analytics-and-reporting','eMaint Analytics and Reporting','eMaint'),
('emaint-cmms','https://www.emaint.com/connected-reliability','eMaint Connected Reliability','eMaint');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM cat113_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS cat113_facts;
CREATE TEMPORARY TABLE cat113_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat113_facts VALUES
-- IBM Maximo Application Suite
('ibm-maximo-application-suite','eam-asset-registry-history','supported',0.990,'IBM documents end-to-end enterprise asset lifecycle management with asset history and maintenance processes across critical equipment and infrastructure.','https://www.ibm.com/products/maximo/asset-management'),
('ibm-maximo-application-suite','eam-work-orders','supported',0.990,'Maximo documents connected maintenance work management and field execution as core enterprise asset-management capabilities.','https://www.ibm.com/products/maximo'),
('ibm-maximo-application-suite','eam-preventive-maintenance','supported',0.990,'IBM documents reliability-centered, preventive and planned maintenance workflows in Maximo.','https://www.ibm.com/products/maximo'),
('ibm-maximo-application-suite','eam-condition-predictive','supported',0.990,'IBM documents condition-based maintenance using real-time sensor, meter and asset-performance insights.','https://www.ibm.com/products/maximo'),
('ibm-maximo-application-suite','eam-reporting-kpis','supported',0.980,'Maximo provides operational and reliability insights; detailed report/KPI availability varies by application and package.','https://www.ibm.com/products/maximo'),
('ibm-maximo-application-suite','eam-enterprise-integrations','supported',0.970,'Maximo is designed to connect asset, maintenance and operational data across enterprise systems; exact adapters and integration entitlements should be validated for the selected package.','https://www.ibm.com/products/maximo'),

-- MaintainX
('maintainx-cmms','eam-asset-registry-history','supported',0.990,'MaintainX documents centralized maintenance data, equipment health, asset information and repair/replacement decision support.','https://help.getmaintainx.com/'),
('maintainx-cmms','eam-work-orders','supported',0.990,'MaintainX documents creation, assignment, monitoring and completion of work orders and work requests.','https://help.getmaintainx.com/about-work-orders'),
('maintainx-cmms','eam-preventive-maintenance','supported',0.990,'MaintainX documents preventive maintenance scheduled by time or usage.','https://www.getmaintainx.com/use-cases/cmms-software'),
('maintainx-cmms','eam-condition-predictive','supported',0.970,'MaintainX documents meter-triggered and condition-based work when readings cross configured thresholds; predictive AI features may depend on product configuration.','https://help.getmaintainx.com/'),
('maintainx-cmms','eam-parts-inventory','supported',0.990,'MaintainX documents parts inventory, stock monitoring and low-stock alerts.','https://help.getmaintainx.com/'),
('maintainx-cmms','eam-mobile-technician','supported',0.990,'MaintainX is documented as a cloud CMMS for web and mobile maintenance workflows.','https://help.getmaintainx.com/'),
('maintainx-cmms','eam-reporting-kpis','supported',0.990,'MaintainX documents dashboards and reports for equipment health, preventive-maintenance compliance, maintenance cost and workforce metrics.','https://help.getmaintainx.com/'),

-- UpKeep
('upkeep-cmms','eam-asset-registry-history','supported',0.990,'UpKeep documents full asset lifecycle tracking with maintenance history, warranties, depreciation and condition information.','https://upkeep.com/product/cmms-software/'),
('upkeep-cmms','eam-work-orders','supported',0.990,'UpKeep documents real-time creation, assignment, prioritization and completion of mobile work orders.','https://upkeep.com/product/cmms-software/'),
('upkeep-cmms','eam-preventive-maintenance','supported',0.990,'UpKeep documents recurring preventive maintenance by time, meter readings and AI-recommended intervals.','https://upkeep.com/product/cmms-software/'),
('upkeep-cmms','eam-condition-predictive','supported',0.980,'UpKeep documents sensor-driven work orders and AI-assisted PM optimization; exact predictive functionality depends on enabled platform modules.','https://upkeep.com/product/cmms-software/'),
('upkeep-cmms','eam-parts-inventory','supported',0.990,'UpKeep documents parts and inventory management with quantities, costing, reorder points and purchase-order workflows.','https://upkeep.com/features/'),
('upkeep-cmms','eam-mobile-technician','supported',0.990,'UpKeep documents full mobile CMMS functionality on iOS and Android with offline mode and automatic synchronization.','https://upkeep.com/product/mobile-cmms/'),
('upkeep-cmms','eam-reporting-kpis','supported',0.990,'UpKeep documents analytics, dashboards and maintenance reporting for KPIs and operational trends.','https://upkeep.com/product/cmms-software/'),
('upkeep-cmms','eam-enterprise-integrations','supported',0.980,'UpKeep Enterprise documents API and custom integrations; exact integrations vary by plan and implementation.','https://upkeep.com/product/cmms-software/'),

-- Fiix
('fiix-cmms','eam-asset-registry-history','supported',0.990,'Fiix documents asset management with equipment records, historical maintenance, KPIs and asset-performance context.','https://fiixsoftware.com/about-fiix/'),
('fiix-cmms','eam-work-orders','supported',0.990,'Fiix documents work order creation, completion, requests, notifications and maintenance scheduling.','https://fiixsoftware.com/about-fiix/'),
('fiix-cmms','eam-preventive-maintenance','supported',0.990,'Fiix documents preventive maintenance scheduling by date/time, meter readings, events and alarms.','https://lp.fiixsoftware.com/preventive-maintenance-software-demo.html'),
('fiix-cmms','eam-condition-predictive','supported',0.970,'Fiix documents condition-based maintenance triggers using connected sensors; predictive capabilities beyond those triggers may depend on companion analytics products.','https://lp.fiixsoftware.com/preventive-maintenance-software-demo.html'),
('fiix-cmms','eam-parts-inventory','supported',0.990,'Fiix documents inventory, parts and supplies management for maintenance operations.','https://fiixsoftware.com/about-fiix/'),
('fiix-cmms','eam-mobile-technician','supported',0.990,'Fiix documents mobile maintenance with access to work orders and asset information, including offline operation.','https://lp.fiixsoftware.com/preventive-maintenance-software-demo.html'),
('fiix-cmms','eam-reporting-kpis','supported',0.990,'Fiix documents dashboards, KPI tracking, custom reporting and maintenance analytics.','https://fiixsoftware.com/about-fiix/'),
('fiix-cmms','eam-enterprise-integrations','supported',0.990,'Fiix documents integration with thousands of endpoints and business systems through its integration capabilities.','https://lp.fiixsoftware.com/preventive-maintenance-software-demo.html'),

-- eMaint
('emaint-cmms','eam-asset-registry-history','supported',0.990,'eMaint documents asset tracking from installation through retirement with maintenance and cost history.','https://www.emaint.com/cmms-software'),
('emaint-cmms','eam-work-orders','supported',0.990,'eMaint documents centralized work-order creation, routing, prioritization, approvals and real-time tracking.','https://www.emaint.com/cmms-software'),
('emaint-cmms','eam-preventive-maintenance','supported',0.990,'eMaint documents preventive maintenance scheduled by time, meter readings or conditions.','https://www.emaint.com/cmms-software'),
('emaint-cmms','eam-condition-predictive','partially_supported',0.950,'eMaint supports connected reliability and condition-monitoring workflows, but deeper predictive monitoring may depend on Fluke sensors/services or additional reliability products.','https://www.emaint.com/connected-reliability'),
('emaint-cmms','eam-parts-inventory','supported',0.990,'eMaint documents intelligent inventory management connected to maintenance assets and work.','https://www.emaint.com/cmms-software'),
('emaint-cmms','eam-reporting-kpis','supported',0.990,'eMaint documents maintenance reporting for work status, PM progress, KPIs and leadership performance reporting.','https://www.emaint.com/analytics-and-reporting');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat113_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat113_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party vendor documentation supporting this capability.'
FROM cat113_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Deployment is promoted only where the vendor explicitly describes the selected product packaging.
INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.990
FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug IN('ibm-maximo-application-suite','maintainx-cmms','upkeep-cmms','fiix-cmms','emaint-cmms')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.990
FROM products p JOIN deployment_models d ON d.slug='on-premise'
WHERE p.slug='ibm-maximo-application-suite'
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

-- Platform-specific mobile access is promoted only where current product documentation is explicit.
INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'supported','supported','vendor_documentation',0.990
FROM products p CROSS JOIN (SELECT 'android' platform UNION ALL SELECT 'ios') x
WHERE p.slug='upkeep-cmms'
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000
FROM products p CROSS JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') x
WHERE p.slug IN('ibm-maximo-application-suite','maintainx-cmms','fiix-cmms','emaint-cmms')
   OR (p.slug='upkeep-cmms' AND x.platform='mobile_web')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

COMMIT;
