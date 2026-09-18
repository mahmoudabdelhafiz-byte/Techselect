-- TechSelectAI Commercial Shipping & Voyage Management Systems catalog expansion.
-- Adds one canonical category and five evidence-backed current products.
-- Official first-party evidence reviewed Sep 2026. Presence is not an endorsement.
-- Unknown != Unsupported. No Fit Score, recommendation ranking, review score, follower/community popularity or commercial placement logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('Commercial Shipping & Voyage Management Systems','commercial-shipping-voyage-management','Specialized software for chartering, voyage estimation, post-fixture operations, laytime, bunkers, voyage P&L, emissions, port costs, vessel reporting and integrations across commercial shipping workflows.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @vms_cat=(SELECT id FROM categories WHERE slug='commercial-shipping-voyage-management' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@vms_cat,'Chartering & Voyage Execution','vms-chartering-execution','Pre-fixture estimation, chartering, voyage operations, laytime and bunker-related commercial workflows.',1),
(@vms_cat,'Financial, Compliance & Connectivity','vms-financial-compliance','Voyage P&L/accounting, emissions, port costs, ship-shore reporting, integrations and voyage optimization.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.sec,1
FROM modules m JOIN (
 SELECT 'vms-chartering-execution' module_slug,'Chartering, voyage estimation & fixture management' name,'vms-chartering-estimation' slug,'Evaluate voyages and cargoes, estimate commercial outcomes, manage charter-party terms, fixtures or freight contracts before execution.' description,0 sec UNION ALL
 SELECT 'vms-chartering-execution','Voyage operations, itinerary & port-call execution','vms-voyage-operations','Manage post-fixture voyage execution, vessel itinerary, port calls, delays, cargo activity and operational updates through the voyage lifecycle.',0 UNION ALL
 SELECT 'vms-chartering-execution','Laytime, demurrage & despatch','vms-laytime-demurrage','Calculate, manage or track laytime, demurrage and despatch based on charter-party terms and port events.',0 UNION ALL
 SELECT 'vms-chartering-execution','Bunker / fuel planning & consumption management','vms-bunker-management','Plan, record, reconcile or analyze bunker inventory, fuel consumption, fuel costs or bunker-related commercial exposure.',0 UNION ALL
 SELECT 'vms-financial-compliance','Voyage P&L, accounting & accruals','vms-voyage-pnl-accounting','Track voyage profitability, invoices, accruals, revenues, expenses or accounting entries and connect operational changes to financial results.',0 UNION ALL
 SELECT 'vms-financial-compliance','Emissions & maritime regulatory cost management','vms-emissions-compliance','Calculate, monitor or manage shipping emissions and regulatory exposure such as EU ETS, FuelEU, CII or comparable voyage-level environmental obligations.',0 UNION ALL
 SELECT 'vms-financial-compliance','Port cost, PDA/FDA & disbursement management','vms-port-cost-disbursement','Manage estimated and actual port costs, port disbursements, PDA/FDA workflows or port-agent cost information.',0 UNION ALL
 SELECT 'vms-financial-compliance','Vessel reporting & ship-shore data capture','vms-vessel-reporting','Capture noon reports, arrival/departure events, vessel positions, consumption or other ship-originated operational reports into shoreside workflows.',0 UNION ALL
 SELECT 'vms-financial-compliance','APIs, accounting & maritime-system integrations','vms-api-integrations','Exchange voyage, financial, vessel or market data with accounting, ERP, ETRM/CTRM, routing, port-cost, vessel-reporting or other maritime systems through supported integrations or APIs.',0 UNION ALL
 SELECT 'vms-financial-compliance','Voyage planning & optimization','vms-voyage-optimization','Optimize voyage plans, routes, speeds or commercial voyage decisions using operational, weather, vessel-performance, cost or emissions data where supported.',0
) x ON x.module_slug=m.slug
WHERE m.category_id=@vms_cat
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Veson Nautical','veson-nautical','https://veson.com/','Commercial maritime freight-management, voyage-management and maritime-data software vendor.','active'),
('Sedna','sedna','https://sedna.com/','Maritime communication, commercial workflow and voyage-management software vendor.','active'),
('Shipnet','shipnet','https://shipnet.no/','Integrated maritime commercial, technical, safety, financial and fleet-management software vendor.','active'),
('90POE','90poe','https://www.90poe.io/','Maritime operations and commercial voyage-management software vendor.','active'),
('Nextvoyage','nextvoyage','https://www.nextvoyage.app/','Commercial maritime freight, voyage, accounting and risk-management software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat119_products;
CREATE TEMPORARY TABLE cat119_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO cat119_products VALUES
('veson-nautical','commercial-shipping-voyage-management','Veson IMOS','veson-imos','Commercial freight contract and voyage-management platform spanning chartering, voyage operations, bunkers, laytime, financials, emissions and connected commercial workflows.','https://veson.com/products/imos/'),
('sedna','commercial-shipping-voyage-management','Sedna Voyage Management System','sedna-voyage-management-system','Modern voyage-management system connecting charter parties, estimates, bunkers, port costs, laytime, voyage execution, emissions, P&L, APIs and mobile access in one workflow.','https://sedna.com/sedna-trade/voyage-management'),
('shipnet','commercial-shipping-voyage-management','Shipnet Commercial','shipnet-commercial','Commercial voyage-management software for cargo evaluation, voyage planning and execution, fixtures, noon-report integration, emissions visibility and integration with Shipnet financial and fleet modules.','https://shipnet.no/solutions/commercial'),
('90poe','commercial-shipping-voyage-management','OpenOcean STUDIO','openocean-studio','End-to-end maritime operations platform with commercial voyage management, operational voyage execution, port costs, bunkers, live P&L, emissions, vessel reporting, APIs and voyage optimization.','https://www.90poe.io/platform'),
('nextvoyage','commercial-shipping-voyage-management','Nextvoyage','nextvoyage','Cloud-based freight and voyage-management system for chartering, voyage operations, bunkers, port activities, laytime, voyage accounting, vessel reporting, risk management and maritime integrations.','https://www.nextvoyage.app/');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat119_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS cat119_sources;
CREATE TEMPORARY TABLE cat119_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat119_sources VALUES
('veson-imos','https://veson.com/products/imos/','Veson IMOS','Veson Nautical'),
('veson-imos','https://veson.com/products/imos/operations/','IMOS Operations','Veson Nautical'),
('veson-imos','https://help.veson.com/imos/vip-workflows','IMOS Workflows','Veson Nautical'),
('veson-imos','https://help.veson.com/imos/vip-demurrage','IMOS Demurrage','Veson Nautical'),
('veson-imos','https://help.veson.com/imos/veson-university-catalog','Veson University Catalog','Veson Nautical'),
('veson-imos','https://help.veson.com/imos/imos-financials-general-overview','IMOS Financials General Overview','Veson Nautical'),
('veson-imos','https://help.veson.com/imos/imos-carbon-emissions-financials-setup-settlement','IMOS Carbon Emissions Financials','Veson Nautical'),
('sedna-voyage-management-system','https://sedna.com/sedna-trade/voyage-management','Sedna Voyage Management System','Sedna'),
('shipnet-commercial','https://shipnet.no/solutions/commercial','Shipnet Commercial','Shipnet'),
('shipnet-commercial','https://shipnet.no/solutions/financial','Shipnet Financial','Shipnet'),
('shipnet-commercial','https://blog.shipnet.no/blog/articles/emissions-data-and-cii-cost-management-in-2024','Shipnet Emissions Data and CII Cost Management','Shipnet'),
('shipnet-commercial','https://blog.shipnet.no/blog/how-digitalisation-prepares-maritime-for-2026-challenges?hsLang=en','Shipnet Digitalisation for 2026','Shipnet'),
('openocean-studio','https://www.90poe.io/platform','OpenOcean STUDIO Platform','90POE'),
('openocean-studio','https://www.90poe.io/platform-pages/commercial-voyage-management','OpenOcean STUDIO Commercial Voyage Management','90POE'),
('openocean-studio','https://www.90poe.io/commercial-voyage-management','OpenOcean STUDIO Connected Commercial Voyage Management','90POE'),
('openocean-studio','https://www.90poe.io/platform-homepage','OpenOcean STUDIO Platform Homepage','90POE'),
('openocean-studio','https://www.90poe.io/post/taking-a-systems-perspective-on-maritime-technology','OpenOcean STUDIO API-driven Architecture','90POE'),
('nextvoyage','https://www.nextvoyage.app/','Nextvoyage Freight and Voyage Management','Nextvoyage'),
('nextvoyage','https://www.nextvoyage.app/chartering/','Nextvoyage Chartering','Nextvoyage'),
('nextvoyage','https://www.nextvoyage.app/voyage-operations/','Nextvoyage Voyage Operations','Nextvoyage'),
('nextvoyage','https://www.nextvoyage.app/voyage-accounting/','Nextvoyage Voyage Accounting','Nextvoyage'),
('nextvoyage','https://www.nextvoyage.app/partners-and-integrations/','Nextvoyage Partners and Integrations','Nextvoyage'),
('nextvoyage','https://www.nextvoyage.app/announcing-vessel-reporting/','Nextvoyage Vessel Reporting','Nextvoyage');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM cat119_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS cat119_facts;
CREATE TEMPORARY TABLE cat119_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat119_facts VALUES
-- Veson IMOS
('veson-imos','vms-chartering-estimation','supported',0.990,'IMOS Chartering supports voyage estimates, cargoes, fixtures, COAs and time-charter workflows from pre-fixture into voyage execution.','https://help.veson.com/imos/vip-workflows'),
('veson-imos','vms-voyage-operations','supported',0.990,'IMOS Operations manages itinerary, cargo details, vessel performance, voyage instructions, tasks, alerts and dynamic voyage P&L through the operational lifecycle.','https://veson.com/products/imos/operations/'),
('veson-imos','vms-laytime-demurrage','supported',0.990,'IMOS provides laytime calculations and demurrage/despatch workflows linked to voyage and port activities.','https://help.veson.com/imos/vip-demurrage'),
('veson-imos','vms-bunker-management','supported',0.990,'Veson documents an IMOS Bunker Management module covering bunker reporting, controls, procurement, de-bunkering and bunker claims.','https://help.veson.com/imos/veson-university-catalog'),
('veson-imos','vms-voyage-pnl-accounting','supported',0.990,'IMOS connects voyage operations to invoices, accruals, voyage P&L and a Financials module with accounting-system interfaces.','https://help.veson.com/imos/imos-financials-general-overview'),
('veson-imos','vms-emissions-compliance','supported',0.990,'IMOS documents voyage-level emissions workflows including EU ETS and FuelEU costs feeding P&L, invoices, accruals and financial reporting.','https://help.veson.com/imos/imos-carbon-emissions-financials-setup-settlement'),
('veson-imos','vms-port-cost-disbursement','supported',0.980,'Veson documents an end-to-end port disbursement workflow including agent nomination, statement of facts, ledger expense setup and invoice creation.','https://help.veson.com/imos/veson-university-catalog'),
('veson-imos','vms-vessel-reporting','partially_supported',0.960,'Veson documents Veslink Onboard Reporting for voyage reports such as noon, arrival and departure notices; this is treated as a connected IMOS/Veson workflow rather than assumed core entitlement.','https://help.veson.com/imos/veson-university-catalog'),
('veson-imos','vms-api-integrations','supported',0.980,'IMOS Financials supports bidirectional interfaces with major accounting systems and other data integrations; exact interface licensing and API scope depend on the implementation.','https://help.veson.com/imos/imos-financials-general-overview'),
('veson-imos','vms-voyage-optimization','partially_supported',0.950,'IMOS supports voyage planning and commercial optimization, but dedicated weather-routing or speed-optimization engines should not be inferred as universally included.','https://veson.com/products/imos/'),

-- Sedna VMS
('sedna-voyage-management-system','vms-chartering-estimation','supported',0.990,'Sedna VMS connects charter parties and voyage estimates and supports comparison of commercial scenarios using time, cost and consumption assumptions.','https://sedna.com/sedna-trade/voyage-management'),
('sedna-voyage-management-system','vms-voyage-operations','supported',0.990,'Sedna VMS captures voyage events, delays, consumption and operational updates in real time from fixture through completion.','https://sedna.com/sedna-trade/voyage-management'),
('sedna-voyage-management-system','vms-laytime-demurrage','supported',0.990,'Sedna VMS explicitly documents connected laytime and real-time demurrage updates during voyage execution.','https://sedna.com/sedna-trade/voyage-management'),
('sedna-voyage-management-system','vms-bunker-management','supported',0.990,'Sedna VMS connects bunker data to voyage estimates, operations, consumption and commercial outcomes.','https://sedna.com/sedna-trade/voyage-management'),
('sedna-voyage-management-system','vms-voyage-pnl-accounting','supported',0.990,'Sedna VMS documents voyage P&L updating as operational, contractual and financial inputs change.','https://sedna.com/sedna-trade/voyage-management'),
('sedna-voyage-management-system','vms-emissions-compliance','supported',0.980,'Sedna VMS surfaces voyage emissions alongside exposure and earnings before execution and recalculates emissions impacts as the voyage changes.','https://sedna.com/sedna-trade/voyage-management'),
('sedna-voyage-management-system','vms-port-cost-disbursement','supported',0.980,'Sedna VMS explicitly connects port costs to the voyage record from fixture through completion.','https://sedna.com/sedna-trade/voyage-management'),
('sedna-voyage-management-system','vms-api-integrations','supported',0.990,'Sedna VMS explicitly documents open APIs and connected-tool integrations.','https://sedna.com/sedna-trade/voyage-management'),

-- Shipnet Commercial
('shipnet-commercial','vms-chartering-estimation','supported',0.990,'Shipnet Commercial evaluates cargoes and supports end-to-end voyage management and fixture generation for commercial teams.','https://shipnet.no/solutions/commercial'),
('shipnet-commercial','vms-voyage-operations','supported',0.980,'Shipnet Commercial is positioned as an end-to-end commercial voyage-management system covering bulk, tanker and time-charter workflows.','https://shipnet.no/solutions/commercial'),
('shipnet-commercial','vms-laytime-demurrage','supported',0.960,'Shipnet documents integrated visibility across fixtures, charters, laytime and voyage performance; detailed laytime-calculation scope should be validated in the selected configuration.','https://blog.shipnet.no/blog/how-digitalisation-prepares-maritime-for-2026-challenges?hsLang=en'),
('shipnet-commercial','vms-bunker-management','partially_supported',0.950,'Shipnet uses bunker ROB and noon-report data for commercial voyage and emissions workflows, but a standalone bunker-procurement suite is not inferred from the reviewed evidence.','https://blog.shipnet.no/blog/articles/emissions-data-and-cii-cost-management-in-2024'),
('shipnet-commercial','vms-voyage-pnl-accounting','supported',0.980,'Shipnet commercial voyage management integrates with Shipnet Financial, which provides maritime accounting and multi-currency financial management.','https://shipnet.no/solutions/financial'),
('shipnet-commercial','vms-emissions-compliance','supported',0.990,'Shipnet documents voyage-estimate and voyage-manager support for CO2, CII and EU ETS cost and emissions tracking.','https://blog.shipnet.no/blog/articles/emissions-data-and-cii-cost-management-in-2024'),
('shipnet-commercial','vms-vessel-reporting','supported',0.990,'Shipnet Commercial explicitly integrates bulk, tanker and time-charter voyages with its noon-reporting solution.','https://shipnet.no/solutions/commercial'),
('shipnet-commercial','vms-api-integrations','supported',0.970,'Shipnet documents a broad integration ecosystem around commercial voyage management; exact API/interface availability depends on the connected applications.','https://shipnet.no/solutions/commercial'),

-- OpenOcean STUDIO
('openocean-studio','vms-chartering-estimation','supported',0.990,'OpenOcean STUDIO Commercial Voyage Management supports voyage estimation, nomination, fixture management and charter-party condition management.','https://www.90poe.io/platform-pages/commercial-voyage-management'),
('openocean-studio','vms-voyage-operations','supported',0.990,'OpenOcean STUDIO operational voyage management includes itinerary, port-call planning, port-agent management and operational voyage execution.','https://www.90poe.io/platform'),
('openocean-studio','vms-bunker-management','supported',0.990,'OpenOcean STUDIO operational voyage management explicitly includes bunker management and actuals flowing into connected commercial workflows.','https://www.90poe.io/platform'),
('openocean-studio','vms-voyage-pnl-accounting','supported',0.990,'OpenOcean STUDIO documents live P&L, life-cycle TCE, invoicing, post-fixture workflows and connected final-account processes.','https://www.90poe.io/commercial-voyage-management'),
('openocean-studio','vms-emissions-compliance','supported',0.990,'OpenOcean STUDIO emissions management covers MRV/DCS, CII, EU ETS and multiple greenhouse-gas measures.','https://www.90poe.io/platform'),
('openocean-studio','vms-port-cost-disbursement','supported',0.990,'OpenOcean STUDIO Commercial Voyage Management explicitly includes port-cost management within the connected commercial workflow.','https://www.90poe.io/commercial-voyage-management'),
('openocean-studio','vms-vessel-reporting','supported',0.990,'OpenOcean STUDIO onBOARD supports noon reports and ship-shore operational reporting, with actuals feeding the commercial voyage workflow.','https://www.90poe.io/platform-homepage'),
('openocean-studio','vms-api-integrations','supported',0.980,'90POE documents an API-driven architecture for synchronizing OpenOcean STUDIO with legacy and third-party applications.','https://www.90poe.io/post/taking-a-systems-perspective-on-maritime-technology'),
('openocean-studio','vms-voyage-optimization','supported',0.990,'OpenOcean STUDIO includes voyage optimization and monitoring with route evaluation, route/weather optimization, consumption and charter-party performance monitoring.','https://www.90poe.io/platform-homepage'),

-- Nextvoyage
('nextvoyage','vms-chartering-estimation','supported',0.990,'Nextvoyage includes voyage estimation, cargo and vessel contract management and pre-fixture chartering workflows.','https://www.nextvoyage.app/chartering/'),
('nextvoyage','vms-voyage-operations','supported',0.990,'Nextvoyage Voyage Operations manages vessel movements, port activities, cargo activities, ETAs and voyage performance in one workflow.','https://www.nextvoyage.app/voyage-operations/'),
('nextvoyage','vms-laytime-demurrage','supported',0.990,'Nextvoyage Voyage Operations explicitly includes laytime calculations and demurrage-related voyage workflows.','https://www.nextvoyage.app/voyage-operations/'),
('nextvoyage','vms-bunker-management','supported',0.990,'Nextvoyage documents bunker consumption, bunker planning and bunker contract/risk information within chartering and voyage operations.','https://www.nextvoyage.app/voyage-operations/'),
('nextvoyage','vms-voyage-pnl-accounting','supported',0.990,'Nextvoyage integrates voyage operations with voyage accounting, general-ledger entries, accrual adjustments and periodic income/expense calculations.','https://www.nextvoyage.app/voyage-accounting/'),
('nextvoyage','vms-port-cost-disbursement','supported',0.980,'Nextvoyage Voyage Operations tracks port activities and Port DAs within voyage execution.','https://www.nextvoyage.app/'),
('nextvoyage','vms-vessel-reporting','supported',0.990,'Nextvoyage Vessel Reporting lets vessel crews submit noon, anchoring, berthing and other vessel events into linked shoreside voyage workflows.','https://www.nextvoyage.app/announcing-vessel-reporting/'),
('nextvoyage','vms-api-integrations','supported',0.980,'Nextvoyage documents integrations with maritime data, routing and performance providers and interfaces to external reporting/financial systems.','https://www.nextvoyage.app/partners-and-integrations/');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat119_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat119_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party vendor documentation supporting this capability.'
FROM cat119_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Promote deployment only where current product-specific evidence is explicit.
INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.990
FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug IN('veson-imos','shipnet-commercial','openocean-studio','nextvoyage')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

-- Do not infer Android/iOS/mobile-web platform support from generic mobile-access or onboard claims.
INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000
FROM products p CROSS JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') x
WHERE p.slug IN('veson-imos','sedna-voyage-management-system','shipnet-commercial','openocean-studio','nextvoyage')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

COMMIT;
