-- TechSelectAI Industrial Energy & Sustainability Management catalog expansion.
-- Adds one canonical energy/sustainability category and five evidence-backed current products.
-- Official first-party evidence reviewed Sep 2026. Presence is not an endorsement.
-- Unknown != Unsupported. No Fit Score, recommendation ranking, review score, follower/community popularity or commercial placement logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('Industrial Energy & Sustainability Management Platforms','industrial-energy-sustainability-management','Software for monitoring and improving industrial energy performance, managing utility and meter data, forecasting and optimizing energy use, tracking carbon emissions, supporting energy/compliance programs and rolling up performance across enterprise sites.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @esm_cat=(SELECT id FROM categories WHERE slug='industrial-energy-sustainability-management' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@esm_cat,'Energy Operations & Efficiency','esm-energy-operations','Energy/resource data collection, utility cost analysis, KPI benchmarking, forecasting and operational energy optimization.',1),
(@esm_cat,'Carbon, Compliance & Enterprise Sustainability','esm-carbon-governance','GHG accounting, target/program management, ISO 50001 support, enterprise integration and multi-site sustainability governance.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.sec,1
FROM modules m JOIN (
 SELECT 'esm-energy-operations' module_slug,'Energy & resource metering / data collection' name,'esm-energy-data-collection' slug,'Collect, import or aggregate electricity, gas, steam, water, compressed air, fuel or other resource/energy data from meters, systems, bills or operational sources.' description,0 sec UNION ALL
 SELECT 'esm-energy-operations','Utility bill, cost & interval-data analytics','esm-utility-cost-analytics','Analyze utility cost, tariff, bill, interval meter or consumption data to identify waste, anomalies, savings and cost-allocation opportunities.' description,0 UNION ALL
 SELECT 'esm-energy-operations','Energy KPIs, baselines & benchmarking','esm-kpi-benchmarking','Calculate and compare normalized energy KPIs, baselines, intensity metrics, site/line performance and efficiency trends.' description,0 UNION ALL
 SELECT 'esm-energy-operations','Forecasting, scenario planning & simulation','esm-forecast-scenario','Forecast energy demand, emissions, generation or costs and evaluate alternative plans, scenarios or optimization outcomes before execution.' description,0 UNION ALL
 SELECT 'esm-energy-operations','Real-time energy optimization & control','esm-realtime-optimization','Automatically optimize or dispatch loads, utilities, generation, storage or process-energy decisions in real time or near real time where explicitly supported.' description,0 UNION ALL
 SELECT 'esm-carbon-governance','GHG emissions accounting & carbon reporting','esm-ghg-accounting','Calculate, reconcile, track and report greenhouse-gas quantities, intensities or carbon footprints using documented methodologies and emissions factors where supported.' description,0 UNION ALL
 SELECT 'esm-carbon-governance','Energy/carbon targets & sustainability programs','esm-target-program-management','Define reduction targets, track measures/projects, monitor progress and manage sustainability or energy-efficiency initiatives across the organization.' description,0 UNION ALL
 SELECT 'esm-carbon-governance','ISO 50001 & energy-compliance support','esm-iso50001-compliance','Support ISO 50001-oriented energy management, audit-ready energy reporting or comparable energy-efficiency compliance requirements where explicitly documented.' description,0 UNION ALL
 SELECT 'esm-carbon-governance','OT, meter, ERP & enterprise data integration','esm-enterprise-integration','Integrate meter, SCADA, BMS, IoT, ERP, MES, utility, finance or other enterprise/operational data through supported interfaces, pipelines or APIs.' description,0 UNION ALL
 SELECT 'esm-carbon-governance','Enterprise multi-site roll-up & governance','esm-enterprise-multisite','Aggregate, compare and govern energy, cost, emissions or sustainability performance across multiple facilities, plants, regions or business units.' description,0
) x ON x.module_slug=m.slug
WHERE m.category_id=@esm_cat
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Siemens','siemens','https://www.siemens.com/','Industrial automation, digitalization and energy-management software vendor.','active'),
('Schneider Electric','schneider-electric','https://www.se.com/','Energy management, sustainability and industrial automation software vendor.','active'),
('ABB','abb','https://www.abb.com/','Industrial automation, electrification and energy-optimization software vendor.','active'),
('IBM','ibm','https://www.ibm.com/','Enterprise software, analytics and sustainability-data management vendor.','active'),
('Honeywell','honeywell','https://www.honeywell.com/','Industrial automation, emissions-management and sustainability software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat132_products;
CREATE TEMPORARY TABLE cat132_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO cat132_products VALUES
('siemens','industrial-energy-sustainability-management','SIMATIC Energy Manager','simatic-energy-manager','Industrial energy-management software for plant and enterprise energy-data collection, KPI benchmarking, target tracking, carbon-footprint visibility, ISO 50001 support and OT/IT integration, with on-premises, Industrial Edge and cloud variants.','https://www.siemens.com/en-us/products/simatic-energy-management/energy-manager/'),
('schneider-electric','industrial-energy-sustainability-management','EcoStruxure Resource Advisor','ecostruxure-resource-advisor','Cloud-based enterprise energy and sustainability platform for utility/bill data, interval-meter analytics, benchmarking, carbon management, sustainability projects, procurement insights and portfolio-wide reporting.','https://www.se.com/sa/en/work/services/se-advisory-services/intelligent-software/resource-advisor/'),
('abb','industrial-energy-sustainability-management','ABB Ability OPTIMAX','abb-ability-optimax','Industrial energy-management and optimization platform combining monitoring/reporting, forecasting/planning and predictive real-time optimization for industrial sites, microgrids and energy-intensive operations.','https://www.abb.com/global/en/areas/automation/solutions/industrial-software/energy-management/energy-optimization-optimax'),
('ibm','industrial-energy-sustainability-management','IBM Envizi','ibm-envizi','Enterprise sustainability and decarbonization platform for utility and interval-meter analytics, energy/emissions reporting, GHG accounting, targets, forecasting, program tracking and auditable multi-organization data management.','https://www.ibm.com/products/envizi'),
('honeywell','industrial-energy-sustainability-management','Honeywell Forge Sustainability+ for Industrials | Emissions Management','honeywell-forge-sustainability-emissions','Industrial emissions-management SaaS platform that reconciles measurement data from Honeywell and third-party sources to track, measure, report and support reduction of greenhouse-gas quantities and intensities.','https://process.honeywell.com/us/en/campaigns/lss/emissions-management-suite');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat132_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS cat132_sources;
CREATE TEMPORARY TABLE cat132_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat132_sources VALUES
('simatic-energy-manager','https://www.siemens.com/en-us/products/simatic-energy-management/energy-manager/','SIMATIC Energy Manager','Siemens'),
('simatic-energy-manager','https://www.siemens.com/en-us/energy-manager/','SIMATIC Energy Manager Energy and Carbon Management','Siemens'),
('simatic-energy-manager','https://cache.industry.siemens.com/dl/files/226/109991226/att_1359114/v1/SIMATIC_EM_Webclient_7.6.pdf?download=true','SIMATIC Energy Manager Web Client 7.6','Siemens'),
('ecostruxure-resource-advisor','https://www.se.com/sa/en/work/services/se-advisory-services/intelligent-software/resource-advisor/','EcoStruxure Resource Advisor','Schneider Electric'),
('ecostruxure-resource-advisor','https://www.se.com/sa/en/work/services/se-advisory-services/energy-management/','Schneider Electric Energy Management Services','Schneider Electric'),
('ecostruxure-resource-advisor','https://www.se.com/uk/en/work/software/ecostruxure-building/small-buildings-sustainability-management/','Resource Advisor Sustainability Strategy','Schneider Electric'),
('abb-ability-optimax','https://www.abb.com/global/en/areas/automation/solutions/industrial-software/energy-management/energy-optimization-optimax','ABB Ability OPTIMAX','ABB'),
('abb-ability-optimax','https://new.abb.com/news/detail/133171/abb-introduces-saas-option-for-industrial-energy-optimization-software','ABB Ability OPTIMAX SaaS 7.0','ABB'),
('abb-ability-optimax','https://new.abb.com/process-automation/energy-industries/digital/solutions','ABB Ability Energy Management and Optimization','ABB'),
('ibm-envizi','https://www.ibm.com/products/envizi','IBM Envizi','IBM'),
('ibm-envizi','https://www.ibm.com/products/envizi/decarbonization','IBM Envizi Decarbonization','IBM'),
('ibm-envizi','https://www.ibm.com/products/envizi/utility-bill-analytics','IBM Envizi Utility Bill Analytics','IBM'),
('ibm-envizi','https://www.ibm.com/products/envizi/interval-meter-analytics','IBM Envizi Interval Meter Analytics','IBM'),
('ibm-envizi','https://www.ibm.com/products/envizi/emissions-management','IBM Envizi Emissions Management','IBM'),
('ibm-envizi','https://www.ibm.com/products/envizi/target-setting-tracking','IBM Envizi Target Setting and Tracking','IBM'),
('ibm-envizi','https://www.ibm.com/support/pages/ibm-envizi-esg-suitesaas','IBM Envizi ESG Suite SaaS Lifecycle','IBM'),
('honeywell-forge-sustainability-emissions','https://process.honeywell.com/us/en/campaigns/lss/emissions-management-suite','Honeywell Emissions Management Suite','Honeywell'),
('honeywell-forge-sustainability-emissions','https://process.honeywell.com/us/en/products/industrial-software/process-optimization/end-to-end-optimization-for-industrials','Honeywell Sustainability+ for Industrials','Honeywell');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM cat132_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS cat132_facts;
CREATE TEMPORARY TABLE cat132_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat132_facts VALUES
-- SIMATIC Energy Manager
('simatic-energy-manager','esm-energy-data-collection','supported',0.990,'SIMATIC Energy Manager records electricity, gas, water, compressed-air and other energy/media data from machines, meters and plant systems.','https://www.siemens.com/en-us/products/simatic-energy-management/energy-manager/'),
('simatic-energy-manager','esm-utility-cost-analytics','partially_supported',0.970,'Energy Manager analyzes consumption, costs and cost allocation, but enterprise utility-bill validation/procurement workflows are not inferred from the reviewed product evidence.','https://www.siemens.com/en-us/energy-manager/'),
('simatic-energy-manager','esm-kpi-benchmarking','supported',0.990,'Siemens documents KPI calculation, benchmarking, kWh per unit, CO2 per product, peak loads and comparison across lines, shifts and plants.','https://www.siemens.com/en-us/products/simatic-energy-management/energy-manager/'),
('simatic-energy-manager','esm-forecast-scenario','partially_supported',0.970,'Energy Manager includes production planning, prognosis and digital-energy-twin simulation, but broad enterprise sustainability scenario planning is not inferred.','https://cache.industry.siemens.com/dl/files/226/109991226/att_1359114/v1/SIMATIC_EM_Webclient_7.6.pdf?download=true'),
('simatic-energy-manager','esm-realtime-optimization','partially_supported',0.960,'Industrial Edge supports near-real-time analysis and Energy Manager identifies optimization potential, but autonomous closed-loop dispatch of site energy assets is not inferred.','https://www.siemens.com/en-us/products/simatic-energy-management/energy-manager/'),
('simatic-energy-manager','esm-ghg-accounting','partially_supported',0.980,'Corporate and product carbon-footprint cockpits are explicit, including upstream/own emissions, but full Scope 1-3 enterprise GHG accounting with maintained factor libraries is not inferred.','https://www.siemens.com/en-us/products/simatic-energy-management/energy-manager/'),
('simatic-energy-manager','esm-target-program-management','partially_supported',0.980,'The Target Cockpit supports savings targets and measures, but broad enterprise sustainability-program/project management is not inferred.','https://cache.industry.siemens.com/dl/files/226/109991226/att_1359114/v1/SIMATIC_EM_Webclient_7.6.pdf?download=true'),
('simatic-energy-manager','esm-iso50001-compliance','supported',0.990,'Siemens explicitly positions SIMATIC Energy Manager as supporting ISO 50001 energy-management requirements.','https://www.siemens.com/en-us/energy-manager/'),
('simatic-energy-manager','esm-enterprise-integration','supported',0.990,'SIMATIC Energy Manager integrates energy/media data from machines, SCADA, BMS, ERP and MES using industrial and enterprise interfaces.','https://www.siemens.com/en-us/products/simatic-energy-management/energy-manager/'),
('simatic-energy-manager','esm-enterprise-multisite','supported',0.990,'Siemens documents cross-location/cloud evaluation and benchmarking from machines and plants to enterprise-wide consumption visibility.','https://www.siemens.com/en-us/products/simatic-energy-management/energy-manager/'),

-- EcoStruxure Resource Advisor
('ecostruxure-resource-advisor','esm-energy-data-collection','supported',0.990,'Resource Advisor aggregates cross-enterprise energy, utility, water, waste and sustainability data in one platform.','https://www.se.com/sa/en/work/services/se-advisory-services/intelligent-software/resource-advisor/'),
('ecostruxure-resource-advisor','esm-utility-cost-analytics','supported',0.990,'Resource Advisor validates and analyzes utility bills, interval data, energy budgets and procurement/cost information across portfolios.','https://www.se.com/sa/en/work/services/se-advisory-services/intelligent-software/resource-advisor/'),
('ecostruxure-resource-advisor','esm-kpi-benchmarking','supported',0.990,'Resource Advisor compares and benchmarks facilities using raw or normalized energy data and tracks performance from corporate to site level.','https://www.se.com/sa/en/work/services/se-advisory-services/intelligent-software/resource-advisor/'),
('ecostruxure-resource-advisor','esm-forecast-scenario','partially_supported',0.970,'Schneider documents predictive energy-cost modules plus decarbonization project/scenario planning, but not plant-level operational scheduling/dispatch.','https://www.se.com/uk/en/work/software/ecostruxure-building/small-buildings-sustainability-management/'),
('ecostruxure-resource-advisor','esm-realtime-optimization','partially_supported',0.950,'Resource Advisor identifies efficiency opportunities, alarms and project priorities, but closed-loop real-time plant energy control belongs to other EcoStruxure offerings and is not inferred here.','https://www.se.com/sa/en/work/services/se-advisory-services/intelligent-software/resource-advisor/'),
('ecostruxure-resource-advisor','esm-ghg-accounting','supported',0.990,'Resource Advisor includes carbon-management reporting and a maintained global emissions library for enterprise sustainability data.','https://www.se.com/sa/en/work/services/se-advisory-services/intelligent-software/resource-advisor/'),
('ecostruxure-resource-advisor','esm-target-program-management','supported',0.990,'Resource Advisor supports decarbonization goals, sustainability-program performance and centrally managed energy-efficiency projects.','https://www.se.com/uk/en/work/software/ecostruxure-building/small-buildings-sustainability-management/'),
('ecostruxure-resource-advisor','esm-enterprise-integration','partially_supported',0.970,'Resource Advisor is designed to complement existing infrastructure and energy-management systems and ingest many enterprise data streams, but native plant protocol coverage is not inferred.','https://www.se.com/sa/en/work/services/se-advisory-services/intelligent-software/resource-advisor/'),
('ecostruxure-resource-advisor','esm-enterprise-multisite','supported',0.990,'Resource Advisor is explicitly an enterprise-level global platform with portfolio-wide roll-up and site/regional analysis.','https://www.se.com/sa/en/work/services/se-advisory-services/intelligent-software/resource-advisor/'),

-- ABB Ability OPTIMAX
('abb-ability-optimax','esm-energy-data-collection','supported',0.990,'OPTIMAX Monitoring and Reporting provides site-wide energy-consumption transparency across energy sources, loads and industrial utilities.','https://www.abb.com/global/en/areas/automation/solutions/industrial-software/energy-management/energy-optimization-optimax'),
('abb-ability-optimax','esm-utility-cost-analytics','supported',0.980,'OPTIMAX monitors energy cost, prices, generation and consumption and uses them in planning and optimization; utility-bill administration is not implied.','https://www.abb.com/global/en/areas/automation/solutions/industrial-software/energy-management/energy-optimization-optimax'),
('abb-ability-optimax','esm-kpi-benchmarking','supported',0.990,'OPTIMAX provides monitoring/reporting, operational KPIs and multi-site benchmarking for energy performance.','https://new.abb.com/process-automation/energy-industries/digital/solutions'),
('abb-ability-optimax','esm-forecast-scenario','supported',0.990,'OPTIMAX explicitly supports AI-enabled forecasting, day-ahead/intraday planning, simulations and predictive optimization.','https://www.abb.com/global/en/areas/automation/solutions/industrial-software/energy-management/energy-optimization-optimax'),
('abb-ability-optimax','esm-realtime-optimization','supported',0.990,'OPTIMAX provides predictive control, automatic asset dispatch and real-time optimization of generation, storage and industrial loads.','https://www.abb.com/global/en/areas/automation/solutions/industrial-software/energy-management/energy-optimization-optimax'),
('abb-ability-optimax','esm-ghg-accounting','partially_supported',0.970,'OPTIMAX monitors emissions and optimizes carbon intensity, but full corporate Scope 1-3 GHG accounting and disclosure workflows are not inferred.','https://www.abb.com/global/en/areas/automation/solutions/industrial-software/energy-management/energy-optimization-optimax'),
('abb-ability-optimax','esm-iso50001-compliance','supported',0.990,'ABB explicitly documents OPTIMAX monitoring/reporting and ISO 50001-oriented energy-management support.','https://www.abb.com/global/en/areas/automation/solutions/industrial-software/energy-management/energy-optimization-optimax'),
('abb-ability-optimax','esm-enterprise-integration','supported',0.980,'OPTIMAX integrates industrial energy assets, production/process context, markets and enterprise systems as part of site optimization.','https://new.abb.com/process-automation/energy-industries/digital/solutions'),
('abb-ability-optimax','esm-enterprise-multisite','supported',0.990,'ABB documents multi-site operation, benchmarking and company-wide energy optimization with scalable deployment.','https://new.abb.com/process-automation/energy-industries/digital/solutions'),

-- IBM Envizi
('ibm-envizi','esm-energy-data-collection','supported',0.990,'Envizi automates energy and ESG data ingestion from utility providers, interval meters, IoT/metering platforms, ERP systems and other enterprise sources.','https://www.ibm.com/products/envizi'),
('ibm-envizi','esm-utility-cost-analytics','supported',0.990,'Utility Bill Analytics and Interval Meter Analytics provide cost, consumption, anomaly, demand and savings analysis across portfolios.','https://www.ibm.com/products/envizi/utility-bill-analytics'),
('ibm-envizi','esm-kpi-benchmarking','supported',0.990,'Envizi supports normalized energy-intensity analysis, baselines, benchmarking and portfolio-to-meter performance comparison.','https://www.ibm.com/products/envizi/interval-meter-analytics'),
('ibm-envizi','esm-forecast-scenario','partially_supported',0.990,'Planning Analytics supports forecasting, simulation and emissions planning, but it is an add-on module rather than assumed in every Envizi package.','https://www.ibm.com/products/envizi/decarbonization'),
('ibm-envizi','esm-realtime-optimization','partially_supported',0.950,'Envizi detects energy waste, raises alerts and prioritizes efficiency actions, but it is not treated as a closed-loop industrial energy-control platform.','https://www.ibm.com/products/envizi/decarbonization'),
('ibm-envizi','esm-ghg-accounting','supported',0.990,'Envizi provides Scope 1, 2 and 3 GHG accounting/reporting with maintained emissions factors and GHG Protocol methodologies.','https://www.ibm.com/products/envizi/emissions-management'),
('ibm-envizi','esm-target-program-management','supported',0.990,'Envizi provides target setting/tracking and sustainability-program tracking for energy, emissions and decarbonization initiatives.','https://www.ibm.com/products/envizi/target-setting-tracking'),
('ibm-envizi','esm-enterprise-integration','supported',0.980,'Envizi ingests data from ERP, IoT/metering platforms, utility providers, spreadsheets and supplier portals and exposes APIs as add-ons.','https://www.ibm.com/products/envizi'),
('ibm-envizi','esm-enterprise-multisite','supported',0.990,'Envizi models regions, sites, assets, product lines and organizational hierarchies for enterprise roll-up and reporting.','https://www.ibm.com/products/envizi'),

-- Honeywell Forge Sustainability+ for Industrials | Emissions Management
('honeywell-forge-sustainability-emissions','esm-energy-data-collection','partially_supported',0.960,'Honeywell Sustainability+ coordinates emissions and measurement data from Honeywell and third-party devices, but broad utility/resource metering scope is not inferred.','https://process.honeywell.com/us/en/campaigns/lss/emissions-management-suite'),
('honeywell-forge-sustainability-emissions','esm-kpi-benchmarking','partially_supported',0.960,'The platform tracks greenhouse-gas quantities and intensities, but broad energy-efficiency KPI and facility benchmarking parity is not inferred.','https://process.honeywell.com/us/en/products/industrial-software/process-optimization/end-to-end-optimization-for-industrials'),
('honeywell-forge-sustainability-emissions','esm-ghg-accounting','supported',0.990,'Honeywell explicitly positions Sustainability+ as a single source of truth for tracking, measurement, reconciliation, compliance and reduction of greenhouse-gas quantities and intensities.','https://process.honeywell.com/us/en/products/industrial-software/process-optimization/end-to-end-optimization-for-industrials'),
('honeywell-forge-sustainability-emissions','esm-target-program-management','partially_supported',0.960,'Honeywell supports compliance and reduction activities around industrial emissions, but broad enterprise sustainability-project portfolio management is not inferred.','https://process.honeywell.com/us/en/products/industrial-software/process-optimization/end-to-end-optimization-for-industrials'),
('honeywell-forge-sustainability-emissions','esm-enterprise-integration','supported',0.990,'Sustainability+ coordinates data from Honeywell and third-party measurement devices and can integrate historian/other industrial data sources.','https://process.honeywell.com/us/en/campaigns/lss/emissions-management-suite'),
('honeywell-forge-sustainability-emissions','esm-enterprise-multisite','partially_supported',0.950,'Honeywell positions the platform as scalable enterprise emissions management, but explicit multi-site energy-governance depth is not inferred from the reviewed sources.','https://process.honeywell.com/us/en/campaigns/lss/emissions-management-suite');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat132_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat132_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party vendor documentation supporting this capability.'
FROM cat132_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Promote deployment only where the commercial deployment model is explicit.
INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.990
FROM products p JOIN deployment_models d ON d.slug='on-premise'
WHERE p.slug IN('simatic-energy-manager','abb-ability-optimax')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.990
FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug IN('ecostruxure-resource-advisor','abb-ability-optimax','ibm-envizi','honeywell-forge-sustainability-emissions')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

-- SIMATIC Energy Manager has Industrial Edge and Insights Hub cloud variants, but cloud wording alone is not converted to the catalog's public-SaaS label here.
-- Platform-specific mobile access remains unknown for all five products.
INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000
FROM products p CROSS JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') x
WHERE p.slug IN('simatic-energy-manager','ecostruxure-resource-advisor','abb-ability-optimax','ibm-envizi','honeywell-forge-sustainability-emissions')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

COMMIT;
