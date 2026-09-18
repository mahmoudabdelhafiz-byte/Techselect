-- TechSelectAI Terminal Truck Appointment & Gate Management catalog expansion.
-- Adds one canonical category and five evidence-backed current products.
-- Official first-party evidence reviewed Sep 2026. Presence is not an endorsement.
-- Unknown != Unsupported. No Fit Score, recommendation ranking, review score, follower/community popularity or commercial placement logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('Terminal Truck Appointment & Gate Management','terminal-truck-appointment-gate-management','Specialized software for landside terminal appointment booking, capacity control, pre-arrival validation, driver self-service, TOS/PCS integration and automated gate processing across container, intermodal and logistics facilities.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @gate_cat=(SELECT id FROM categories WHERE slug='terminal-truck-appointment-gate-management' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@gate_cat,'Appointment & Landside Flow','terminal-appointment-flow','Truck timeslot booking, capacity rules, pre-arrival checks, driver self-service and multi-terminal/community coordination.',1),
(@gate_cat,'Gate Execution & Automation','terminal-gate-execution','TOS/PCS integration, OCR/RFID/kiosk automation, identity/access control, gate transaction handling and gate-performance visibility.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.sec,1
FROM modules m JOIN (
 SELECT 'terminal-appointment-flow' module_slug,'Truck appointment & timeslot booking' name,'gate-truck-appointment-booking' slug,'Allow carriers or terminal users to create, manage or review truck appointments and timeslots for container pickup, drop-off or other landside terminal moves.' description,0 sec UNION ALL
 SELECT 'terminal-appointment-flow','Capacity, quota & business-rule management','gate-capacity-rules','Configure appointment capacity, operating calendars, slot quotas, cutoff rules or other terminal-specific booking constraints.' description,0 UNION ALL
 SELECT 'terminal-appointment-flow','Pre-arrival readiness & transaction validation','gate-prearrival-validation','Validate container, cargo, vessel, customs, authorization or terminal-readiness conditions before truck arrival so failed transactions can be resolved earlier.' description,0 UNION ALL
 SELECT 'terminal-appointment-flow','Driver / carrier self-service interface','gate-driver-self-service','Provide carrier, driver or trucking-company self-service through web, mobile, kiosk or comparable interfaces for booking, check-in, status and transaction interaction.' description,0 UNION ALL
 SELECT 'terminal-appointment-flow','Multi-terminal / community coordination','gate-multiterminal-coordination','Support appointment or landside coordination across multiple terminals, depots or facilities within a port or logistics community where explicitly documented.' description,0 UNION ALL
 SELECT 'terminal-gate-execution','TOS, PCS & terminal-system integration','gate-terminal-integration','Exchange appointments, container status, transactions or gate events with terminal operating systems, port community systems, depot systems or other host platforms.' description,0 UNION ALL
 SELECT 'terminal-gate-execution','OCR, ALPR, RFID & kiosk gate automation','gate-automation-devices','Integrate truck/container OCR, ALPR/LPR, RFID, self-service kiosks, cameras, barriers, intercoms or comparable gate-automation devices.' description,0 UNION ALL
 SELECT 'terminal-gate-execution','Driver, vehicle & access identity controls','gate-identity-access','Validate driver, truck, load or access credentials and support secure terminal/gate authorization workflows where documented.' description,0 UNION ALL
 SELECT 'terminal-gate-execution','Gate transaction & exception handling','gate-transaction-exceptions','Execute and monitor in-gate/out-gate transactions, route exceptions, centralize clerk intervention or manage failed/abnormal gate workflows.' description,0 UNION ALL
 SELECT 'terminal-gate-execution','Truck turn-time, congestion & gate analytics','gate-analytics-turntime','Provide gate-performance metrics, turn-time or queue visibility, capacity utilization, bottleneck analysis or other landside/gate analytics.' description,0
) x ON x.module_slug=m.slug
WHERE m.category_id=@gate_cat
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('OneStop','onestop','https://www.1-stop.biz/','Port-community and terminal landside software vendor.','active'),
('Camco Technologies','camco-technologies','https://camco.be/','Terminal gate automation, OCR, vehicle-booking and operations software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat123_products;
CREATE TEMPORARY TABLE cat123_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO cat123_products VALUES
('onestop','terminal-truck-appointment-gate-management','OneStop Vehicle Booking System','onestop-vbs','Terminal-to-landside capacity-management system for carrier timeslot booking, configurable slot capacity and business rules, status visibility and TOS/depot-system integration.','https://www.1-stop.biz/operations/vehicle-booking-system/'),
('soget','terminal-truck-appointment-gate-management','SOGET Truck Appointment System','soget-tas','Web-based truck appointment system for carriers and terminal operators with real-time slot capacity, prerequisite checks, mobile access and terminal/security-system integration.','https://www.soget.fr/en/carriers-and-logisticians/'),
('kaleris','terminal-truck-appointment-gate-management','Kaleris Smart Access','kaleris-smart-access','Web-based landside access and visibility tool for trucking companies and logistics providers, providing container availability, vessel updates and terminal appointment scheduling.','https://kaleris.com/solutions/execution-visiblity-platform/'),
('camco-technologies','terminal-truck-appointment-gate-management','Camco Vehicle Booking System','camco-vehicle-booking-system','Terminal vehicle booking system for timeslot management, pre-registration and deep integration with TOS and Camco gate automation to reduce congestion and resolve transaction issues before truck arrival.','https://camco.be/vehicle-booking-system-vbs/'),
('tideworks-technology','terminal-truck-appointment-gate-management','Tideworks GateVision','tideworks-gatevision','Automated gate operating system integrating TOS transactions, self-service kiosks, camera/voice workflows and OCR/ALPR/RFID technologies for faster truck processing and centralized exception handling.','https://tideworks.com/gate-vision/');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat123_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS cat123_sources;
CREATE TEMPORARY TABLE cat123_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat123_sources VALUES
('onestop-vbs','https://www.1-stop.biz/operations/vehicle-booking-system/','OneStop Vehicle Booking System','OneStop'),
('onestop-vbs','https://www.1-stop.biz/solutions/','OneStop Port and Terminal Solutions','OneStop'),
('soget-tas','https://www.soget.fr/en/','SOGET Truck Appointment System','SOGET'),
('soget-tas','https://www.soget.fr/en/carriers-and-logisticians/','SOGET TAS for Carriers and Logisticians','SOGET'),
('soget-tas','https://www.soget.fr/sone-jamaique-les-rdv-transporteurs-100-operationnels/','SOGET TAS Jamaica Deployment','SOGET'),
('kaleris-smart-access','https://kaleris.com/solutions/execution-visiblity-platform/','Kaleris Smart Access','Kaleris'),
('kaleris-smart-access','https://kaleris.com/enhancing-supply-chain-efficiency-with-kaleris-execution-and-visibility-platform/','Kaleris Execution and Visibility Platform - Smart Access','Kaleris'),
('kaleris-smart-access','https://kaleris.com/case-study/2022-inspire-award-winner-peel-ports-group/','Peel Ports SmartAccess Truck Appointment Case Study','Kaleris'),
('camco-vehicle-booking-system','https://camco.be/vehicle-booking-system-vbs/','Camco Vehicle Booking System','Camco Technologies'),
('camco-vehicle-booking-system','https://camco.be/gate-operating-system-gos/','Camco Gate Operating System','Camco Technologies'),
('camco-vehicle-booking-system','https://camco.be/container-terminals/','Camco Container Terminal Gate Automation','Camco Technologies'),
('tideworks-gatevision','https://tideworks.com/gate-vision/','Tideworks GateVision','Tideworks Technology'),
('tideworks-gatevision','https://tideworks.com/pomtoc-accelerates-terminal-modernization-to-support-regional-trade-growth-with-tideworks-cloud-tos/','Tideworks GateVision Current POMTOC Deployment','Tideworks Technology');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM cat123_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS cat123_facts;
CREATE TEMPORARY TABLE cat123_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat123_facts VALUES
-- OneStop VBS
('onestop-vbs','gate-truck-appointment-booking','supported',0.990,'OneStop VBS is explicitly a web-based booking system for carrier timeslots to pick up and drop off containers at terminals and depots.','https://www.1-stop.biz/operations/vehicle-booking-system/'),
('onestop-vbs','gate-capacity-rules','supported',0.990,'OneStop VBS lets facilities control offered slots using capacity, operational needs, configurable business rules and calendar templates.','https://www.1-stop.biz/operations/vehicle-booking-system/'),
('onestop-vbs','gate-prearrival-validation','partially_supported',0.950,'OneStop VBS exposes import availability and terminal-fed status used by carriers before arrival, but a universal customs/readiness validation engine is not inferred.','https://www.1-stop.biz/operations/vehicle-booking-system/'),
('onestop-vbs','gate-driver-self-service','supported',0.980,'Carriers can log in to create bookings and drivers can manage and view drop-off/pick-up status through the VBS interface.','https://www.1-stop.biz/operations/vehicle-booking-system/'),
('onestop-vbs','gate-multiterminal-coordination','supported',0.980,'OneStop documents VBS use across dozens of terminals and depots and positions it as a common terminal-to-landside interface across port communities.','https://www.1-stop.biz/operations/vehicle-booking-system/'),
('onestop-vbs','gate-terminal-integration','supported',0.990,'OneStop explicitly documents TOS and park-management-system integration.','https://www.1-stop.biz/operations/vehicle-booking-system/'),
('onestop-vbs','gate-transaction-exceptions','partially_supported',0.950,'OneStop provides booking status and operational notifications, but a dedicated real-time gate exception engine is not inferred from the reviewed VBS evidence.','https://www.1-stop.biz/operations/vehicle-booking-system/'),

-- SOGET TAS
('soget-tas','gate-truck-appointment-booking','supported',0.990,'SOGET TAS is explicitly an online truck appointment system for carrier drop-off and pickup appointments at port or airport terminals.','https://www.soget.fr/en/carriers-and-logisticians/'),
('soget-tas','gate-capacity-rules','supported',0.990,'Terminals can configure appointment slots according to business hours and real-time reception capacity; Jamaica deployments also configure capacities by import/export and full/empty flows.','https://www.soget.fr/sone-jamaique-les-rdv-transporteurs-100-operationnels/'),
('soget-tas','gate-prearrival-validation','supported',0.990,'SOGET TAS only authorizes appointments when required S ONE conditions such as customs clearance, vessel arrival and valid transport authorization are known.','https://www.soget.fr/en/carriers-and-logisticians/'),
('soget-tas','gate-driver-self-service','supported',0.990,'SOGET TAS is web-based and documented as accessible on mobile platforms including smartphones and tablets.','https://www.soget.fr/en/carriers-and-logisticians/'),
('soget-tas','gate-multiterminal-coordination','supported',0.990,'SOGET documents one community appointment system across all Jamaican port terminals.','https://www.soget.fr/sone-jamaique-les-rdv-transporteurs-100-operationnels/'),
('soget-tas','gate-terminal-integration','supported',0.990,'SOGET TAS is interfaceable with terminal internal systems and port-security services and uses S ONE status data.','https://www.soget.fr/en/carriers-and-logisticians/'),
('soget-tas','gate-identity-access','supported',0.990,'SOGET TAS can generate identification codes by truck/driver and load and supports ISPS-oriented access-security workflows.','https://www.soget.fr/en/carriers-and-logisticians/'),

-- Kaleris Smart Access
('kaleris-smart-access','gate-truck-appointment-booking','supported',0.990,'Smart Access explicitly provides terminal appointment scheduling for trucking companies, logistics providers and cargo owners.','https://kaleris.com/solutions/execution-visiblity-platform/'),
('kaleris-smart-access','gate-prearrival-validation','partially_supported',0.970,'Smart Access provides real-time container availability and vessel updates that support pre-arrival decisions, but the reviewed evidence does not establish a universal rules-based readiness validator.','https://kaleris.com/solutions/execution-visiblity-platform/'),
('kaleris-smart-access','gate-driver-self-service','supported',0.990,'Kaleris documents Smart Access as a web-based tool; Peel Ports users can create, manage and review appointments via mobile app or web portal.','https://kaleris.com/case-study/2022-inspire-award-winner-peel-ports-group/'),
('kaleris-smart-access','gate-terminal-integration','partially_supported',0.960,'Smart Access is part of Kaleris terminal execution/visibility workflows and consumes live terminal asset information, but a universal interface catalogue is not inferred.','https://kaleris.com/solutions/execution-visiblity-platform/'),
('kaleris-smart-access','gate-analytics-turntime','partially_supported',0.950,'Kaleris positions Smart Access as reducing non-productive moves and improving landside coordination; dedicated gate-performance analytics belong to broader Kaleris analytics tooling and are not assumed core.','https://kaleris.com/enhancing-supply-chain-efficiency-with-kaleris-execution-and-visibility-platform/'),

-- Camco VBS
('camco-vehicle-booking-system','gate-truck-appointment-booking','supported',0.990,'Camco VBS is explicitly designed for truck appointment and terminal time-slot management.','https://camco.be/vehicle-booking-system-vbs/'),
('camco-vehicle-booking-system','gate-capacity-rules','supported',0.980,'Camco documents tailored booking logic and terminal-specific time-slot rules rather than a one-size-fits-all booking model.','https://camco.be/vehicle-booking-system-vbs/'),
('camco-vehicle-booking-system','gate-prearrival-validation','supported',0.990,'Camco documents deep TOS/GOS integration that resolves transaction issues before the truck arrives.','https://camco.be/vehicle-booking-system-vbs/'),
('camco-vehicle-booking-system','gate-driver-self-service','supported',0.980,'Camco documents a truck app and complementary mobile application for pre-registration, pickup/drop-off and appointment workflows.','https://camco.be/container-terminals/'),
('camco-vehicle-booking-system','gate-terminal-integration','supported',0.990,'Camco VBS is tightly integrated with the TOS and Camco Gate Operating System.','https://camco.be/vehicle-booking-system-vbs/'),
('camco-vehicle-booking-system','gate-automation-devices','partially_supported',0.980,'Camco VBS integrates with GOS, while OCR portals, kiosks, barriers, access control and other device control belong to the broader Camco gate-automation/GOS layer.','https://camco.be/gate-operating-system-gos/'),
('camco-vehicle-booking-system','gate-identity-access','partially_supported',0.960,'Camco GOS integrates access control and terminal security processes; these are treated as connected gate-layer capabilities rather than universally native VBS entitlement.','https://camco.be/gate-operating-system-gos/'),
('camco-vehicle-booking-system','gate-transaction-exceptions','partially_supported',0.970,'Camco GOS provides real-time gate process monitoring and exception-oriented gate control; this remains a companion gate-layer capability to VBS.','https://camco.be/gate-operating-system-gos/'),

-- Tideworks GateVision
('tideworks-gatevision','gate-driver-self-service','supported',0.990,'GateVision provides self-service driver kiosks with touch/display, ticketing and two-way communication options.','https://tideworks.com/gate-vision/'),
('tideworks-gatevision','gate-terminal-integration','supported',0.990,'GateVision integrates the gate transaction directly with the terminal operating system.','https://tideworks.com/gate-vision/'),
('tideworks-gatevision','gate-automation-devices','supported',0.990,'GateVision explicitly supports integration with OCR, ALPR/LPR, RFID, cameras and configurable kiosk I/O devices.','https://tideworks.com/gate-vision/'),
('tideworks-gatevision','gate-transaction-exceptions','supported',0.990,'GateVision centralizes clerk interaction, lane calls and transaction processing so terminals can handle gate activity and exceptions outside the lanes.','https://tideworks.com/gate-vision/'),
('tideworks-gatevision','gate-analytics-turntime','partially_supported',0.950,'Tideworks documents faster processing and reduced truck turn times, but a dedicated GateVision analytics/KPI package is not established by the reviewed product evidence.','https://tideworks.com/gate-vision/');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat123_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat123_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party vendor documentation supporting this capability.'
FROM cat123_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Deployment remains not_yet_verified in this batch.
-- Web-based, cloud-hosted or Azure-hosted does not automatically define the commercial deployment model.
INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000
FROM products p CROSS JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') x
WHERE p.slug IN('onestop-vbs','soget-tas','kaleris-smart-access','camco-vehicle-booking-system','tideworks-gatevision')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

COMMIT;
