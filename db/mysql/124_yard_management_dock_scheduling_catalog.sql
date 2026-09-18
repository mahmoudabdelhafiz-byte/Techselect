-- TechSelectAI Yard Management & Dock Scheduling catalog expansion.
-- Adds one canonical YMS/dock category and five evidence-backed current products.
-- Official first-party evidence reviewed Sep 2026. Presence is not an endorsement.
-- Unknown != Unsupported. No Fit Score, recommendation ranking, review score, follower/community popularity or commercial placement logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('Yard Management & Dock Scheduling Systems','yard-management-dock-scheduling','Specialized software for managing trailer, container and vehicle flow across warehouse, distribution-center, manufacturing and logistics yards, including gate operations, yard visibility, move tasking, dock scheduling, dwell control, integrations and performance analytics.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @yms_cat=(SELECT id FROM categories WHERE slug='yard-management-dock-scheduling' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@yms_cat,'Gate, Yard & Dock Execution','yms-yard-execution','Gate check-in/out, trailer and asset visibility, yard move tasking, dock-door scheduling and driver/carrier self-service.',1),
(@yms_cat,'Optimization, Integration & Visibility','yms-optimization-integration','Dwell/detention control, WMS/TMS/ERP integration, RTLS/camera/IoT automation, analytics and multi-site yard governance.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.sec,1
FROM modules m JOIN (
 SELECT 'yms-yard-execution' module_slug,'Gate check-in, check-out & pre-arrival processing' name,'yms-gate-checkin' slug,'Digitize vehicle/trailer arrival and departure, pre-arrival details, gate validation, gate passes or comparable yard-entry workflows.' description,0 sec UNION ALL
 SELECT 'yms-yard-execution','Trailer, container & yard-asset visibility','yms-asset-visibility','Maintain real-time or near-real-time location, status, inventory and lifecycle visibility for trailers, containers, tractors, loads or other yard assets.',0 UNION ALL
 SELECT 'yms-yard-execution','Yard move, spotter & jockey task optimization','yms-yard-move-tasking','Create, prioritize, assign, sequence and track yard moves or spotter/jockey tasks to position assets efficiently.',0 UNION ALL
 SELECT 'yms-yard-execution','Dock-door appointment & scheduling management','yms-dock-scheduling','Schedule inbound/outbound appointments, manage dock-door capacity and coordinate trailers, loads and doors through configurable scheduling workflows.',0 UNION ALL
 SELECT 'yms-yard-execution','Driver & carrier self-service','yms-driver-carrier-selfservice','Allow drivers, carriers or suppliers to check in, schedule appointments, receive instructions, provide status or interact with yard/dock workflows through self-service interfaces.',0 UNION ALL
 SELECT 'yms-optimization-integration','Dwell, detention & turnaround management','yms-dwell-detention','Track dwell, waiting, detention, turnaround or accessorial-fee exposure and use alerts or workflows to reduce avoidable delays and costs.',0 UNION ALL
 SELECT 'yms-optimization-integration','WMS, TMS, ERP & host-system integration','yms-host-integration','Exchange orders, shipments, appointments, inventory, status or execution data with warehouse, transportation, ERP or other host systems through supported interfaces or APIs.',0 UNION ALL
 SELECT 'yms-optimization-integration','RTLS, camera vision, IoT & gate automation','yms-rtls-automation','Use real-time location systems, camera/computer vision, IoT sensors, kiosks or comparable automation to improve asset identification, location accuracy and gate/yard execution.',0 UNION ALL
 SELECT 'yms-optimization-integration','Yard analytics, KPIs & exception visibility','yms-analytics-kpis','Provide dashboards, alerts, operational KPIs, congestion/bottleneck visibility, dwell analysis, utilization or other yard-performance analytics.',0 UNION ALL
 SELECT 'yms-optimization-integration','Multi-site & enterprise yard visibility','yms-multisite-enterprise','Provide cross-site yard visibility, common configuration, reporting or governance across multiple facilities or yard networks where explicitly documented.',0
) x ON x.module_slug=m.slug
WHERE m.category_id=@yms_cat
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Kaleris','kaleris','https://kaleris.com/','Supply-chain execution, yard, terminal and transportation software vendor.','active'),
('Manhattan Associates','manhattan-associates','https://www.manh.com/','Supply-chain commerce, warehouse, transportation and yard-management software vendor.','active'),
('Blue Yonder','blue-yonder','https://blueyonder.com/','Supply-chain planning, warehouse, execution and yard-management software vendor.','active'),
('C3 Solutions','c3-solutions','https://www.c3solutions.com/','Yard management, dock scheduling and supply-chain collaboration software vendor.','active'),
('Goramp','goramp','https://www.goramp.com/','Yard, gate, dock scheduling and logistics operations software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat124_products;
CREATE TEMPORARY TABLE cat124_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO cat124_products VALUES
('kaleris','yard-management-dock-scheduling','Kaleris Yard Management System','kaleris-yms','Enterprise yard management system for gate, dock and asset management with RTLS/IoT visibility, automated tasking, appointment scheduling, dwell/accessorial tracking, analytics and host-system integration.','https://kaleris.com/solutions/yard-management/'),
('manhattan-associates','yard-management-dock-scheduling','Manhattan Yard Management','manhattan-yard-management','AI-driven yard-management capability within ActiveWarehouse that unifies yard, dock, warehouse and transportation execution with trailer/door visibility, yard-move optimization and dock scheduling.','https://www.manh.com/solutions/supply-chain-management-software/yard-management'),
('blue-yonder','yard-management-dock-scheduling','Blue Yonder Yard Management','blue-yonder-yard-management','Yard-management capability with dock scheduling, automated gate checks, camera-vision yard mapping, trailer status, carrier/driver portal access and detention-focused operational visibility.','https://blueyonder.com/solutions/warehouse-management/yard-management'),
('c3-solutions','yard-management-dock-scheduling','C3 Yard','c3-yard','SaaS yard-management system for gate operations, real-time trailer visibility, automated shunter tasks, dock management, dwell control, multi-site visibility, APIs and mobile yard execution.','https://www.c3solutions.com/yard-management/'),
('goramp','yard-management-dock-scheduling','Goramp Yard Management','goramp-yard-management','Yard control platform for real-time trailer tracking, gate check-in/out, automated yard moves, dock coordination, dwell/detention visibility, driver self-service and connected logistics workflows.','https://www.goramp.com/yard-management-software');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat124_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS cat124_sources;
CREATE TEMPORARY TABLE cat124_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat124_sources VALUES
('kaleris-yms','https://kaleris.com/solutions/yard-management/','Kaleris Yard Management','Kaleris'),
('kaleris-yms','https://kaleris.com/company/about/','Kaleris Yard Management Overview','Kaleris'),
('manhattan-yard-management','https://www.manh.com/solutions/supply-chain-management-software/yard-management','Manhattan Yard Management','Manhattan Associates'),
('manhattan-yard-management','https://www.manh.com/solutions/supply-chain-management-software/activewarehouse','Manhattan ActiveWarehouse Yard Management','Manhattan Associates'),
('manhattan-yard-management','https://www.manh.com/our-insights/resources/articles/what-is-yard-management','Manhattan Yard Management Capabilities','Manhattan Associates'),
('blue-yonder-yard-management','https://blueyonder.com/solutions/warehouse-management/yard-management','Blue Yonder Yard Management','Blue Yonder'),
('blue-yonder-yard-management','https://blueyonder.com/solutions/warehouse-management','Blue Yonder Warehouse Management Platform','Blue Yonder'),
('c3-yard','https://www.c3solutions.com/yard-management/','C3 Yard Management System','C3 Solutions'),
('c3-yard','https://www.c3solutions.com/yard-management/tour/','C3 Yard Product Tour','C3 Solutions'),
('c3-yard','https://www.c3solutions.com/yard-management/faq/','C3 Yard FAQ','C3 Solutions'),
('c3-yard','https://www.c3solutions.com/c3-yard-and-dock/','C3 Yard and Dock Scheduling','C3 Solutions'),
('goramp-yard-management','https://www.goramp.com/yard-management-software','Goramp Yard Management Software','Goramp'),
('goramp-yard-management','https://www.goramp.com/solutions/yard-operator-software','Goramp Yard Operator Software','Goramp'),
('goramp-yard-management','https://www.goramp.com/solutions/gate-management-software','Goramp Gate Management','Goramp'),
('goramp-yard-management','https://www.goramp.com/solutions/warehouse-dock-scheduling-software','Goramp Dock Scheduling','Goramp');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM cat124_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS cat124_facts;
CREATE TEMPORARY TABLE cat124_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat124_facts VALUES
-- Kaleris YMS
('kaleris-yms','yms-gate-checkin','supported',0.990,'Kaleris YMS documents configurable check-in/check-out, multilingual driver kiosks and automated gate workflows.','https://kaleris.com/solutions/yard-management/'),
('kaleris-yms','yms-asset-visibility','supported',0.990,'Kaleris documents real-time asset inventory, location, status, dwell and cross-yard visibility.','https://kaleris.com/solutions/yard-management/'),
('kaleris-yms','yms-yard-move-tasking','supported',0.990,'Kaleris YMS supports automated task assignment, spotter management and prioritized trailer-move workflows.','https://kaleris.com/solutions/yard-management/'),
('kaleris-yms','yms-dock-scheduling','supported',0.990,'Kaleris explicitly documents automated dock management and self-scheduled inbound/outbound appointments.','https://kaleris.com/solutions/yard-management/'),
('kaleris-yms','yms-driver-carrier-selfservice','supported',0.980,'Kaleris documents driver kiosks plus self-scheduling for yard managers, warehouse teams, carriers and suppliers.','https://kaleris.com/solutions/yard-management/'),
('kaleris-yms','yms-dwell-detention','supported',0.990,'Kaleris tracks asset dwell and accessorial/detention exposure using configurable free-time and fee profiles.','https://kaleris.com/solutions/yard-management/'),
('kaleris-yms','yms-host-integration','supported',0.990,'Kaleris documents seamless WMS, TMS and ERP integration plus web APIs and data streaming.','https://kaleris.com/solutions/yard-management/'),
('kaleris-yms','yms-rtls-automation','supported',0.990,'Kaleris documents RTLS, IoT, automated gate check-in and event-based automation for yard execution.','https://kaleris.com/solutions/yard-management/'),
('kaleris-yms','yms-analytics-kpis','supported',0.990,'Kaleris provides real-time dashboards, KPIs, alerts, task reports and configurable yard analytics.','https://kaleris.com/solutions/yard-management/'),
('kaleris-yms','yms-multisite-enterprise','supported',0.990,'Kaleris documents cross-network dashboards and asset visibility across multiple yard locations.','https://kaleris.com/solutions/yard-management/'),

-- Manhattan Yard Management
('manhattan-yard-management','yms-gate-checkin','supported',0.980,'Manhattan documents trailer, driver and mobile check-in/check-out workflows, with or without an appointment.','https://www.manh.com/our-insights/resources/articles/what-is-yard-management'),
('manhattan-yard-management','yms-asset-visibility','supported',0.990,'Manhattan Yard Management provides graphical dock/yard visibility with trailer locations, pending arrivals and trailer contents.','https://www.manh.com/solutions/supply-chain-management-software/yard-management'),
('manhattan-yard-management','yms-yard-move-tasking','supported',0.990,'Manhattan documents optimal yard moves, advanced trailer selection and assignment to dock doors.','https://www.manh.com/solutions/supply-chain-management-software/yard-management'),
('manhattan-yard-management','yms-dock-scheduling','supported',0.990,'Manhattan documents dock-door scheduling and makes appointments, trailers and moves visible alongside warehouse work.','https://www.manh.com/solutions/supply-chain-management-software/activewarehouse'),
('manhattan-yard-management','yms-driver-carrier-selfservice','partially_supported',0.950,'Driver/mobile check-in and trailer check-in/out are documented, but a broad external carrier self-service portal is not inferred from the reviewed evidence.','https://www.manh.com/our-insights/resources/articles/what-is-yard-management'),
('manhattan-yard-management','yms-dwell-detention','partially_supported',0.960,'Manhattan explicitly positions Yard Management to reduce dwell and synchronize appointments, trailers and doors, but a dedicated detention/accessorial fee-management module is not inferred.','https://www.manh.com/solutions/supply-chain-management-software/activewarehouse'),
('manhattan-yard-management','yms-host-integration','supported',0.980,'Yard Management is unified with Manhattan Warehouse and Transportation Management on ActivePlatform; third-party host interfaces are not assumed beyond documented platform connectivity.','https://www.manh.com/solutions/supply-chain-management-software/yard-management'),
('manhattan-yard-management','yms-analytics-kpis','partially_supported',0.960,'Manhattan provides real-time yard/dock insights and visibility, while a standalone yard-analytics package is not inferred from the reviewed evidence.','https://www.manh.com/solutions/supply-chain-management-software/yard-management'),

-- Blue Yonder Yard Management
('blue-yonder-yard-management','yms-gate-checkin','supported',0.990,'Blue Yonder documents automated gate checks using camera vision and time-stamped trailer entry/exit images.','https://blueyonder.com/solutions/warehouse-management/yard-management'),
('blue-yonder-yard-management','yms-asset-visibility','supported',0.990,'Blue Yonder provides real-time yard mapping and trailer/location visibility across the yard and docks.','https://blueyonder.com/solutions/warehouse-management/yard-management'),
('blue-yonder-yard-management','yms-dock-scheduling','supported',0.990,'Blue Yonder explicitly describes Yard Management as a YMS with dock scheduling and real-time visibility.','https://blueyonder.com/solutions/warehouse-management/yard-management'),
('blue-yonder-yard-management','yms-driver-carrier-selfservice','supported',0.990,'Blue Yonder documents a yard-management portal for drivers and carriers through the Blue Yonder Network.','https://blueyonder.com/solutions/warehouse-management/yard-management'),
('blue-yonder-yard-management','yms-dwell-detention','supported',0.980,'Blue Yonder documents reduction of detention fees plus alerts around trailer location, detention and unknown trailer/load status.','https://blueyonder.com/solutions/warehouse-management/yard-management'),
('blue-yonder-yard-management','yms-host-integration','partially_supported',0.960,'Yard Management is part of Blue Yonder Warehouse Management and documents seamless software/hardware integration, but a universal external WMS/TMS/ERP interface catalogue is not inferred.','https://blueyonder.com/solutions/warehouse-management/yard-management'),
('blue-yonder-yard-management','yms-rtls-automation','supported',0.990,'Blue Yonder explicitly uses camera vision, machine learning and mobile-unit cameras for automated identification and real-time yard mapping.','https://blueyonder.com/solutions/warehouse-management/yard-management'),
('blue-yonder-yard-management','yms-analytics-kpis','partially_supported',0.960,'Blue Yonder documents alerts, throughput/utilization improvements and ML-driven visibility, but a separate yard-KPI analytics package is not inferred from the reviewed page.','https://blueyonder.com/solutions/warehouse-management/yard-management'),

-- C3 Yard
('c3-yard','yms-gate-checkin','supported',0.990,'C3 Yard streamlines gate check-in using pre-arrival details, gate passes and digital gate workflows.','https://www.c3solutions.com/yard-management/tour/'),
('c3-yard','yms-asset-visibility','supported',0.990,'C3 Yard provides real-time visibility of trailers, tractors, parking locations, gate activity and yard inventory.','https://www.c3solutions.com/yard-management/'),
('c3-yard','yms-yard-move-tasking','supported',0.990,'C3 Yard automatically assigns and optimizes shunter/yard-driver tasks based on business rules and priorities.','https://www.c3solutions.com/yard-management/tour/'),
('c3-yard','yms-dock-scheduling','partially_supported',0.990,'C3 dock scheduling is provided by the companion C3 Reservations product; C3 Yard and C3 Reservations can be combined but are distinct products.','https://www.c3solutions.com/c3-yard-and-dock/'),
('c3-yard','yms-driver-carrier-selfservice','partially_supported',0.980,'Driver self-check-in and carrier collaboration are delivered through the connected C3 Hive/C3 Reservations experience rather than assumed as core C3 Yard entitlement.','https://www.c3solutions.com/c3-yard-and-dock/'),
('c3-yard','yms-dwell-detention','supported',0.990,'C3 Yard tracks trailer dwell, timestamps and availability and is designed to reduce detention and wait costs.','https://www.c3solutions.com/yard-management/tour/'),
('c3-yard','yms-host-integration','supported',0.990,'C3 Yard supports inbound/outbound web services plus XML/flat-file SFTP integration with external business systems.','https://www.c3solutions.com/yard-management/faq/'),
('c3-yard','yms-rtls-automation','partially_supported',0.950,'C3 offers Vision AI gate automation and connected visibility services, but a universal native RTLS/camera package is not inferred as core C3 Yard.','https://www.c3solutions.com/c3-yard-and-dock/'),
('c3-yard','yms-analytics-kpis','supported',0.990,'C3 Yard provides flexible reports, real-time visibility, door-turn reporting and operational performance measurement.','https://www.c3solutions.com/yard-management/tour/'),
('c3-yard','yms-multisite-enterprise','supported',0.990,'C3 Yard documents enterprise visibility across multiple sites and fleet-wide trailer-pool reporting.','https://www.c3solutions.com/yard-management/'),

-- Goramp Yard Management
('goramp-yard-management','yms-gate-checkin','supported',0.990,'Goramp automates driver check-in/check-out and provides live gate tracking across yard workflows.','https://www.goramp.com/yard-management-software'),
('goramp-yard-management','yms-asset-visibility','supported',0.990,'Goramp provides a live digital yard map with trailer, truck, dock-door and asset status/location visibility.','https://www.goramp.com/yard-management-software'),
('goramp-yard-management','yms-yard-move-tasking','supported',0.990,'Goramp supports automated yard workflows, driver task automation and prioritized/sequenced yard moves.','https://www.goramp.com/solutions/yard-operator-software'),
('goramp-yard-management','yms-dock-scheduling','partially_supported',0.980,'Goramp Yard Management integrates with the platform’s dedicated Dock Scheduling/Time Slot Management solution; packaging should be validated rather than assuming universal entitlement.','https://www.goramp.com/solutions/warehouse-dock-scheduling-software'),
('goramp-yard-management','yms-driver-carrier-selfservice','supported',0.990,'Goramp documents driver self check-in, carrier/driver messaging and appointment interaction across its yard platform.','https://www.goramp.com/yard-management-software'),
('goramp-yard-management','yms-dwell-detention','supported',0.990,'Goramp tracks dwell, truck turnaround, dock utilization, waiting and detention exposure through yard dashboards and alerts.','https://www.goramp.com/solutions/yard-operator-software'),
('goramp-yard-management','yms-host-integration','supported',0.980,'Goramp documents system integrations and connectivity with WMS, TMS and YMS environments.','https://www.goramp.com/solutions/warehouse-dock-scheduling-software'),
('goramp-yard-management','yms-analytics-kpis','supported',0.990,'Goramp exposes dwell time, turnaround, gate wait, dock utilization, on-time departures and detention KPIs plus alerts and dashboards.','https://www.goramp.com/solutions/yard-operator-software');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat124_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat124_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party vendor documentation supporting this capability.'
FROM cat124_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Promote deployment only where current product-specific evidence is explicit.
INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.990
FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug='c3-yard'
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

-- Default platform-specific mobile evidence to unknown.
INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000
FROM products p CROSS JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') x
WHERE p.slug IN('kaleris-yms','manhattan-yard-management','blue-yonder-yard-management','c3-yard','goramp-yard-management')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

-- C3 explicitly documents its Progressive Web Application as available from mobile browsers.
INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,'mobile_web','supported','supported','vendor_documentation',0.990
FROM products p WHERE p.slug='c3-yard'
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

COMMIT;
