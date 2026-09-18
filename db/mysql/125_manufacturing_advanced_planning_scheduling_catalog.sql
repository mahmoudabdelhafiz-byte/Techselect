-- TechSelectAI Manufacturing Advanced Planning & Scheduling catalog expansion.
-- Adds one canonical APS category and five evidence-backed current products.
-- Official first-party evidence reviewed Sep 2026. Presence is not an endorsement.
-- Unknown != Unsupported. No Fit Score, recommendation ranking, review score, follower/community popularity or commercial placement logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('Manufacturing Advanced Planning & Scheduling (APS)','advanced-planning-scheduling-manufacturing','Specialized manufacturing planning and scheduling software for finite-capacity planning, material and resource constraints, sequencing, changeovers, scenario analysis, rescheduling and ERP/MES-connected production optimization.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @aps_cat=(SELECT id FROM categories WHERE slug='advanced-planning-scheduling-manufacturing' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@aps_cat,'Constraint-Based Planning & Scheduling','aps-constraint-planning','Finite-capacity production scheduling, materials, secondary resources, sequence/changeover optimization and capacity planning across planning horizons.',1),
(@aps_cat,'Scenario, Integration & Planning Intelligence','aps-scenario-integration','What-if analysis, dynamic rescheduling, multi-site planning, ERP/MES integration and planning-performance visibility.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.sec,1
FROM modules m JOIN (
 SELECT 'aps-constraint-planning' module_slug,'Finite-capacity & constraint-based scheduling' name,'aps-finite-capacity-scheduling' slug,'Create feasible production schedules using finite capacity, resource availability and operational constraints rather than infinite-capacity assumptions.' description,0 sec UNION ALL
 SELECT 'aps-constraint-planning','Material, BOM & availability constraints','aps-material-bom-constraints','Plan and schedule against bills of material, inventory, raw-material availability, component dependencies or shortages where supported.',0 UNION ALL
 SELECT 'aps-constraint-planning','Labor, tooling & secondary-resource constraints','aps-secondary-resource-constraints','Model labor, skills, tools, secondary resources or additional resource constraints alongside machines and work centers.',0 UNION ALL
 SELECT 'aps-constraint-planning','Sequence, setup & changeover optimization','aps-sequence-changeover-optimization','Optimize production sequence while considering setup times, changeovers, campaigns, preferred orderings or comparable sequence-dependent constraints.',0 UNION ALL
 SELECT 'aps-constraint-planning','Medium/long-range capacity & production planning','aps-capacity-production-planning','Support production and capacity planning beyond immediate detailed scheduling, including master planning, rough-cut capacity or longer planning horizons.',0 UNION ALL
 SELECT 'aps-scenario-integration','What-if scenarios & simulation','aps-whatif-scenarios','Create alternative plans or simulations to compare the impact of demand, capacity, staffing, equipment, material or priority changes before publishing a schedule.',0 UNION ALL
 SELECT 'aps-scenario-integration','Dynamic rescheduling & disruption response','aps-dynamic-rescheduling','Recalculate or interactively adjust schedules when orders, demand, materials, machines, labor or shop-floor conditions change.',0 UNION ALL
 SELECT 'aps-scenario-integration','Multi-site / multi-plant planning','aps-multisite-planning','Coordinate or compare production planning and constrained capacity across multiple plants, sites or manufacturing networks where explicitly documented.',0 UNION ALL
 SELECT 'aps-scenario-integration','ERP, MES & shop-floor integration','aps-erp-mes-integration','Exchange orders, inventory, routings, materials, production status or schedule results with ERP, MES and other manufacturing systems through supported interfaces.',0 UNION ALL
 SELECT 'aps-scenario-integration','Planning dashboards, KPIs & visual analysis','aps-planning-analytics','Provide planning boards, Gantt views, capacity/bottleneck visibility, alerts, KPIs or schedule-performance analysis to support planning decisions.',0
) x ON x.module_slug=m.slug
WHERE m.category_id=@aps_cat
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Siemens','siemens','https://www.siemens.com/','Industrial technology, automation and manufacturing software vendor.','active'),
('Dassault Systèmes','dassault-systemes','https://www.3ds.com/','Industrial design, engineering, manufacturing and planning software vendor.','active'),
('Asprova Corporation','asprova','https://www.asprova.com/','Advanced planning and production scheduling software vendor.','active'),
('CAI Software','cai-software','https://caisoft.com/','Manufacturing software vendor and current owner of CAI PlanetTogether.','active'),
('SAP','sap','https://www.sap.com/','Enterprise application and manufacturing planning software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat125_products;
CREATE TEMPORARY TABLE cat125_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO cat125_products VALUES
('siemens','advanced-planning-scheduling-manufacturing','Siemens Opcenter Advanced Planning and Scheduling','siemens-opcenter-aps','APS product family for long-, mid- and short-term production planning, finite-capacity scheduling, material/resource constraints, sequencing, what-if analysis and production-plan visibility.','https://www.siemens.com/en-us/products/opcenter/advanced-planning-scheduling-aps/'),
('dassault-systemes','advanced-planning-scheduling-manufacturing','DELMIA Ortems','delmia-ortems','Advanced planning and scheduling solution spanning manufacturing planning, finite-capacity production scheduling, material synchronization, scenario analysis, optimization, ERP/MES integration and planning KPIs.','https://www.3ds.com/products/delmia/ortems'),
('asprova','advanced-planning-scheduling-manufacturing','Asprova APS','asprova-aps','Advanced planning and scheduling system for finite-capacity production planning across sales, manufacturing, inventory and purchasing with long-, mid- and short-term scheduling and ERP integration.','https://www.asprova.com/en/asprova.html'),
('cai-software','advanced-planning-scheduling-manufacturing','CAI PlanetTogether APS','cai-planettogether-aps','Advanced planning and scheduling software for constraint-based production scheduling around machines, labor, materials, tooling, changeovers, due dates, scenarios, multi-site planning and ERP/MES-connected execution.','https://www.planettogether.com/products/advanced-planning-scheduling-software'),
('sap','advanced-planning-scheduling-manufacturing','SAP S/4HANA Production Planning and Detailed Scheduling (PP/DS)','sap-s4hana-ppds','Embedded SAP S/4HANA production-planning and detailed-scheduling capability for critical products and bottleneck resources, with finite scheduling, optimization, material/resource availability and interactive planning.','https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/f899ce30af9044299d573ea30b533f1c/2451c95360267614e10000000a174cb4-1643.html');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat125_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS cat125_sources;
CREATE TEMPORARY TABLE cat125_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat125_sources VALUES
('siemens-opcenter-aps','https://www.siemens.com/en-us/products/opcenter/advanced-planning-scheduling-aps/','Siemens Opcenter Advanced Planning and Scheduling','Siemens'),
('siemens-opcenter-aps','https://www.siemens.com/en-us/products/opcenter/advanced-planning-scheduling-aps/advanced-scheduling-software/','Siemens Opcenter Advanced Scheduling','Siemens'),
('siemens-opcenter-aps','https://www.siemens.com/en-us/products/opcenter/advanced-planning-scheduling-aps/advanced-planning-software/','Siemens Opcenter Advanced Planning','Siemens'),
('siemens-opcenter-aps','https://www.siemens.com/en-us/products/opcenter/scheduling-standard/','Siemens Opcenter Scheduling Standard','Siemens'),
('siemens-opcenter-aps','https://www.siemens.com/en-us/technology/manufacturing-scheduling-software/','Siemens Manufacturing Scheduling Software','Siemens'),
('delmia-ortems','https://www.3ds.com/products/delmia/ortems','DELMIA Ortems Planning and Scheduling','Dassault Systèmes'),
('delmia-ortems','https://www.3ds.com/products/delmia/ortems/production-scheduler','DELMIA Ortems Production Scheduler','Dassault Systèmes'),
('delmia-ortems','https://www.3ds.com/products/delmia/ortems/manufacturing-planner','DELMIA Ortems Manufacturing Planner','Dassault Systèmes'),
('delmia-ortems','https://www.3ds.com/products/delmia/ortems/synchronized-requirements-planner','DELMIA Ortems Synchronized Requirements Planner','Dassault Systèmes'),
('delmia-ortems','https://www.3ds.com/support/documentation/delmia-ortems-2026-installation-and-reference-guides','DELMIA Ortems 2026 Installation and Reference Guides','Dassault Systèmes'),
('asprova-aps','https://www.asprova.com/en/asprova.html','Asprova Advanced Planning and Scheduling','Asprova Corporation'),
('asprova-aps','https://www.asprova.com/en/asprova/modules/asprova_ap.html','Asprova APS Module','Asprova Corporation'),
('asprova-aps','https://www.asprova.com/en/','Asprova Production Scheduling System','Asprova Corporation'),
('asprova-aps','https://www.asprova.com/en/faq/implementation-considerations/000461-2.html','Asprova Scheduling Options','Asprova Corporation'),
('asprova-aps','https://lib.asprova.com/en/2-beginners/25-erp-interface.html','Asprova ERP Interface','Asprova Corporation'),
('asprova-aps','https://www.asprova.com/en/asprova/environment.html','Asprova APS Operating Environment','Asprova Corporation'),
('cai-planettogether-aps','https://www.planettogether.com/products/advanced-planning-scheduling-software','CAI PlanetTogether APS','CAI PlanetTogether'),
('cai-planettogether-aps','https://www.planettogether.com/finite-capacity-scheduling-software','PlanetTogether Finite Capacity Scheduling','CAI PlanetTogether'),
('cai-planettogether-aps','https://www.planettogether.com/aps-software-integrations','PlanetTogether APS Integrations','CAI PlanetTogether'),
('cai-planettogether-aps','https://www.planettogether.com/news/planettogether-joins-cai','PlanetTogether Joins CAI','CAI PlanetTogether'),
('cai-planettogether-aps','https://caisoft.com/resources/cai-software-acquires-planettogether/','CAI Software Acquires PlanetTogether','CAI Software'),
('sap-s4hana-ppds','https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/f899ce30af9044299d573ea30b533f1c/2451c95360267614e10000000a174cb4-1643.html','SAP S/4HANA Production Planning and Detailed Scheduling','SAP'),
('sap-s4hana-ppds','https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/f899ce30af9044299d573ea30b533f1c/330bdbd6e033485d8530029a7147c1da.html','SAP Advanced Scheduling Board','SAP'),
('sap-s4hana-ppds','https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/f899ce30af9044299d573ea30b533f1c/8539c95360267614e10000000a174cb4.html','SAP S/4HANA and PP/DS Production Process','SAP');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM cat125_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS cat125_facts;
CREATE TEMPORARY TABLE cat125_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat125_facts VALUES
-- Siemens Opcenter APS
('siemens-opcenter-aps','aps-finite-capacity-scheduling','supported',0.990,'Opcenter Scheduling creates order-based multi-constraint schedules using resource availability and operational constraints.','https://www.siemens.com/en-us/products/opcenter/advanced-planning-scheduling-aps/advanced-scheduling-software/'),
('siemens-opcenter-aps','aps-material-bom-constraints','supported',0.990,'Siemens documents material usage rules, shortage visibility and BOM-based production/material planning within the Opcenter APS family.','https://www.siemens.com/en-us/products/opcenter/advanced-planning-scheduling-aps/advanced-planning-software/'),
('siemens-opcenter-aps','aps-secondary-resource-constraints','supported',0.980,'Siemens manufacturing-scheduling documentation explicitly includes tooling and personnel availability alongside equipment/resource constraints.','https://www.siemens.com/en-us/technology/manufacturing-scheduling-software/'),
('siemens-opcenter-aps','aps-sequence-changeover-optimization','supported',0.990,'Opcenter Scheduling supports sequence-dependent changeovers, preferred sequencing, campaigning and changeover-time minimization.','https://www.siemens.com/en-us/products/opcenter/advanced-planning-scheduling-aps/advanced-scheduling-software/'),
('siemens-opcenter-aps','aps-capacity-production-planning','supported',0.990,'Opcenter APS explicitly spans long-term strategic, medium-term tactical and detailed scheduling horizons, with capacity and MPS planning.','https://www.siemens.com/en-us/products/opcenter/advanced-planning-scheduling-aps/'),
('siemens-opcenter-aps','aps-whatif-scenarios','supported',0.980,'Opcenter Scheduling Standard explicitly documents what-if simulations, impact analysis and capable-to-promise.','https://www.siemens.com/en-us/products/opcenter/scheduling-standard/'),
('siemens-opcenter-aps','aps-dynamic-rescheduling','supported',0.980,'Siemens documents interactive schedule adjustment and rapid response to unforeseen events, order changes and production disruptions.','https://www.siemens.com/en-us/technology/manufacturing-scheduling-software/'),
('siemens-opcenter-aps','aps-erp-mes-integration','partially_supported',0.960,'Opcenter Planning exports purchase requirements to ERP and the wider Opcenter portfolio supports enterprise/manufacturing connectivity, but a universal APS-native ERP/MES adapter catalogue is not inferred.','https://www.siemens.com/en-us/products/opcenter/advanced-planning-scheduling-aps/advanced-planning-software/'),
('siemens-opcenter-aps','aps-planning-analytics','supported',0.980,'Opcenter APS provides interactive planning boards, material/stock views, capacity graphs and schedule-versus-actual visibility.','https://www.siemens.com/en-us/products/opcenter/advanced-planning-scheduling-aps/advanced-planning-software/'),

-- DELMIA Ortems
('delmia-ortems','aps-finite-capacity-scheduling','supported',0.990,'DELMIA Ortems explicitly uses finite-capacity, constraint-based planning and scheduling across machines, materials, workforce and processes.','https://www.3ds.com/products/delmia/ortems'),
('delmia-ortems','aps-material-bom-constraints','supported',0.990,'Ortems integrates material availability and multi-level BOM synchronization through its planning family, including Synchronized Requirements Planner.','https://www.3ds.com/products/delmia/ortems/synchronized-requirements-planner'),
('delmia-ortems','aps-secondary-resource-constraints','supported',0.990,'Ortems Production Scheduler explicitly manages constraints across machines, tools and operators.','https://www.3ds.com/products/delmia/ortems/production-scheduler'),
('delmia-ortems','aps-sequence-changeover-optimization','supported',0.990,'Ortems Production Scheduler optimizes sequences and dispatching to reduce changeover/setup time and improve resource utilization.','https://www.3ds.com/products/delmia/ortems/production-scheduler'),
('delmia-ortems','aps-capacity-production-planning','supported',0.990,'Ortems spans long-, mid- and short-term planning, with Manufacturing Planner supporting finite-capacity midterm planning and load analysis.','https://www.3ds.com/products/delmia/ortems/manufacturing-planner'),
('delmia-ortems','aps-whatif-scenarios','supported',0.990,'Ortems explicitly supports what-if simulations and comparison of alternative plans against KPIs.','https://www.3ds.com/products/delmia/ortems'),
('delmia-ortems','aps-dynamic-rescheduling','supported',0.990,'Ortems supports rapid rescheduling for demand changes, late deliveries, breakdowns, labor shortages and other disruptions.','https://www.3ds.com/products/delmia/ortems'),
('delmia-ortems','aps-erp-mes-integration','supported',0.990,'Dassault Systèmes explicitly documents Ortems integration with ERP, MES and operational data.','https://www.3ds.com/products/delmia/ortems'),
('delmia-ortems','aps-planning-analytics','supported',0.990,'Ortems monitors on-time delivery, lead time, throughput, adherence, cost and utilization KPIs with centralized visual planning.','https://www.3ds.com/products/delmia/ortems'),

-- Asprova APS
('asprova-aps','aps-finite-capacity-scheduling','supported',0.990,'Asprova documents finite-capacity scheduling as a core production-scheduling capability.','https://www.asprova.com/en/'),
('asprova-aps','aps-material-bom-constraints','supported',0.980,'Asprova APS integrates sales, manufacturing, inventory and purchasing; current ERP-interface training also documents BOM/material import for scheduling.','https://lib.asprova.com/en/2-beginners/25-erp-interface.html'),
('asprova-aps','aps-secondary-resource-constraints','supported',0.980,'Asprova finite-capacity scheduling documentation includes equipment and personnel constraints; exact modeling depends on configured scheduling logic.','https://www.asprova.com/en/'),
('asprova-aps','aps-sequence-changeover-optimization','partially_supported',0.980,'Asprova supports changeover/setup optimization, but the reviewed vendor documentation identifies Optimization as an optional feature rather than assuming universal entitlement.','https://www.asprova.com/en/faq/implementation-considerations/000461-2.html'),
('asprova-aps','aps-capacity-production-planning','supported',0.990,'Asprova APS explicitly performs long-, mid- and short-term scheduling across sales, manufacturing and purchasing in one module.','https://www.asprova.com/en/asprova/modules/asprova_ap.html'),
('asprova-aps','aps-dynamic-rescheduling','supported',0.970,'Asprova documents fast adjustment of production schedules as demand and factory conditions change.','https://www.asprova.com/en/asprova.html'),
('asprova-aps','aps-erp-mes-integration','supported',0.980,'Asprova documents ERP and production-control integration, including SAP, QAD, JD Edwards, Dynamics and legacy-system data exchange examples.','https://lib.asprova.com/en/2-beginners/25-erp-interface.html'),
('asprova-aps','aps-planning-analytics','partially_supported',0.960,'Asprova provides visual management and Gantt-based planning, while KPI costing/analysis is documented as an optional feature.','https://www.asprova.com/en/faq/implementation-considerations/000461-2.html'),

-- CAI PlanetTogether APS
('cai-planettogether-aps','aps-finite-capacity-scheduling','supported',0.990,'PlanetTogether APS builds schedules around finite machine/work-center capacity and real plant constraints.','https://www.planettogether.com/finite-capacity-scheduling-software'),
('cai-planettogether-aps','aps-material-bom-constraints','supported',0.990,'PlanetTogether APS explicitly plans around material availability, inventory, routings and shortages.','https://www.planettogether.com/products/advanced-planning-scheduling-software'),
('cai-planettogether-aps','aps-secondary-resource-constraints','supported',0.990,'PlanetTogether explicitly models labor, tooling and other secondary/constrained resources alongside machines.','https://www.planettogether.com/finite-capacity-scheduling-software'),
('cai-planettogether-aps','aps-sequence-changeover-optimization','supported',0.990,'PlanetTogether sequences work around setup times, changeover rules, cleaning requirements and transition logic.','https://www.planettogether.com/finite-capacity-scheduling-software'),
('cai-planettogether-aps','aps-capacity-production-planning','supported',0.980,'PlanetTogether APS supports capacity-oriented production planning for complex, constrained and multi-site manufacturing; exact corporate S&OP scope is not inferred.','https://www.planettogether.com/products/advanced-planning-scheduling-software'),
('cai-planettogether-aps','aps-whatif-scenarios','supported',0.990,'PlanetTogether explicitly supports what-if analysis for rush orders, downtime, material delays, staffing changes and priority shifts.','https://www.planettogether.com/finite-capacity-scheduling-software'),
('cai-planettogether-aps','aps-dynamic-rescheduling','supported',0.990,'PlanetTogether supports rapid schedule adjustment when demand, materials, machines or labor conditions change.','https://www.planettogether.com/products/advanced-planning-scheduling-software'),
('cai-planettogether-aps','aps-multisite-planning','supported',0.980,'PlanetTogether explicitly positions APS for multi-site manufacturers and multi-plant capacity planning.','https://www.planettogether.com/products/advanced-planning-scheduling-software'),
('cai-planettogether-aps','aps-erp-mes-integration','supported',0.990,'PlanetTogether documents integration with ERP, MES, WMS, labor and supply-chain systems using APIs, database connections, file exchange and middleware.','https://www.planettogether.com/aps-software-integrations'),
('cai-planettogether-aps','aps-planning-analytics','supported',0.980,'PlanetTogether provides capacity-risk, bottleneck and delivery-impact visibility plus a web analytics layer; exact analytics packaging should be validated.','https://www.planettogether.com/news/planettogether-joins-cai'),

-- SAP S/4HANA PP/DS
('sap-s4hana-ppds','aps-finite-capacity-scheduling','supported',0.990,'SAP PP/DS detailed scheduling automatically schedules orders on resources while considering planning conditions and resource availability.','https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/f899ce30af9044299d573ea30b533f1c/2451c95360267614e10000000a174cb4-1643.html'),
('sap-s4hana-ppds','aps-material-bom-constraints','supported',0.990,'SAP PP/DS explicitly considers component availability and uses S/4HANA BOM/routing/PDS data in integrated production planning.','https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/f899ce30af9044299d573ea30b533f1c/8539c95360267614e10000000a174cb4.html'),
('sap-s4hana-ppds','aps-secondary-resource-constraints','partially_supported',0.950,'PP/DS supports detailed resource scheduling, but the reviewed sources do not justify assuming generic labor/skill/tool scheduling parity with dedicated APS products.','https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/f899ce30af9044299d573ea30b533f1c/2451c95360267614e10000000a174cb4-1643.html'),
('sap-s4hana-ppds','aps-sequence-changeover-optimization','supported',0.980,'PP/DS optimization can optimize resource schedules using criteria including setup times and setup costs.','https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/f899ce30af9044299d573ea30b533f1c/2451c95360267614e10000000a174cb4-1643.html'),
('sap-s4hana-ppds','aps-capacity-production-planning','supported',0.970,'PP/DS supports production planning runs, finite production planning and detailed scheduling for critical products and bottleneck resources.','https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/f899ce30af9044299d573ea30b533f1c/2451c95360267614e10000000a174cb4-1643.html'),
('sap-s4hana-ppds','aps-dynamic-rescheduling','supported',0.980,'SAP PP/DS supports automated planning plus interactive planning and rescheduling through planning-board and planning-run functions.','https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/f899ce30af9044299d573ea30b533f1c/2451c95360267614e10000000a174cb4-1643.html'),
('sap-s4hana-ppds','aps-erp-mes-integration','partially_supported',0.990,'PP/DS is embedded/integrated with SAP S/4HANA manufacturing orders and planning data; this is not evidence of broad third-party MES/ERP connector coverage.','https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/f899ce30af9044299d573ea30b533f1c/8539c95360267614e10000000a174cb4.html'),
('sap-s4hana-ppds','aps-planning-analytics','partially_supported',0.960,'SAP provides planning boards, product/resource views and alert monitoring, but a standalone APS KPI/analytics package is not inferred from the reviewed PP/DS evidence.','https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/f899ce30af9044299d573ea30b533f1c/330bdbd6e033485d8530029a7147c1da.html');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat125_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat125_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party vendor documentation supporting this capability.'
FROM cat125_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Promote on-premises deployment only where current product-specific evidence is explicit.
INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.990
FROM products p JOIN deployment_models d ON d.slug='on-premise'
WHERE p.slug IN('delmia-ortems','asprova-aps','cai-planettogether-aps','sap-s4hana-ppds')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

-- Do not infer SaaS from cloud/server references. PlanetTogether currently documents a client-server architecture with cloud or on-premises server options.
-- Platform-specific mobile access remains unknown for all five products.
INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000
FROM products p CROSS JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') x
WHERE p.slug IN('siemens-opcenter-aps','delmia-ortems','asprova-aps','cai-planettogether-aps','sap-s4hana-ppds')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

COMMIT;
