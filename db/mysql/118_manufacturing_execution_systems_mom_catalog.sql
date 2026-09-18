-- TechSelectAI Manufacturing Execution Systems / MOM catalog expansion.
-- Adds one canonical MES/MOM category and five evidence-backed current products.
-- Official first-party evidence reviewed Sep 2026. Presence is not an endorsement.
-- Unknown != Unsupported. No Fit Score, recommendation ranking, review score, follower/community popularity or commercial placement logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('Manufacturing Execution Systems & MOM','manufacturing-execution-systems-mom','Specialized software for controlling, tracking and optimizing factory-floor production across execution, scheduling, traceability, quality, equipment connectivity, performance, workforce and enterprise integration.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @mes_cat=(SELECT id FROM categories WHERE slug='manufacturing-execution-systems-mom' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@mes_cat,'Production Execution & Traceability','mes-execution-traceability','Production control, electronic work execution, scheduling, work-in-process, material tracking and genealogy.',1),
(@mes_cat,'Quality, Connectivity & Operations Intelligence','mes-quality-connectivity','Quality/compliance, equipment connectivity, OEE and analytics, labor/resources, enterprise integration and multi-site standardization.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.sec,1
FROM modules m JOIN (
 SELECT 'mes-execution-traceability' module_slug,'Production execution & work-order control' name,'mes-production-execution' slug,'Dispatch, execute, monitor and record production orders, operations, routings or shop-floor activities in real time.' description,0 sec UNION ALL
 SELECT 'mes-execution-traceability','Electronic work instructions & paperless operations','mes-work-instructions-paperless','Guide operators with electronic work instructions, digital procedures, operator dashboards or paperless execution records.',0 UNION ALL
 SELECT 'mes-execution-traceability','Production scheduling & dispatch','mes-scheduling-dispatch','Sequence, schedule, dispatch or dynamically coordinate production work across constrained manufacturing resources.',0 UNION ALL
 SELECT 'mes-execution-traceability','WIP, material traceability & genealogy','mes-wip-traceability-genealogy','Track work-in-process, materials, lots, batches, serials and product genealogy through manufacturing operations.',0 UNION ALL
 SELECT 'mes-quality-connectivity','Quality, SPC & compliance execution','mes-quality-compliance','Execute inspections, quality checks, SPC, defect/rework controls, compliance or electronic manufacturing records where supported.',0 UNION ALL
 SELECT 'mes-quality-connectivity','Equipment / machine connectivity & automation','mes-equipment-connectivity','Connect MES workflows and data collection to machines, PLCs, automation systems, IIoT devices or shop-floor control systems.',0 UNION ALL
 SELECT 'mes-quality-connectivity','OEE, production analytics & KPIs','mes-oee-analytics','Provide real-time production visibility, OEE, throughput, loss, yield, downtime or other manufacturing performance analytics.',0 UNION ALL
 SELECT 'mes-quality-connectivity','Labor, skills & resource management','mes-labor-resource-management','Plan, allocate, validate or track labor, skills, certifications, tools and other manufacturing resources.',0 UNION ALL
 SELECT 'mes-quality-connectivity','ERP / PLM / business-system integration','mes-enterprise-integration','Exchange production orders, master data, material consumption, results or other manufacturing information with ERP, PLM and enterprise systems through supported interfaces or APIs.',0 UNION ALL
 SELECT 'mes-quality-connectivity','Multi-site standardization & governance','mes-multisite-standardization','Standardize, deploy, govern and compare manufacturing processes, configurations or KPIs across multiple factories or global operations.',0
) x ON x.module_slug=m.slug
WHERE m.category_id=@mes_cat
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Siemens','siemens','https://www.siemens.com/','Industrial technology, automation and manufacturing software vendor.','active'),
('SAP','sap','https://www.sap.com/','Enterprise application and manufacturing software vendor.','active'),
('AVEVA','aveva','https://www.aveva.com/','Industrial software vendor for operations, manufacturing, engineering and data management.','active'),
('Dassault Systèmes','dassault-systemes','https://www.3ds.com/','Industrial design, engineering and manufacturing software vendor.','active'),
('Critical Manufacturing','critical-manufacturing','https://www.criticalmanufacturing.com/','Manufacturing execution and Industry 4.0 software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat118_products;
CREATE TEMPORARY TABLE cat118_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO cat118_products VALUES
('siemens','manufacturing-execution-systems-mom','Siemens Opcenter Execution','siemens-opcenter-execution','Manufacturing execution system family for production execution, sequencing, resource control, material/WIP tracking, quality, equipment connectivity and manufacturing visibility across discrete, process and regulated industries.','https://www.siemens.com/en-gb/products/opcenter/execution/'),
('sap','manufacturing-execution-systems-mom','SAP Digital Manufacturing','sap-digital-manufacturing','Cloud manufacturing operations platform for production execution, resource orchestration, operator guidance, traceability, quality, equipment connectivity, analytics and enterprise integration.','https://www.sap.com/products/scm/digital-manufacturing.html'),
('aveva','manufacturing-execution-systems-mom','AVEVA Manufacturing Execution System','aveva-manufacturing-execution-system','Hybrid-cloud manufacturing execution system for production control, paperless work, inventory and genealogy, quality, industrial connectivity, OEE analytics and multi-site manufacturing standardization.','https://www.aveva.com/en/products/manufacturing-execution-system/'),
('dassault-systemes','manufacturing-execution-systems-mom','DELMIA Apriso','delmia-apriso','Manufacturing operations management platform with MES production execution plus integrated quality, materials, labor, equipment, analytics and enterprise process standardization across multiple plants.','https://www.3ds.com/products/delmia/apriso'),
('critical-manufacturing','manufacturing-execution-systems-mom','Critical Manufacturing MES','critical-manufacturing-mes','Modular MES for complex manufacturing with shop-floor execution, WIP and genealogy, quality, APS, equipment/IIoT integration, analytics, automation and enterprise-wide standardization.','https://www.criticalmanufacturing.com/mes-for-industry-4-0/');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat118_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS cat118_sources;
CREATE TEMPORARY TABLE cat118_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat118_sources VALUES
('siemens-opcenter-execution','https://www.siemens.com/en-gb/products/opcenter/execution/','Siemens Opcenter Execution','Siemens'),
('siemens-opcenter-execution','https://www.siemens.com/en-gb/solutions/manufacturing-execution-system-mes/','Siemens Manufacturing Execution System Software','Siemens'),
('siemens-opcenter-execution','https://www.siemens.com/en-us/products/opcenter/execution/process/','Siemens Opcenter Execution Process','Siemens'),
('sap-digital-manufacturing','https://www.sap.com/products/scm/digital-manufacturing.html','SAP Digital Manufacturing','SAP'),
('sap-digital-manufacturing','https://www.sap.com/products/scm/digital-manufacturing/features.html','SAP Digital Manufacturing Features','SAP'),
('sap-digital-manufacturing','https://www.sap.com/products/scm/digital-manufacturing/product-tour.html','SAP Digital Manufacturing Product Tour','SAP'),
('sap-digital-manufacturing','https://help.sap.com/docs/sap-digital-manufacturing/application-help-for-sap-digital-manufacturing/overview','SAP Digital Manufacturing Application Help Overview','SAP'),
('aveva-manufacturing-execution-system','https://www.aveva.com/en/products/manufacturing-execution-system/','AVEVA Manufacturing Execution System','AVEVA'),
('aveva-manufacturing-execution-system','https://www.aveva.com/en/solutions/operations/operations-execution-management/','AVEVA Operations and Execution Management','AVEVA'),
('aveva-manufacturing-execution-system','https://www.aveva.com/en/perspectives/blog/what-a-hybrid-cloud-manufacturing-execution-system-means-for-manufacturing/','AVEVA Hybrid Cloud MES Architecture','AVEVA'),
('delmia-apriso','https://www.3ds.com/products/delmia/apriso','DELMIA Apriso','Dassault Systèmes'),
('delmia-apriso','https://www.3ds.com/products/delmia/apriso/production','DELMIA Apriso Manufacturing Production','Dassault Systèmes'),
('delmia-apriso','https://www.3ds.com/products/delmia/apriso/quality-control','DELMIA Apriso Quality Control','Dassault Systèmes'),
('critical-manufacturing-mes','https://www.criticalmanufacturing.com/mes-for-industry-4-0/','Critical Manufacturing MES for Industry 4.0','Critical Manufacturing'),
('critical-manufacturing-mes','https://www.criticalmanufacturing.com/mes-for-industry-4-0/complete-modular-solution','Critical Manufacturing Complete Modular MES','Critical Manufacturing'),
('critical-manufacturing-mes','https://www.criticalmanufacturing.com/mes-for-industry-4-0/advanced-planning-and-scheduling/','Critical Manufacturing Advanced Planning and Scheduling','Critical Manufacturing'),
('critical-manufacturing-mes','https://www.criticalmanufacturing.com/mes-for-industry-4-0/easy-deployment/','Critical Manufacturing MES Deployment','Critical Manufacturing');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM cat118_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS cat118_facts;
CREATE TEMPORARY TABLE cat118_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat118_facts VALUES
-- Siemens Opcenter Execution
('siemens-opcenter-execution','mes-production-execution','supported',0.990,'Opcenter Execution is Siemens MES family for orchestrating and controlling production and processes across manufacturing operations.','https://www.siemens.com/en-gb/products/opcenter/execution/'),
('siemens-opcenter-execution','mes-work-instructions-paperless','supported',0.970,'Siemens documents paperless manufacturing, electronic work instructions and electronic records in multiple Opcenter Execution industry variants; exact functions vary by selected edition.','https://www.siemens.com/en-us/products/opcenter/execution/process/'),
('siemens-opcenter-execution','mes-scheduling-dispatch','supported',0.990,'Opcenter Execution documents optimized sequencing and synchronized production execution to reduce cycle times.','https://www.siemens.com/en-gb/products/opcenter/execution/'),
('siemens-opcenter-execution','mes-wip-traceability-genealogy','supported',0.990,'Siemens documents production tracking, work-in-process status, material movement and full manufacturing traceability.','https://www.siemens.com/en-gb/solutions/manufacturing-execution-system-mes/'),
('siemens-opcenter-execution','mes-quality-compliance','supported',0.980,'Opcenter Execution Process documents integrated quality sampling/testing and traceability; exact quality and regulated-record scope varies by industry-specific Opcenter edition.','https://www.siemens.com/en-us/products/opcenter/execution/process/'),
('siemens-opcenter-execution','mes-equipment-connectivity','supported',0.990,'Siemens documents digital linkage between enterprise systems and automated manufacturing equipment and machine connectivity in Opcenter Execution variants.','https://www.siemens.com/en-gb/products/opcenter/execution/'),
('siemens-opcenter-execution','mes-oee-analytics','supported',0.970,'Siemens documents actionable performance data, real-time production monitoring and manufacturing optimization; exact KPI/OEE packages vary by deployment.','https://www.siemens.com/en-gb/solutions/manufacturing-execution-system-mes/'),
('siemens-opcenter-execution','mes-labor-resource-management','supported',0.980,'Opcenter Execution manages manufacturing resources including personnel, materials, components and work-in-process.','https://www.siemens.com/en-gb/products/opcenter/execution/'),
('siemens-opcenter-execution','mes-enterprise-integration','supported',0.980,'Siemens documents connecting enterprise systems with automated manufacturing equipment through the MES digital thread; exact adapters and APIs require edition validation.','https://www.siemens.com/en-gb/products/opcenter/execution/'),

-- SAP Digital Manufacturing
('sap-digital-manufacturing','mes-production-execution','supported',0.990,'SAP Digital Manufacturing for execution manages and controls manufacturing and shop-floor operations across the production cycle.','https://help.sap.com/docs/sap-digital-manufacturing/application-help-for-sap-digital-manufacturing/overview'),
('sap-digital-manufacturing','mes-work-instructions-paperless','supported',0.990,'SAP documents production operator dashboards, work instructions, paperless execution and process controls.','https://www.sap.com/products/scm/digital-manufacturing/features.html'),
('sap-digital-manufacturing','mes-scheduling-dispatch','supported',0.990,'Resource Orchestration schedules, dispatches and monitors manufacturing operations and resources in real time.','https://www.sap.com/products/scm/digital-manufacturing/features.html'),
('sap-digital-manufacturing','mes-wip-traceability-genealogy','supported',0.990,'SAP documents material consumption, WIP inventory, full batch traceability and production genealogy.','https://www.sap.com/products/scm/digital-manufacturing/product-tour.html'),
('sap-digital-manufacturing','mes-quality-compliance','supported',0.990,'SAP documents qualitative/quantitative quality checks, scrap/rework, process controls, electronic signatures and compliance traceability.','https://www.sap.com/products/scm/digital-manufacturing/product-tour.html'),
('sap-digital-manufacturing','mes-equipment-connectivity','supported',0.990,'SAP Digital Manufacturing documents production connectivity to physical shop-floor elements, machines and automation systems.','https://help.sap.com/docs/sap-digital-manufacturing/application-help-for-sap-digital-manufacturing/overview'),
('sap-digital-manufacturing','mes-oee-analytics','supported',0.990,'SAP documents embedded manufacturing insights, KPIs, OEE, throughput, yield, scrap, downtime and cross-plant analytics.','https://www.sap.com/products/scm/digital-manufacturing/features.html'),
('sap-digital-manufacturing','mes-labor-resource-management','supported',0.990,'SAP documents labor tracking, workforce scheduling, skills/certification management and closed-loop resource orchestration.','https://www.sap.com/products/scm/digital-manufacturing/features.html'),
('sap-digital-manufacturing','mes-enterprise-integration','supported',0.990,'SAP documents bidirectional integration of business systems and operations, APIs/services and integration with SAP enterprise applications.','https://www.sap.com/products/scm/digital-manufacturing/features.html'),
('sap-digital-manufacturing','mes-multisite-standardization','supported',0.970,'SAP documents plant and enterprise-level manufacturing execution and visibility across locations; exact rollout governance depends on implementation.','https://www.sap.com/products/scm/digital-manufacturing.html'),

-- AVEVA Manufacturing Execution System
('aveva-manufacturing-execution-system','mes-production-execution','supported',0.990,'AVEVA MES documents real-time production control, work-order execution and synchronization of human and machine actions.','https://www.aveva.com/en/products/manufacturing-execution-system/'),
('aveva-manufacturing-execution-system','mes-work-instructions-paperless','supported',0.990,'AVEVA documents paperless work management, operator workflows and digital standard operating procedures through integrated work-task capabilities.','https://www.aveva.com/en/products/manufacturing-execution-system/'),
('aveva-manufacturing-execution-system','mes-scheduling-dispatch','supported',0.970,'AVEVA MES manages plant schedules and production execution; deeper advanced scheduling optimization may use separate/partner APS capabilities.','https://www.aveva.com/en/products/manufacturing-execution-system/'),
('aveva-manufacturing-execution-system','mes-wip-traceability-genealogy','supported',0.990,'AVEVA documents real-time inventory, material transformation tracking, traceability and genealogy from raw material to finished product.','https://www.aveva.com/en/products/manufacturing-execution-system/'),
('aveva-manufacturing-execution-system','mes-quality-compliance','supported',0.990,'AVEVA MES documents automated quality plans, SPC, specification control, traceability and compliance-oriented execution records.','https://www.aveva.com/en/products/manufacturing-execution-system/'),
('aveva-manufacturing-execution-system','mes-equipment-connectivity','supported',0.990,'AVEVA documents native integration with System Platform plus agnostic industrial connectivity for MES data collection and automation execution.','https://www.aveva.com/en/products/manufacturing-execution-system/'),
('aveva-manufacturing-execution-system','mes-oee-analytics','supported',0.990,'AVEVA documents OEE, schedule adherence, productivity KPIs, multi-site visualization and industrial analytics.','https://www.aveva.com/en/products/manufacturing-execution-system/'),
('aveva-manufacturing-execution-system','mes-enterprise-integration','supported',0.990,'AVEVA documents Enterprise Integration for exchanging production planning/results data with ERP and other business applications.','https://www.aveva.com/en/products/manufacturing-execution-system/'),
('aveva-manufacturing-execution-system','mes-multisite-standardization','supported',0.990,'AVEVA documents multi-site MES standardization, reusable models, common KPIs and centralized visibility across distributed plants.','https://www.aveva.com/en/products/manufacturing-execution-system/'),

-- DELMIA Apriso
('delmia-apriso','mes-production-execution','supported',0.990,'DELMIA Apriso Production provides MES production execution and real-time manufacturing control across shop-floor operations.','https://www.3ds.com/products/delmia/apriso/production'),
('delmia-apriso','mes-work-instructions-paperless','supported',0.980,'Apriso documents guided execution, step-by-step instructions and paperless manufacturing workflows across production and quality operations.','https://www.3ds.com/products/delmia/apriso/quality-control'),
('delmia-apriso','mes-scheduling-dispatch','supported',0.980,'DELMIA Apriso documents integrated scheduling, resource allocation and responsive manufacturing cycles within production management.','https://www.3ds.com/products/delmia/apriso'),
('delmia-apriso','mes-wip-traceability-genealogy','supported',0.990,'Apriso documents synchronized materials management, WIP reduction, real-time tracking and traceability across manufacturing operations.','https://www.3ds.com/products/delmia/apriso'),
('delmia-apriso','mes-quality-compliance','supported',0.990,'Apriso Quality Control documents inspections, testing, SPC, defect/issue management, compliance controls and integrated production quality.','https://www.3ds.com/products/delmia/apriso/quality-control'),
('delmia-apriso','mes-equipment-connectivity','supported',0.990,'DELMIA Apriso documents machine connectivity, edge computing and shop-floor automation integration across multiple protocols.','https://www.3ds.com/products/delmia/apriso'),
('delmia-apriso','mes-oee-analytics','supported',0.990,'Apriso documents real-time production analytics, core manufacturing metrics and OEE-related operational visibility.','https://www.3ds.com/products/delmia/apriso'),
('delmia-apriso','mes-labor-resource-management','supported',0.990,'DELMIA Apriso documents time/labor management, operator skills/certifications and manufacturing resource allocation.','https://www.3ds.com/products/delmia/apriso'),
('delmia-apriso','mes-enterprise-integration','supported',0.990,'Apriso documents ERP/PLM connectivity and more than 40 standard ERP connection points for production/material/result exchange.','https://www.3ds.com/products/delmia/apriso'),
('delmia-apriso','mes-multisite-standardization','supported',0.990,'Apriso documents centralized process governance and consistent rollout of manufacturing best practices across multiple plants.','https://www.3ds.com/products/delmia/apriso'),

-- Critical Manufacturing MES
('critical-manufacturing-mes','mes-production-execution','supported',0.990,'Critical Manufacturing MES documents comprehensive modular shop-floor operations management with real-time visibility and control.','https://www.criticalmanufacturing.com/mes-for-industry-4-0/complete-modular-solution'),
('critical-manufacturing-mes','mes-scheduling-dispatch','supported',0.990,'Critical Manufacturing documents a natively integrated Advanced Planning and Scheduling module using current WIP, equipment and resource constraints.','https://www.criticalmanufacturing.com/mes-for-industry-4-0/advanced-planning-and-scheduling/'),
('critical-manufacturing-mes','mes-wip-traceability-genealogy','supported',0.990,'Critical Manufacturing documents batch, lot and unit tracking with real-time material history, traceability and genealogy.','https://www.criticalmanufacturing.com/mes-for-industry-4-0/complete-modular-solution'),
('critical-manufacturing-mes','mes-quality-compliance','supported',0.980,'Critical Manufacturing documents natively integrated quality functionality and error-proof execution; exact regulated-record features depend on licensed modules and industry use case.','https://www.criticalmanufacturing.com/mes-for-industry-4-0/'),
('critical-manufacturing-mes','mes-equipment-connectivity','supported',0.990,'Critical Manufacturing documents IIoT, equipment integration, standard/IoT interfaces and automation as core Industry 4.0 capabilities.','https://www.criticalmanufacturing.com/mes-for-industry-4-0/'),
('critical-manufacturing-mes','mes-oee-analytics','supported',0.990,'Critical Manufacturing documents integrated efficiency, analytics, real-time visibility and manufacturing performance insight.','https://www.criticalmanufacturing.com/mes-for-industry-4-0/'),
('critical-manufacturing-mes','mes-labor-resource-management','partially_supported',0.950,'Integrated APS can consider personnel certifications and sequence personnel, but a full standalone labor-management scope is not inferred from the reviewed evidence.','https://www.criticalmanufacturing.com/mes-for-industry-4-0/advanced-planning-and-scheduling/'),
('critical-manufacturing-mes','mes-multisite-standardization','supported',0.990,'Critical Manufacturing documents enterprise baseline MES standardization and rapid deployment of governed configurations across multiple sites.','https://www.criticalmanufacturing.com/mes-for-industry-4-0/');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat118_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat118_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party vendor documentation supporting this capability.'
FROM cat118_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Promote deployment only where current product-specific evidence is explicit.
INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.990
FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug='sap-digital-manufacturing'
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.990
FROM products p JOIN deployment_models d ON d.slug='on-premise'
WHERE p.slug IN('aveva-manufacturing-execution-system','delmia-apriso','critical-manufacturing-mes')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

-- Do not infer platform-specific mobile access from browser, connected-device or worker-interface claims.
INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000
FROM products p CROSS JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') x
WHERE p.slug IN('siemens-opcenter-execution','sap-digital-manufacturing','aveva-manufacturing-execution-system','delmia-apriso','critical-manufacturing-mes')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

COMMIT;
