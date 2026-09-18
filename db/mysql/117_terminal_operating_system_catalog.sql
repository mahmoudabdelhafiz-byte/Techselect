-- TechSelectAI Terminal Operating Systems catalog expansion.
-- Adds one canonical TOS category and five evidence-backed current products.
-- Official first-party evidence reviewed Sep 2026. Presence is not an endorsement.
-- Unknown != Unsupported. No Fit Score, recommendation ranking, review score, follower/community popularity or commercial placement logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('Terminal Operating Systems (TOS)','terminal-operating-systems','Specialized software for planning, controlling and optimizing marine and inland terminal operations across vessel, yard, gate, rail, equipment, automation, integration and operational visibility.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @tos_cat=(SELECT id FROM categories WHERE slug='terminal-operating-systems' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@tos_cat,'Terminal Planning & Execution','tos-planning-execution','Vessel and berth planning, yard operations, gate, rail and equipment execution across container-terminal workflows.',1),
(@tos_cat,'Automation, Integration & Business Control','tos-automation-integration','Automation/ECS integration, EDI and APIs, real-time visibility, billing/financial connectivity and specialized cargo controls.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.sec,1
FROM modules m JOIN (
 SELECT 'tos-planning-execution' module_slug,'Vessel & berth planning / execution' name,'tos-vessel-berth-planning' slug,'Plan and execute vessel calls, berth allocation, stowage or quay work using terminal-operational data.' description,0 sec UNION ALL
 SELECT 'tos-planning-execution','Yard planning & container inventory','tos-yard-planning-inventory','Plan yard allocation and maintain operational visibility of container locations, stacks, moves and inventory.',0 UNION ALL
 SELECT 'tos-planning-execution','Gate & truck operations','tos-gate-truck-operations','Manage terminal gate transactions, truck processing, interchange and related landside workflows.',0 UNION ALL
 SELECT 'tos-planning-execution','Rail / intermodal operations','tos-rail-operations','Plan or execute rail and intermodal container movements within supported terminal operations.',0 UNION ALL
 SELECT 'tos-planning-execution','Equipment dispatch & control','tos-equipment-dispatch-control','Assign, dispatch, monitor or optimize work for terminal tractors, straddle carriers, quay cranes, RTGs, RMGs or other handling equipment.',0 UNION ALL
 SELECT 'tos-automation-integration','Terminal automation / ECS integration','tos-automation-ecs','Integrate terminal plans and work instructions with automated or semi-automated equipment control and execution systems.',0 UNION ALL
 SELECT 'tos-automation-integration','EDI, APIs & external-system integration','tos-edi-api-integrations','Exchange operational data with carriers, port authorities, customs, gate systems, financial systems or other applications through EDI, APIs or other interfaces.',0 UNION ALL
 SELECT 'tos-automation-integration','Operational visibility, analytics & KPIs','tos-kpi-visibility','Provide real-time operational visibility, dashboards, simulation, productivity metrics, KPIs or decision-support analytics.',0 UNION ALL
 SELECT 'tos-automation-integration','Billing / tariff / financial integration','tos-billing-financial','Capture billable terminal events, calculate tariffs/invoices, or integrate operational events with finance and billing systems.',0 UNION ALL
 SELECT 'tos-automation-integration','Reefer, dangerous goods & special cargo controls','tos-special-cargo-controls','Support terminal handling workflows for reefers, dangerous goods, out-of-gauge or other specialized container/cargo requirements where explicitly documented.',0
) x ON x.module_slug=m.slug
WHERE m.category_id=@tos_cat
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Kaleris','kaleris','https://kaleris.com/','Supply-chain execution and terminal operating software vendor.','active'),
('Tideworks Technology','tideworks-technology','https://tideworks.com/','Marine and intermodal terminal operating software vendor.','active'),
('Realtime Business Solutions','realtime-business-solutions','https://rbs-tops.com/','Terminal operating systems and container-handling software vendor.','active'),
('CyberLogitec','cyberlogitec','https://www.cyberlogitec.com/','Maritime, port and logistics software vendor.','active'),
('Total Soft Bank','total-soft-bank','https://www.tsb.co.kr/','Maritime and logistics software vendor for terminal and vessel operations.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat117_products;
CREATE TEMPORARY TABLE cat117_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO cat117_products VALUES
('kaleris','terminal-operating-systems','Kaleris N4 TOS','kaleris-n4-tos','Enterprise terminal operating system for container terminals with vessel and yard planning, gate workflows, equipment optimization, automation integration, EDI/API connectivity, operational visibility and billing capabilities.','https://kaleris.com/solutions/terminal-operating-system/container-terminals/'),
('tideworks-technology','terminal-operating-systems','Tideworks Mainsail','tideworks-mainsail','Marine terminal operating system for cargo, inventory, vessel activity and gate operations, supported by Tideworks planning, equipment-control, customer-visibility and EDI companion products where selected.','https://tideworks.com/mainsail/'),
('realtime-business-solutions','terminal-operating-systems','RBS TOPS Expert','rbs-tops-expert','Terminal operating system family for real-time container-terminal planning and execution across vessel, berth, yard, gate, rail, equipment, automation and operational analytics.','https://rbs-tops.com/terminal-operating-system/tops-terminal-solution/tops-expert-enterprise/'),
('cyberlogitec','terminal-operating-systems','CyberLogitec OPUS Terminal','cyberlogitec-opus-terminal','Integrated container terminal operating system for berth, vessel, yard, gate, rail and equipment operations with optimization and semi-to-fully automated terminal support.','https://www.cyberlogitec.com/en/sub/solution/port/opus_terminal.php'),
('total-soft-bank','terminal-operating-systems','Total Soft Bank CATOS','total-soft-bank-catos','Container terminal operating system for berth, ship, rail, gate and yard planning with equipment supervision, optimization, EDI connectivity and operational analytics.','https://www.tsb.co.kr/CATOS');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat117_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS cat117_sources;
CREATE TEMPORARY TABLE cat117_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat117_sources VALUES
('kaleris-n4-tos','https://kaleris.com/solutions/terminal-operating-system/','Kaleris Terminal Operating Systems','Kaleris'),
('kaleris-n4-tos','https://kaleris.com/solutions/terminal-operating-system/container-terminals/','Kaleris N4 for Container Terminals','Kaleris'),
('kaleris-n4-tos','https://kaleris.com/what-is-a-terminal-operating-system/','Kaleris: What Is a Terminal Operating System','Kaleris'),
('tideworks-mainsail','https://tideworks.com/mainsail/','Tideworks Mainsail','Tideworks Technology'),
('tideworks-mainsail','https://tideworks.com/pomtoc-modernizes-terminal-operations-with-cloud-based-tos-mainsail-10/','POMTOC Modernizes with Mainsail 10','Tideworks Technology'),
('tideworks-mainsail','https://tideworks.com/oregons-only-international-container-terminal-relaunches-with-tideworks-technology/','Oregon Container Terminal Relaunch','Tideworks Technology'),
('tideworks-mainsail','https://tideworks.com/traffic-control/','Tideworks Traffic Control','Tideworks Technology'),
('realtime-business-solutions','https://rbs-tops.com/terminal-operating-system/tops-terminal-solution/tops-expert-enterprise/','RBS TOPS Expert Enterprise','Realtime Business Solutions'),
('rbs-tops-expert','https://rbs-tops.com/terminal-operating-system/topo-expert-2/','RBS TOPO Expert','Realtime Business Solutions'),
('rbs-tops-expert','https://www.rbs-emea.com/products/tops-expert-cloud','RBS TOPS Expert Cloud','Realtime Business Solutions'),
('rbs-tops-expert','https://www.rbs-emea.com/','RBS EMEA Terminal Operating Systems','Realtime Business Solutions'),
('cyberlogitec-opus-terminal','https://www.cyberlogitec.com/en/sub/solution/port/opus_terminal.php','CyberLogitec OPUS Terminal','CyberLogitec'),
('cyberlogitec-opus-terminal','https://www.cyberlogitec.com/en/sub/insight/press_view.php?idx=182','CyberLogitec Incheon Automated Terminal Contract','CyberLogitec'),
('cyberlogitec-opus-terminal','https://www.cyberlogitec.com/en/sub/insight/press_view.php?idx=162','CyberLogitec Automated Terminal Operations','CyberLogitec'),
('total-soft-bank-catos','https://www.tsb.co.kr/','Total Soft Bank','Total Soft Bank'),
('total-soft-bank-catos','https://www.tsb.co.kr/CATOS','Total Soft Bank CATOS','Total Soft Bank');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM cat117_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS cat117_facts;
CREATE TEMPORARY TABLE cat117_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat117_facts VALUES
-- Kaleris N4 TOS
('kaleris-n4-tos','tos-vessel-berth-planning','supported',0.990,'Kaleris documents vessel planning support including N4 Vessel Autostow and terminal planning across berth, yard and quay workflows.','https://kaleris.com/solutions/terminal-operating-system/container-terminals/'),
('kaleris-n4-tos','tos-yard-planning-inventory','supported',0.990,'Kaleris documents N4 yard planning, Expert Decking, yard utilization and real-time container/equipment visibility.','https://kaleris.com/solutions/terminal-operating-system/container-terminals/'),
('kaleris-n4-tos','tos-gate-truck-operations','supported',0.980,'Kaleris documents terminal execution across the gate and truck workflows; exact optional optimization modules should be validated for the selected N4 package.','https://kaleris.com/solutions/terminal-operating-system/'),
('kaleris-n4-tos','tos-equipment-dispatch-control','supported',0.990,'Kaleris documents PrimeRoute, RTG/RMG optimization and VMT workflows for terminal handling equipment dispatch and execution.','https://kaleris.com/solutions/terminal-operating-system/container-terminals/'),
('kaleris-n4-tos','tos-automation-ecs','supported',0.990,'Kaleris documents N4 coordination of automated yard, transport, quay and gate operations through ECS integration for semi- and fully automated terminals.','https://kaleris.com/solutions/terminal-operating-system/'),
('kaleris-n4-tos','tos-edi-api-integrations','supported',0.990,'Kaleris documents robust EDI and API integration for container terminal cargo and external systems/data streams.','https://kaleris.com/what-is-a-terminal-operating-system/'),
('kaleris-n4-tos','tos-kpi-visibility','supported',0.980,'Kaleris documents real-time operational data, productivity KPIs, control-room visibility and decision-support optimization.','https://kaleris.com/solutions/terminal-operating-system/'),
('kaleris-n4-tos','tos-billing-financial','supported',0.970,'Kaleris documents capture of billable terminal events and N4 billing/invoicing; detailed tariff scope depends on implementation.','https://kaleris.com/what-is-a-terminal-operating-system/'),

-- Tideworks Mainsail
('tideworks-mainsail','tos-vessel-berth-planning','partially_supported',0.950,'Mainsail manages vessel activity, while full graphical vessel and berth planning is documented through the companion Spinnaker Planning Management System.','https://tideworks.com/oregons-only-international-container-terminal-relaunches-with-tideworks-technology/'),
('tideworks-mainsail','tos-yard-planning-inventory','partially_supported',0.950,'Mainsail manages cargo and inventory, while advanced graphical yard planning is documented with the companion Spinnaker planning system.','https://tideworks.com/oregons-only-international-container-terminal-relaunches-with-tideworks-technology/'),
('tideworks-mainsail','tos-gate-truck-operations','supported',0.980,'Tideworks documents gate operations in Mainsail; advanced gate imaging/processing may use the companion Gate Vision product.','https://tideworks.com/mainsail/'),
('tideworks-mainsail','tos-rail-operations','partially_supported',0.940,'Tideworks documents rail planning through the companion Spinnaker component deployed with Mainsail; do not treat it as a universal core-Mainsail entitlement.','https://tideworks.com/oregons-only-international-container-terminal-relaunches-with-tideworks-technology/'),
('tideworks-mainsail','tos-equipment-dispatch-control','partially_supported',0.950,'Terminal equipment dispatch and control are documented through Tideworks Traffic Control, a companion product integrated with Mainsail.','https://tideworks.com/traffic-control/'),
('tideworks-mainsail','tos-edi-api-integrations','partially_supported',0.960,'Mainsail 10 documents standardized API integration, while managed EDI is delivered through the companion EDI Porter service in current deployments.','https://tideworks.com/pomtoc-modernizes-terminal-operations-with-cloud-based-tos-mainsail-10/'),
('tideworks-mainsail','tos-kpi-visibility','supported',0.970,'Tideworks documents real-time operational visibility and data-driven planning across the Mainsail terminal platform.','https://tideworks.com/mainsail/'),

-- RBS TOPS Expert
('rbs-tops-expert','tos-vessel-berth-planning','supported',0.990,'TOPS Expert documents vessel planning/management, automated berth planning and real-time execution.','https://rbs-tops.com/terminal-operating-system/tops-terminal-solution/tops-expert-enterprise/'),
('rbs-tops-expert','tos-yard-planning-inventory','supported',0.990,'TOPS Expert documents advanced yard strategy, yard/truck management and container movement optimization.','https://rbs-tops.com/terminal-operating-system/tops-terminal-solution/tops-expert-enterprise/'),
('rbs-tops-expert','tos-gate-truck-operations','supported',0.990,'TOPO Expert documents gate management/GOS connectivity, while TOPS Expert Cloud documents integrated gate management.','https://rbs-tops.com/terminal-operating-system/topo-expert-2/'),
('rbs-tops-expert','tos-rail-operations','supported',0.980,'TOPS Expert Cloud explicitly documents rail management within the TOPX operational package.','https://www.rbs-emea.com/products/tops-expert-cloud'),
('rbs-tops-expert','tos-equipment-dispatch-control','supported',0.990,'RBS documents container-handling equipment management, equipment-control optimization and real-time operational planning.','https://www.rbs-emea.com/products/tops-expert-cloud'),
('rbs-tops-expert','tos-automation-ecs','supported',0.970,'RBS documents terminal automation, IoT-capable equipment connectivity and optimization; exact ECS adapters and automation scope require project validation.','https://www.rbs-emea.com/'),
('rbs-tops-expert','tos-edi-api-integrations','supported',0.990,'TOPO/TOPS documentation includes EDI processing, open interfaces/web services and connectivity to gate, reefer-monitoring and financial systems.','https://www.rbs-emea.com/products/tops-expert-cloud'),
('rbs-tops-expert','tos-kpi-visibility','supported',0.990,'RBS documents TOPS KPI dashboards, real-time monitoring, forecasting and operational reporting.','https://www.rbs-emea.com/'),
('rbs-tops-expert','tos-billing-financial','partially_supported',0.950,'RBS documents interfaces to financial systems and automatic linking of yard/vessel activity to billing; a universal native tariff/invoicing scope is not inferred.','https://www.rbs-emea.com/'),

-- CyberLogitec OPUS Terminal
('cyberlogitec-opus-terminal','tos-vessel-berth-planning','supported',0.990,'OPUS Terminal documents automated vessel, berth and yard planning using historical analysis, configurable patterns and real-time plan updates.','https://www.cyberlogitec.com/en/sub/solution/port/opus_terminal.php'),
('cyberlogitec-opus-terminal','tos-yard-planning-inventory','supported',0.990,'OPUS Terminal documents yard optimization, container intelligent management and automated yard planning.','https://www.cyberlogitec.com/en/sub/solution/port/opus_terminal.php'),
('cyberlogitec-opus-terminal','tos-gate-truck-operations','supported',0.990,'OPUS Terminal documents terminal workloads covering vessel, rail and gate operations and integrated trucking-company workflows.','https://www.cyberlogitec.com/en/sub/solution/port/opus_terminal.php'),
('cyberlogitec-opus-terminal','tos-rail-operations','supported',0.980,'OPUS Terminal explicitly documents optimized work orders across vessel, rail and gate entry/exit workflows.','https://www.cyberlogitec.com/en/sub/solution/port/opus_terminal.php'),
('cyberlogitec-opus-terminal','tos-equipment-dispatch-control','supported',0.990,'OPUS Terminal documents optimized equipment workload execution and unified equipment operations across terminal layouts.','https://www.cyberlogitec.com/en/sub/solution/port/opus_terminal.php'),
('cyberlogitec-opus-terminal','tos-automation-ecs','supported',0.990,'CyberLogitec documents OPUS Terminal integration with automated equipment control systems and semi-to-fully automated terminal operations.','https://www.cyberlogitec.com/en/sub/insight/press_view.php?idx=182'),
('cyberlogitec-opus-terminal','tos-edi-api-integrations','supported',0.980,'CyberLogitec documents integration with automated equipment, carriers, port authorities and trucking companies, including EDI-driven terminal data and interfaces.','https://www.cyberlogitec.com/en/sub/insight/press_view.php?idx=162'),
('cyberlogitec-opus-terminal','tos-kpi-visibility','partially_supported',0.950,'OPUS Terminal includes operation analysis and simulation; richer digital-twin visualization/analytics may use the separate OPUS DigiPort product and is not treated as universally included.','https://www.cyberlogitec.com/en/sub/solution/port/opus_terminal.php'),

-- Total Soft Bank CATOS
('total-soft-bank-catos','tos-vessel-berth-planning','supported',0.990,'CATOS explicitly documents berth, ship and planning workflows including automated ship planning.','https://www.tsb.co.kr/CATOS'),
('total-soft-bank-catos','tos-yard-planning-inventory','supported',0.990,'CATOS documents yard planning, remarshalling and container-position optimization.','https://www.tsb.co.kr/CATOS'),
('total-soft-bank-catos','tos-gate-truck-operations','supported',0.990,'CATOS explicitly documents gate planning and container entry/exit ordering within its integrated operating platform.','https://www.tsb.co.kr/CATOS'),
('total-soft-bank-catos','tos-rail-operations','supported',0.990,'CATOS explicitly documents rail planning and rail-supervisor workflows.','https://www.tsb.co.kr/CATOS'),
('total-soft-bank-catos','tos-equipment-dispatch-control','supported',0.990,'CATOS documents quay, RTG/RMG, rail and container-handling-equipment supervisor systems for optimized scheduling and work instructions.','https://www.tsb.co.kr/CATOS'),
('total-soft-bank-catos','tos-automation-ecs','supported',0.980,'CATOS documents automated transfer-crane supervision and equipment optimization; exact third-party ECS integration scope should be validated per terminal implementation.','https://www.tsb.co.kr/CATOS'),
('total-soft-bank-catos','tos-edi-api-integrations','supported',0.970,'CATOS documents EDI, web ordering and integrated-platform connectivity; exact API/interface catalogue should be validated for the selected release.','https://www.tsb.co.kr/CATOS'),
('total-soft-bank-catos','tos-kpi-visibility','supported',0.980,'CATOS documents digital-twin visualization and an automated real-time analytics dashboard for terminal performance evaluation.','https://www.tsb.co.kr/CATOS');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat117_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat117_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party vendor documentation supporting this capability.'
FROM cat117_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Promote deployment only where current product-specific evidence is explicit.
INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.990
FROM products p JOIN deployment_models d ON d.slug='on-premise'
WHERE p.slug='kaleris-n4-tos'
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.990
FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug='tideworks-mainsail'
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.980
FROM products p JOIN deployment_models d ON d.slug IN('on-premise','public-saas')
WHERE p.slug='rbs-tops-expert'
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

-- Do not infer platform-specific mobile access from browser/mobile-user references.
INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000
FROM products p CROSS JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') x
WHERE p.slug IN('kaleris-n4-tos','tideworks-mainsail','rbs-tops-expert','cyberlogitec-opus-terminal','total-soft-bank-catos')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

COMMIT;
