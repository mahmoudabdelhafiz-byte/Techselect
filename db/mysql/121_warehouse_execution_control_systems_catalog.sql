-- TechSelectAI Warehouse Execution & Control Systems catalog expansion.
-- Adds one canonical WES/WCS category and five evidence-backed current products.
-- Official first-party evidence reviewed Sep 2026. Presence is not an endorsement.
-- Unknown != Unsupported. No Fit Score, recommendation ranking, review score, follower/community popularity or commercial placement logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('Warehouse Execution & Control Systems','warehouse-execution-control-systems','Specialized software for real-time warehouse execution, orchestration and automation control across orders, labor, robotics, material flow, inventory, host systems, visibility, analytics and automated fulfillment operations.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @wes_cat=(SELECT id FROM categories WHERE slug='warehouse-execution-control-systems' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@wes_cat,'Execution Orchestration','wes-execution-orchestration','Dynamic task prioritization, human-machine orchestration, resource balancing and operational execution across warehouse workflows.',1),
(@wes_cat,'Automation Control & Visibility','wes-automation-control','Automation/MHE integration, material-flow control, host-system integration, real-time visibility, analytics and simulation/digital-twin capabilities.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.sec,1
FROM modules m JOIN (
 SELECT 'wes-execution-orchestration' module_slug,'Dynamic order & task prioritization' name,'wes-task-prioritization' slug,'Continuously prioritize, release, sequence or interleave warehouse work based on due times, constraints, demand and live operating conditions.' description,0 sec UNION ALL
 SELECT 'wes-execution-orchestration','Human, robot & automation orchestration','wes-human-robot-orchestration','Coordinate work across people, robots, automated equipment and manual workflows using a common execution layer.',0 UNION ALL
 SELECT 'wes-execution-orchestration','Labor & resource optimization','wes-resource-labor-optimization','Balance and assign labor, equipment and other warehouse resources according to workload, location, capacity, permissions or service objectives.',0 UNION ALL
 SELECT 'wes-execution-orchestration','Inventory & fulfillment workflow execution','wes-inventory-workflow','Execute and coordinate receiving, replenishment, storage, picking, consolidation, staging, shipping or comparable fulfillment workflows with real-time inventory/process state where supported.',0 UNION ALL
 SELECT 'wes-automation-control','Automation, robotics & MHE integration','wes-automation-integration','Integrate conveyors, AS/RS, shuttles, sorters, AMRs/AGVs, goods-to-person systems, robotics and other material-handling equipment into warehouse execution.',0 UNION ALL
 SELECT 'wes-automation-control','Material-flow routing & WCS control','wes-material-flow-control','Route and control material movement and machine-level execution through warehouse control, material-flow-control or equivalent real-time automation functions.',0 UNION ALL
 SELECT 'wes-automation-control','WMS, ERP & host-system integration','wes-host-integration','Exchange orders, inventory, tasks, status and execution data with WMS, ERP, MES or other host systems through supported interfaces and APIs.',0 UNION ALL
 SELECT 'wes-automation-control','Real-time operational visibility & exception handling','wes-visibility-exceptions','Provide live operational status, alerts, bottleneck/exception visibility and operator intervention across automated and manual warehouse processes.',0 UNION ALL
 SELECT 'wes-automation-control','Analytics, KPIs & throughput optimization','wes-analytics-kpis','Use dashboards, historical/real-time analytics, optimization algorithms or AI/ML to improve throughput, utilization, labor efficiency and service performance.',0 UNION ALL
 SELECT 'wes-automation-control','Simulation, emulation & digital twin','wes-simulation-digital-twin','Model, emulate, test or visualize warehouse automation and material flow before or during live operation where explicitly supported.',0
) x ON x.module_slug=m.slug
WHERE m.category_id=@wes_cat
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Honeywell','honeywell','https://www.honeywell.com/','Industrial automation, warehouse execution and control software vendor.','active'),
('FORTNA','fortna','https://www.fortna.com/','Warehouse automation, execution and controls software vendor.','active'),
('Dematic','dematic','https://www.dematic.com/','Warehouse automation, execution and control software vendor.','active'),
('Swisslog','swisslog','https://www.swisslog.com/','Automated intralogistics and warehouse software vendor.','active'),
('Blue Yonder','blue-yonder','https://blueyonder.com/','Supply-chain planning, warehouse management and warehouse execution software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat121_products;
CREATE TEMPORARY TABLE cat121_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO cat121_products VALUES
('honeywell','warehouse-execution-control-systems','Honeywell Momentum WES','honeywell-momentum-wes','Cloud-capable warehouse execution system for dynamic order release, labor/resource allocation, robotics and automation orchestration, real-time visibility and configurable fulfillment execution within the Momentum Core ecosystem.','https://automation.honeywell.com/us/en/software/warehouse-automation/momentum-warehouse-execution-system'),
('fortna','warehouse-execution-control-systems','FORTNA WES','fortna-wes','Warehouse execution system for real-time orchestration of people, processes, inventory and automation using optimization algorithms across automated and mixed-manual fulfillment operations.','https://www.fortna.com/software/wes/'),
('dematic','warehouse-execution-control-systems','Dematic Warehouse Execution System','dematic-warehouse-execution-system','Warehouse execution software that synchronizes fulfillment workflows, automation and material flow with host-system integration and real-time operational control across distribution and production environments.','https://www.dematic.com/en-au/software/'),
('swisslog','warehouse-execution-control-systems','Swisslog SynQ','swisslog-synq','Intralogistics software platform combining WMS, WES/WCS, material-flow control, SCADA, analytics and digital-twin functions for automated warehouse operations.','https://www.swisslog.com/en-us/products-systems-solutions/software-inventory-management/synq-warehouse-management-system-wms-mfcs'),
('blue-yonder','warehouse-execution-control-systems','Blue Yonder Warehouse Execution','blue-yonder-warehouse-execution','Cloud-native warehouse execution system for AI-assisted task prioritization, predictive work assignment, labor/robot orchestration and responsive warehouse execution.','https://blueyonder.com/solutions/warehouse-management/warehouse-execution');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat121_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS cat121_sources;
CREATE TEMPORARY TABLE cat121_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat121_sources VALUES
('honeywell-momentum-wes','https://automation.honeywell.com/us/en/software/warehouse-automation/momentum-warehouse-execution-system','Honeywell Momentum Warehouse Execution System','Honeywell'),
('honeywell-momentum-wes','https://automation.honeywell.com/us/en/software','Honeywell Warehouse Automation Software','Honeywell'),
('honeywell-momentum-wes','https://www.honeywell.com/us/en/news/press-releases/2025/03/honeywell-introduces-warehouse-execution-software-on-the-cloud','Honeywell Introduces Warehouse Execution Software on the Cloud','Honeywell'),
('fortna-wes','https://www.fortna.com/software/wes/','FORTNA WES','FORTNA'),
('fortna-wes','https://www.fortna.com/software/','FORTNA Software Suite','FORTNA'),
('fortna-wes','https://www.fortna.com/software/fortna-wcs/','FORTNA WCS','FORTNA'),
('dematic-warehouse-execution-system','https://www.dematic.com/en-au/software/','Dematic Software Overview','Dematic'),
('dematic-warehouse-execution-system','https://www.dematic.com/en-us/solutions/suite-of-intralogistics-systems/pallet-handling-systems/','Dematic Pallet Handling Systems','Dematic'),
('dematic-warehouse-execution-system','https://www.dematic.com/en-us/solutions/suite-of-intralogistics-systems/case-pick-systems/','Dematic Case Pick Systems','Dematic'),
('dematic-warehouse-execution-system','https://www.dematic.com/en-us/insights/articles/how-dematic-software-and-amrs-are-revolutionizing-logistics/','Dematic Software and AMR Orchestration','Dematic'),
('swisslog-synq','https://www.swisslog.com/en-us/products-systems-solutions/software-inventory-management/synq-warehouse-management-system-wms-mfcs','Swisslog SynQ','Swisslog'),
('swisslog-synq','https://www.swisslog.com/en-gb/products-systems-solutions/software-inventory-management','Swisslog Warehouse Automation Software','Swisslog'),
('blue-yonder-warehouse-execution','https://blueyonder.com/solutions/warehouse-management/warehouse-execution','Blue Yonder Warehouse Execution','Blue Yonder'),
('blue-yonder-warehouse-execution','https://blueyonder.com/resources/warehouse-execution-system-overview-video','Blue Yonder Warehouse Execution System Overview','Blue Yonder'),
('blue-yonder-warehouse-execution','https://blueyonder.com/resources/maximizing-warehouse-execution-with-blue-yonder','Blue Yonder Warehouse Execution Resource Orchestration','Blue Yonder'),
('blue-yonder-warehouse-execution','https://media.blueyonder.com/new-blue-yonder-offerings-enable-omni-channel-micro-fulfillment-and-enhanced-warehouse-orchestration-capabilities/','Blue Yonder Warehouse Execution SaaS Launch','Blue Yonder');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM cat121_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS cat121_facts;
CREATE TEMPORARY TABLE cat121_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat121_facts VALUES
-- Honeywell Momentum WES
('honeywell-momentum-wes','wes-task-prioritization','supported',0.990,'Momentum WES dynamically releases and prioritizes fulfillment work using live system constraints and configurable execution strategies.','https://automation.honeywell.com/us/en/software/warehouse-automation/momentum-warehouse-execution-system'),
('honeywell-momentum-wes','wes-human-robot-orchestration','supported',0.990,'Honeywell documents coordination of human resources and robotics plus integration with conveyors, AS/RS and other automation.','https://automation.honeywell.com/us/en/software/warehouse-automation/momentum-warehouse-execution-system'),
('honeywell-momentum-wes','wes-resource-labor-optimization','supported',0.990,'Momentum WES dynamically allocates work to available resources and provides labor-performance visibility using near-real-time data.','https://www.honeywell.com/us/en/news/press-releases/2025/03/honeywell-introduces-warehouse-execution-software-on-the-cloud'),
('honeywell-momentum-wes','wes-inventory-workflow','supported',0.980,'Momentum WES supports order release and fulfillment workflows including AS/RS storage, goods-to-person and consolidation scenarios; detailed inventory-master scope depends on the host architecture.','https://automation.honeywell.com/us/en/software/warehouse-automation/momentum-warehouse-execution-system'),
('honeywell-momentum-wes','wes-automation-integration','supported',0.990,'Momentum WES explicitly integrates robotics, conveyors, AS/RS and material-handling equipment into a common execution layer.','https://automation.honeywell.com/us/en/software/warehouse-automation/momentum-warehouse-execution-system'),
('honeywell-momentum-wes','wes-material-flow-control','partially_supported',0.970,'Momentum WES manages routing and execution, while dedicated WCS and machine-control functions are separate Momentum Core components and are not assumed to be included in every WES deployment.','https://automation.honeywell.com/us/en/software'),
('honeywell-momentum-wes','wes-host-integration','partially_supported',0.960,'Honeywell documents seamless system integration and configurable execution, but a universal WMS/ERP interface catalog is not inferred from the reviewed WES pages.','https://automation.honeywell.com/us/en/software/warehouse-automation/momentum-warehouse-execution-system'),
('honeywell-momentum-wes','wes-visibility-exceptions','supported',0.990,'Momentum WES provides real-time warehouse visibility and decision support from live operational data.','https://automation.honeywell.com/us/en/software/warehouse-automation/momentum-warehouse-execution-system'),
('honeywell-momentum-wes','wes-analytics-kpis','supported',0.990,'Honeywell documents AI/ML-driven optimization, dashboards, metrics and live performance intelligence for WES operations.','https://www.honeywell.com/us/en/news/press-releases/2025/03/honeywell-introduces-warehouse-execution-software-on-the-cloud'),

-- FORTNA WES
('fortna-wes','wes-task-prioritization','supported',0.990,'FORTNA WES dynamically prioritizes and interjects orders using real-time optimization algorithms to protect throughput and service performance.','https://www.fortna.com/software/wes/'),
('fortna-wes','wes-human-robot-orchestration','supported',0.990,'FORTNA WES orchestrates people, processes, robotics, automation and manual workflows in one execution layer.','https://www.fortna.com/software/wes/'),
('fortna-wes','wes-resource-labor-optimization','supported',0.990,'FORTNA WES balances available inventory and resources and dynamically assigns work to improve utilization and reduce idle time.','https://www.fortna.com/software/'),
('fortna-wes','wes-inventory-workflow','supported',0.990,'FORTNA WES supports receiving-through-shipping fulfillment workflows while balancing inventory and available resources in real time.','https://www.fortna.com/software/wes/'),
('fortna-wes','wes-automation-integration','supported',0.990,'FORTNA WES coordinates automated and manual systems and is positioned for mixed-automation warehouse environments.','https://www.fortna.com/software/wes/'),
('fortna-wes','wes-material-flow-control','partially_supported',0.980,'FORTNA WES orchestrates warehouse execution while real-time MHE control is explicitly delivered by the separate FORTNA WCS product.','https://www.fortna.com/software/fortna-wcs/'),
('fortna-wes','wes-host-integration','supported',0.980,'FORTNA documents WES integration with warehouse management and warehouse control systems; exact host adapters depend on the implementation.','https://www.fortna.com/software/wes/'),
('fortna-wes','wes-visibility-exceptions','supported',0.990,'FORTNA WES uses real-time visibility across manual and automated operations to support responsive decision-making.','https://www.fortna.com/software/wes/'),
('fortna-wes','wes-analytics-kpis','supported',0.990,'FORTNA WES uses real-time data, AI/ML and predictive optimization algorithms to improve flow, throughput and resource performance.','https://www.fortna.com/software/wes/'),

-- Dematic Warehouse Execution System
('dematic-warehouse-execution-system','wes-task-prioritization','supported',0.980,'Dematic WES continuously releases and synchronizes work using execution logic and resource-optimization algorithms across warehouse processes.','https://www.dematic.com/en-au/software/'),
('dematic-warehouse-execution-system','wes-human-robot-orchestration','supported',0.990,'Dematic documents WES/WCS software as the execution engine coordinating AMRs, automation and warehouse work.','https://www.dematic.com/en-us/insights/articles/how-dematic-software-and-amrs-are-revolutionizing-logistics/'),
('dematic-warehouse-execution-system','wes-resource-labor-optimization','supported',0.980,'Dematic documents advanced algorithms for allocating resources, orchestrating workflows and optimizing operational execution.','https://www.dematic.com/en-us/insights/articles/how-dematic-software-and-amrs-are-revolutionizing-logistics/'),
('dematic-warehouse-execution-system','wes-inventory-workflow','supported',0.990,'Dematic WES manages inbound, storage, picking, sequencing and outbound material workflows across automated fulfillment and production-buffer scenarios.','https://www.dematic.com/en-us/solutions/suite-of-intralogistics-systems/pallet-handling-systems/'),
('dematic-warehouse-execution-system','wes-automation-integration','supported',0.990,'Dematic WES is documented across AS/RS, conveyor, AGV/AMR, AutoStore and other automated-material-handling configurations.','https://www.dematic.com/en-us/solutions/suite-of-intralogistics-systems/pallet-handling-systems/'),
('dematic-warehouse-execution-system','wes-material-flow-control','partially_supported',0.970,'Dematic WES provides real-time flow synchronization, while dedicated equipment control is also exposed as a separate Dematic WCS layer; WCS entitlement is not assumed.','https://www.dematic.com/en-au/software/'),
('dematic-warehouse-execution-system','wes-host-integration','supported',0.990,'Dematic documents WMS/host interfaces and MES interfaces for WES-controlled warehouse and production material-flow use cases.','https://www.dematic.com/en-us/solutions/suite-of-intralogistics-systems/pallet-handling-systems/'),
('dematic-warehouse-execution-system','wes-visibility-exceptions','supported',0.990,'Dematic WES provides real-time control and visibility into automated warehouse operations.','https://www.dematic.com/en-us/solutions/suite-of-intralogistics-systems/pallet-handling-systems/'),

-- Swisslog SynQ
('swisslog-synq','wes-task-prioritization','supported',0.990,'Swisslog documents SynQ orchestration of orders, inventory, people and automation with real-time decisions about prioritization and sequencing.','https://www.swisslog.com/en-gb/products-systems-solutions/software-inventory-management'),
('swisslog-synq','wes-human-robot-orchestration','supported',0.990,'SynQ orchestrates human and automated workflows across robotics and warehouse automation within one intralogistics platform.','https://www.swisslog.com/en-us/products-systems-solutions/software-inventory-management/synq-warehouse-management-system-wms-mfcs'),
('swisslog-synq','wes-resource-labor-optimization','partially_supported',0.950,'SynQ orchestrates people and resources, but a standalone labor-management or workforce-optimization scope is not inferred from the reviewed product evidence.','https://www.swisslog.com/en-gb/products-systems-solutions/software-inventory-management'),
('swisslog-synq','wes-inventory-workflow','supported',0.990,'SynQ provides WMS/WES functions across inbound, inventory, fulfillment and automated warehouse workflows.','https://www.swisslog.com/en-us/products-systems-solutions/software-inventory-management/synq-warehouse-management-system-wms-mfcs'),
('swisslog-synq','wes-automation-integration','supported',0.990,'SynQ integrates warehouse automation, robotics and material-handling layers across end-to-end intralogistics workflows.','https://www.swisslog.com/en-us/products-systems-solutions/software-inventory-management/synq-warehouse-management-system-wms-mfcs'),
('swisslog-synq','wes-material-flow-control','supported',0.990,'SynQ explicitly combines WCS, material-flow control and SCADA with warehouse-management/execution functions in one platform.','https://www.swisslog.com/en-us/products-systems-solutions/software-inventory-management/synq-warehouse-management-system-wms-mfcs'),
('swisslog-synq','wes-host-integration','supported',0.990,'Swisslog documents host integration with existing WMS and ERP systems while SynQ owns real-time execution below the host layer.','https://www.swisslog.com/en-gb/products-systems-solutions/software-inventory-management'),
('swisslog-synq','wes-visibility-exceptions','supported',0.990,'SynQ Cockpit centralizes warehouse status, alerts, workflows and real-time operational visibility.','https://www.swisslog.com/en-us/products-systems-solutions/software-inventory-management/synq-warehouse-management-system-wms-mfcs'),
('swisslog-synq','wes-analytics-kpis','supported',0.990,'SynQ Cockpit provides built-in and configurable dashboards, KPIs, business intelligence and AI-driven decision support.','https://www.swisslog.com/en-us/products-systems-solutions/software-inventory-management/synq-warehouse-management-system-wms-mfcs'),
('swisslog-synq','wes-simulation-digital-twin','supported',0.990,'SynQ Digital Twin provides live 3D visualization, operational intelligence and material-flow simulation for the automated warehouse.','https://www.swisslog.com/en-us/products-systems-solutions/software-inventory-management/synq-warehouse-management-system-wms-mfcs'),

-- Blue Yonder Warehouse Execution
('blue-yonder-warehouse-execution','wes-task-prioritization','supported',0.990,'Blue Yonder Warehouse Execution dynamically escalates, de-escalates and groups tasks using priorities, due times and ML-based task-duration estimates.','https://blueyonder.com/solutions/warehouse-management/warehouse-execution'),
('blue-yonder-warehouse-execution','wes-human-robot-orchestration','supported',0.990,'Blue Yonder WES orchestrates human and machine workflows and supports multi-vendor robotics onboarding.','https://blueyonder.com/resources/maximizing-warehouse-execution-with-blue-yonder'),
('blue-yonder-warehouse-execution','wes-resource-labor-optimization','supported',0.990,'Blue Yonder WES assigns work using operator proximity, priority, permissions and predictive work assignment to improve labor utilization.','https://blueyonder.com/solutions/warehouse-management/warehouse-execution'),
('blue-yonder-warehouse-execution','wes-inventory-workflow','partially_supported',0.970,'Warehouse Execution coordinates picking, replenishment, task dependencies and outbound work, while full inventory-management scope belongs to the broader Blue Yonder warehouse-management solution.','https://blueyonder.com/solutions/warehouse-management/warehouse-execution'),
('blue-yonder-warehouse-execution','wes-automation-integration','supported',0.990,'Blue Yonder WES coordinates robotics and automation and is positioned for seamless robotics onboarding across warehouse execution.','https://blueyonder.com/resources/warehouse-execution-system-overview-video'),
('blue-yonder-warehouse-execution','wes-material-flow-control','partially_supported',0.950,'Blue Yonder WES orchestrates automation and robotics, but direct PLC/WCS machine-control functionality is not inferred from the reviewed WES evidence.','https://blueyonder.com/solutions/warehouse-management/warehouse-execution'),
('blue-yonder-warehouse-execution','wes-visibility-exceptions','supported',0.980,'Blue Yonder WES dynamically adapts priorities and reassigns work during disruptions to protect service levels and throughput.','https://blueyonder.com/solutions/warehouse-management/warehouse-execution'),
('blue-yonder-warehouse-execution','wes-analytics-kpis','partially_supported',0.960,'Blue Yonder WES uses AI/ML and predictive task intelligence for execution optimization; a standalone WES analytics/KPI package is not inferred beyond the reviewed scope.','https://blueyonder.com/resources/warehouse-execution-system-overview-video');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat121_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat121_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party vendor documentation supporting this capability.'
FROM cat121_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Promote SaaS only where the product-specific vendor evidence is explicit.
INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.990
FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug IN('honeywell-momentum-wes','blue-yonder-warehouse-execution')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

-- Do not infer Android/iOS/mobile-web support from browser-based, operator-interface or device claims.
INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000
FROM products p CROSS JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') x
WHERE p.slug IN('honeywell-momentum-wes','fortna-wes','dematic-warehouse-execution-system','swisslog-synq','blue-yonder-warehouse-execution')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

COMMIT;
