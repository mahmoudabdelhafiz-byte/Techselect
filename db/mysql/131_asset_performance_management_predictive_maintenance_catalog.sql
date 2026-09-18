-- TechSelectAI Asset Performance Management & Predictive Maintenance catalog expansion.
-- Adds one canonical industrial APM category and five evidence-backed current products.
-- Official first-party evidence reviewed Sep 2026. Presence is not an endorsement.
-- Unknown != Unsupported. No Fit Score, recommendation ranking, review score, follower/community popularity or commercial placement logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('Asset Performance Management & Predictive Maintenance','asset-performance-management-predictive-maintenance','Industrial asset-performance and predictive-maintenance software for condition monitoring, anomaly detection, failure forecasting, prescriptive action, reliability strategy, EAM integration and enterprise-scale asset health programs.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @apm_cat=(SELECT id FROM categories WHERE slug='asset-performance-management-predictive-maintenance' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@apm_cat,'Asset Health & Predictive Intelligence','apm-predictive-intelligence','Condition monitoring, anomaly detection, failure prediction and prescriptive maintenance insight for industrial assets.',1),
(@apm_cat,'Reliability Strategy & Enterprise Action','apm-reliability-enterprise','Criticality/risk, RCM/FMEA, maintenance-system integration, operational-data integration, collaborative case workflows and multi-site scaling.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.sec,1
FROM modules m JOIN (
 SELECT 'apm-predictive-intelligence' module_slug,'Asset health & condition monitoring' name,'apm-asset-health-monitoring' slug,'Assess current equipment condition and health using sensor, operational, inspection or maintenance data with asset-level status and prioritized attention.' description,0 sec UNION ALL
 SELECT 'apm-predictive-intelligence','Anomaly detection & early warning','apm-anomaly-detection','Detect abnormal equipment behavior or emerging degradation before functional failure using rules, analytics, AI/ML or digital-twin techniques.' description,0 UNION ALL
 SELECT 'apm-predictive-intelligence','Failure prediction, prognosis & time-to-failure','apm-failure-prediction','Forecast likely equipment failures, remaining useful life, malfunction windows or future degradation with predictive models where explicitly supported.' description,0 UNION ALL
 SELECT 'apm-predictive-intelligence','Prescriptive maintenance recommendations','apm-prescriptive-recommendations','Turn asset-health and predictive findings into recommended corrective actions, remediation guidance or prioritized maintenance decisions.' description,0 UNION ALL
 SELECT 'apm-reliability-enterprise','Asset criticality, risk & strategy optimization','apm-risk-strategy','Assess asset criticality and risk and optimize maintenance or mitigation strategies against cost, reliability and operating context.' description,0 UNION ALL
 SELECT 'apm-reliability-enterprise','RCM, FMEA & reliability analysis','apm-rcm-fmea-reliability','Support reliability-centered maintenance, FMEA/failure-mode analysis, root-cause or other reliability methodologies where explicitly documented.' description,0 UNION ALL
 SELECT 'apm-reliability-enterprise','EAM / CMMS maintenance workflow integration','apm-eam-workflow-integration','Deliver recommendations, health insights or work triggers into EAM, CMMS, ERP or maintenance workflows and consume relevant maintenance history.' description,0 UNION ALL
 SELECT 'apm-reliability-enterprise','OT, historian, sensor & condition-data integration','apm-ot-data-integration','Ingest or connect sensor, historian, vibration, control-system, IoT or other operations data used to evaluate asset health and predictive models.' description,0 UNION ALL
 SELECT 'apm-reliability-enterprise','Alerts, cases & reliability-team collaboration','apm-case-collaboration','Manage alerts, cases, comments, evidence, notifications or collaborative investigation workflows around asset-health and predictive findings.' description,0 UNION ALL
 SELECT 'apm-reliability-enterprise','Enterprise & multi-site predictive-maintenance scale','apm-enterprise-multisite','Standardize and scale asset-health or predictive-maintenance programs across large asset fleets, plants, regions or enterprise operations.' description,0
) x ON x.module_slug=m.slug
WHERE m.category_id=@apm_cat
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('GE Vernova','ge-vernova','https://www.gevernova.com/','Energy and industrial software provider including asset-performance and predictive-maintenance applications.','active'),
('Aspen Technology','aspentech','https://www.aspentech.com/','Industrial AI, asset optimization and process-industry software vendor.','active'),
('Siemens','siemens','https://www.siemens.com/','Industrial automation, digitalization and predictive-maintenance software vendor.','active'),
('AVEVA','aveva','https://www.aveva.com/','Industrial software and asset-performance analytics vendor.','active'),
('ABB','abb','https://www.abb.com/','Industrial automation, electrification and asset-performance software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat131_products;
CREATE TEMPORARY TABLE cat131_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO cat131_products VALUES
('ge-vernova','asset-performance-management-predictive-maintenance','GE Vernova Asset Performance Management','ge-vernova-apm','Modular enterprise APM suite spanning asset health, SmartSignal predictive analytics, reliability, asset strategy, integrity and connected maintenance workflows across asset-intensive operations.','https://www.gevernova.com/software/products/asset-performance-management'),
('aspentech','asset-performance-management-predictive-maintenance','Aspen Mtell','aspen-mtell','Industrial AI predictive and prescriptive maintenance software providing asset-health templates, anomaly/failure prediction, embedded FMEA-guided prescriptions and EAM-connected reliability workflows at enterprise scale.','https://www.aspentech.com/en/products/apm/aspen-mtell'),
('siemens','asset-performance-management-predictive-maintenance','Senseye Predictive Maintenance','siemens-senseye-predictive-maintenance','Cloud-based predictive-maintenance solution combining industrial AI, machine-health insights, failure forecasting, collaborative cases and scalable deployment across assets, plants and regions.','https://www.siemens.com/en-us/products/industrial-digitalization-services/senseye-predictive-maintenance/'),
('aveva','asset-performance-management-predictive-maintenance','AVEVA Predictive Analytics','aveva-predictive-analytics','AI-powered predictive-maintenance software for anomaly detection, fault diagnostics, time-to-failure forecasting, prescriptive guidance, case management and scalable asset monitoring.','https://www.aveva.com/en/products/predictive-analytics/'),
('abb','asset-performance-management-predictive-maintenance','ABB Genix APM','abb-genix-apm','Enterprise asset-performance suite combining condition monitoring, predictive and prescriptive analytics, pre-built asset models, contextualized industrial data and actionable maintenance recommendations.','https://new.abb.com/process-automation/genix');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat131_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS cat131_sources;
CREATE TEMPORARY TABLE cat131_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat131_sources VALUES
('ge-vernova-apm','https://www.gevernova.com/software/products/asset-performance-management','GE Vernova Asset Performance Management','GE Vernova'),
('ge-vernova-apm','https://www.gevernova.com/software/products/asset-performance-management/condition-monitoring','GE Vernova APM Health','GE Vernova'),
('ge-vernova-apm','https://www.gevernova.com/software/products/asset-performance-management/equipment-downtime-predictive-analytics','GE Vernova SmartSignal Predictive Analytics','GE Vernova'),
('ge-vernova-apm','https://www.gevernova.com/software/products/asset-performance-management/asset-strategy-management','GE Vernova APM Strategy','GE Vernova'),
('ge-vernova-apm','https://www.gevernova.com/software/products/asset-performance-management/asset-reliability','GE Vernova APM Reliability','GE Vernova'),
('ge-vernova-apm','https://www.gevernova.com/software/products/asset-performance-management/cloud-edge','GE Vernova Cloud-Based APM','GE Vernova'),
('ge-vernova-apm','https://www.gevernova.com/software/blog/asset-performance-management-v5-faq-premises','GE Vernova APM V5 On-Premises FAQ','GE Vernova'),
('aspen-mtell','https://www.aspentech.com/en/products/apm/aspen-mtell','Aspen Mtell','AspenTech'),
('aspen-mtell','https://www.aspentech.com/en/platform-support/cloud-support','AspenTech Cloud Support','AspenTech'),
('siemens-senseye-predictive-maintenance','https://www.siemens.com/en-us/products/industrial-digitalization-services/senseye-predictive-maintenance/','Senseye Predictive Maintenance','Siemens'),
('siemens-senseye-predictive-maintenance','https://www.siemens.com/en-gb/products/industrial-digitalization-services/senseye-cloud-application/','Senseye Cloud Application','Siemens'),
('siemens-senseye-predictive-maintenance','https://cache.industry.siemens.com/dl/files/319/109955319/att_1350959/v1/109955319_Senseye-product-sheet-V1.6_Nov25-2.pdf','Senseye Predictive Maintenance Product Data Sheet','Siemens'),
('siemens-senseye-predictive-maintenance','https://developer.siemens.com/senseye/machine/index.html','Senseye Machine Data Integration','Siemens'),
('aveva-predictive-analytics','https://www.aveva.com/en/products/predictive-analytics/','AVEVA Predictive Analytics','AVEVA'),
('aveva-predictive-analytics','https://www.aveva.com/en/solutions/operations/asset-performance-management/','AVEVA Asset Performance Management','AVEVA'),
('abb-genix-apm','https://new.abb.com/process-automation/genix','ABB Genix Industrial IoT and AI Suite','ABB'),
('abb-genix-apm','https://new.abb.com/industrial-software/asset-performance-management','ABB Asset Performance Management','ABB'),
('abb-genix-apm','https://new.abb.com/news/detail/135969/abb-named-a-leader-in-green-quadrant-for-asset-performance-management-solutions','ABB Genix APM 2026 Update','ABB'),
('abb-genix-apm','https://www.abb.com/global/en/company/innovation/news/genix-asset-performance-management','ABB Genix APM Copilot','ABB');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM cat131_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS cat131_facts;
CREATE TEMPORARY TABLE cat131_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat131_facts VALUES
-- GE Vernova APM
('ge-vernova-apm','apm-asset-health-monitoring','supported',0.990,'APM Health provides near-real-time asset health/condition status and equipment-health workflows; it is a module within the broader GE Vernova APM suite.','https://www.gevernova.com/software/products/asset-performance-management/condition-monitoring'),
('ge-vernova-apm','apm-anomaly-detection','supported',0.990,'SmartSignal predictive analytics detects emerging equipment issues using AI/ML and digital-twin blueprints; SmartSignal is an integrated APM application rather than base-platform entitlement.','https://www.gevernova.com/software/products/asset-performance-management/equipment-downtime-predictive-analytics'),
('ge-vernova-apm','apm-failure-prediction','supported',0.990,'SmartSignal forecasts equipment malfunction windows and supports predictive maintenance across hundreds of equipment types.','https://www.gevernova.com/software/products/asset-performance-management/equipment-downtime-predictive-analytics'),
('ge-vernova-apm','apm-prescriptive-recommendations','supported',0.980,'GE Vernova APM combines SmartSignal, Health, policies and reliability workflows to generate remediation guidance and maintenance recommendations; exact function depends on selected APM applications.','https://www.gevernova.com/software/products/asset-performance-management'),
('ge-vernova-apm','apm-risk-strategy','supported',0.990,'APM Strategy provides criticality assessment, risk identification and risk/cost-based maintenance-strategy optimization as a dedicated suite application.','https://www.gevernova.com/software/products/asset-performance-management/asset-strategy-management'),
('ge-vernova-apm','apm-rcm-fmea-reliability','supported',0.990,'APM Strategy and Reliability explicitly support RCM, FMEA, reliability analysis and failure-elimination workflows.','https://www.gevernova.com/software/products/asset-performance-management/asset-strategy-management'),
('ge-vernova-apm','apm-eam-workflow-integration','supported',0.990,'APM Health generates work recommendations with EAM integration and the broader APM platform integrates maintenance and enterprise data.','https://www.gevernova.com/software/products/asset-performance-management/condition-monitoring'),
('ge-vernova-apm','apm-ot-data-integration','supported',0.990,'GE Vernova cloud APM connects sensors, historians, ERP, EAM/CMMS, OPC UA, MQTT and other OT/IT data sources.','https://www.gevernova.com/software/products/asset-performance-management/cloud-edge'),
('ge-vernova-apm','apm-case-collaboration','supported',0.980,'APM suite workflows include alerts, action tracking, investigation and corrective-action collaboration; exact screens vary by licensed APM application.','https://www.gevernova.com/software/products/asset-performance-management'),
('ge-vernova-apm','apm-enterprise-multisite','supported',0.990,'GE Vernova positions APM as an integrated enterprise solution with scalable cross-asset and enterprise operations.','https://www.gevernova.com/software/products/asset-performance-management'),

-- Aspen Mtell
('aspen-mtell','apm-asset-health-monitoring','supported',0.990,'Aspen Mtell uses industry-specific asset templates to establish and scale foundational asset health across the enterprise.','https://www.aspentech.com/en/products/apm/aspen-mtell'),
('aspen-mtell','apm-anomaly-detection','supported',0.990,'Aspen Mtell Industrial AI detects emerging failure patterns rather than relying only on simple threshold alarms.','https://www.aspentech.com/en/products/apm/aspen-mtell'),
('aspen-mtell','apm-failure-prediction','supported',0.990,'Aspen Mtell explicitly predicts equipment failures in advance using industrial AI and predictive-maintenance models.','https://www.aspentech.com/en/products/apm/aspen-mtell'),
('aspen-mtell','apm-prescriptive-recommendations','supported',0.990,'Embedded FMEA provides corrective prescriptions that turn predictive findings into recommended actions.','https://www.aspentech.com/en/products/apm/aspen-mtell'),
('aspen-mtell','apm-risk-strategy','partially_supported',0.960,'Mtell prioritizes asset-health risk and supports reliability strategy at scale, but a full standalone asset-criticality and maintenance-strategy optimization module is not inferred.','https://www.aspentech.com/en/products/apm/aspen-mtell'),
('aspen-mtell','apm-rcm-fmea-reliability','partially_supported',0.990,'Embedded FMEA is explicit, but full RCM and broad statistical reliability-analysis parity are not inferred from Mtell alone.','https://www.aspentech.com/en/products/apm/aspen-mtell'),
('aspen-mtell','apm-eam-workflow-integration','supported',0.990,'Aspen Mtell explicitly integrates actionable insights into ERP workflows through deep EAM-system integration.','https://www.aspentech.com/en/products/apm/aspen-mtell'),
('aspen-mtell','apm-ot-data-integration','partially_supported',0.970,'Mtell integrates with Emerson AMS vibration monitoring and uses industrial condition data, but a universal historian/OT connector catalogue is not inferred from the reviewed product evidence.','https://www.aspentech.com/en/products/apm/aspen-mtell'),
('aspen-mtell','apm-enterprise-multisite','supported',0.990,'Aspen Mtell explicitly targets enterprise-scale deployment using reusable asset templates and scalable reliability programs.','https://www.aspentech.com/en/products/apm/aspen-mtell'),

-- Siemens Senseye
('siemens-senseye-predictive-maintenance','apm-asset-health-monitoring','supported',0.990,'Senseye provides holistic asset-health visibility and condition/risk prioritization across industrial machinery.','https://www.siemens.com/en-us/products/industrial-digitalization-services/senseye-predictive-maintenance/'),
('siemens-senseye-predictive-maintenance','apm-anomaly-detection','supported',0.990,'Senseye automatically models machine behavior and raises predictive cases when asset condition deviates from expected behavior.','https://www.siemens.com/en-gb/products/industrial-digitalization-services/senseye-cloud-application/'),
('siemens-senseye-predictive-maintenance','apm-failure-prediction','supported',0.990,'Senseye Cloud forecasts machine failure and provides remaining-useful-life and risk insights for predictive maintenance.','https://www.siemens.com/en-gb/products/industrial-digitalization-services/senseye-cloud-application/'),
('siemens-senseye-predictive-maintenance','apm-prescriptive-recommendations','partially_supported',0.970,'Senseye prioritizes maintenance attention and provides diagnostics/actionable context, but a formal prescriptive-maintenance recommendation engine equivalent to FMEA-guided prescriptions is not inferred.','https://www.siemens.com/en-us/products/industrial-digitalization-services/senseye-predictive-maintenance/'),
('siemens-senseye-predictive-maintenance','apm-risk-strategy','partially_supported',0.960,'Senseye prioritizes asset condition and failure risk, but a full criticality/maintenance-strategy optimization module is not inferred.','https://www.siemens.com/en-us/products/industrial-digitalization-services/senseye-predictive-maintenance/'),
('siemens-senseye-predictive-maintenance','apm-eam-workflow-integration','partially_supported',0.960,'Senseye complements existing CMMS, historians and operational systems, but the reviewed public evidence does not establish universal closed-loop work-order integration.','https://www.siemens.com/en-us/products/industrial-digitalization-services/senseye-predictive-maintenance/'),
('siemens-senseye-predictive-maintenance','apm-ot-data-integration','supported',0.990,'Senseye accepts time-series/vibration data through APIs, MQTT, cloud object storage or historian connectivity and is designed to work with existing machine data.','https://developer.siemens.com/senseye/machine/index.html'),
('siemens-senseye-predictive-maintenance','apm-case-collaboration','supported',0.990,'Senseye cases support notes, messages, @mentions, replies and captured maintenance knowledge around predictive findings.','https://cache.industry.siemens.com/dl/files/319/109955319/att_1350959/v1/109955319_Senseye-product-sheet-V1.6_Nov25-2.pdf'),
('siemens-senseye-predictive-maintenance','apm-enterprise-multisite','supported',0.990,'Senseye is explicitly designed to scale predictive maintenance across assets, plants, regions and large industrial organizations.','https://www.siemens.com/en-us/products/industrial-digitalization-services/senseye-predictive-maintenance/'),

-- AVEVA Predictive Analytics
('aveva-predictive-analytics','apm-asset-health-monitoring','supported',0.990,'AVEVA Predictive Analytics continuously monitors asset performance and provides asset-health information for reliability decisions.','https://www.aveva.com/en/products/predictive-analytics/'),
('aveva-predictive-analytics','apm-anomaly-detection','supported',0.990,'AVEVA Predictive Analytics identifies equipment anomalies weeks or months before failure using AI-powered models.','https://www.aveva.com/en/products/predictive-analytics/'),
('aveva-predictive-analytics','apm-failure-prediction','supported',0.990,'The product explicitly provides time-to-failure forecasting to help users prioritize maintenance and shutdown decisions.','https://www.aveva.com/en/products/predictive-analytics/'),
('aveva-predictive-analytics','apm-prescriptive-recommendations','supported',0.990,'AVEVA provides prescriptive guidance and recommended actions from its Asset Library to remediate detected failure conditions.','https://www.aveva.com/en/products/predictive-analytics/'),
('aveva-predictive-analytics','apm-ot-data-integration','partially_supported',0.970,'AVEVA positions Predictive Analytics alongside PI System and enterprise operations data, but PI System is a related product rather than assumed bundled connectivity.','https://www.aveva.com/en/solutions/operations/asset-performance-management/'),
('aveva-predictive-analytics','apm-case-collaboration','supported',0.990,'Predictive Analytics includes advanced alerts, case management, knowledge capture and comprehensive reporting around anomalies.','https://www.aveva.com/en/products/predictive-analytics/'),
('aveva-predictive-analytics','apm-enterprise-multisite','supported',0.980,'AVEVA explicitly positions the product to deploy and scale predictive-maintenance programs across industrial operations; exact enterprise topology depends on deployment.','https://www.aveva.com/en/products/predictive-analytics/'),

-- ABB Genix APM
('abb-genix-apm','apm-asset-health-monitoring','supported',0.990,'ABB Genix APM provides broad condition monitoring and asset-performance visibility across multiple equipment classes.','https://new.abb.com/industrial-software/asset-performance-management'),
('abb-genix-apm','apm-anomaly-detection','supported',0.990,'Genix APM combines machine learning and industrial AI to identify asset-performance deviations and developing issues.','https://www.abb.com/global/en/company/innovation/news/genix-asset-performance-management'),
('abb-genix-apm','apm-failure-prediction','supported',0.990,'ABB Genix APM explicitly provides predictive analytics and models designed to prevent failures in advance.','https://new.abb.com/process-automation/genix'),
('abb-genix-apm','apm-prescriptive-recommendations','supported',0.990,'Genix APM combines predictive and prescriptive analytics to provide actionable recommendations for maintenance and operations.','https://new.abb.com/process-automation/genix'),
('abb-genix-apm','apm-risk-strategy','partially_supported',0.970,'ABB Genix APM uses asset criticality and performance context to prioritize maintenance, but full standalone asset-strategy optimization parity is not inferred.','https://new.abb.com/industrial-software/asset-performance-management'),
('abb-genix-apm','apm-eam-workflow-integration','supported',0.980,'ABB documents Genix APM collecting and contextualizing data from ERP, CMMS and EAM systems and closing the feedback loop with maintenance recommendations.','https://new.abb.com/industrial-software/asset-performance-management'),
('abb-genix-apm','apm-ot-data-integration','supported',0.990,'Genix APM is vendor-agnostic and combines OT/sensor data with enterprise and maintenance-system information for asset analytics.','https://new.abb.com/industrial-software/asset-performance-management'),
('abb-genix-apm','apm-enterprise-multisite','supported',0.990,'ABB documents Genix APM as enterprise-grade and highlights global deployment across large asset portfolios.','https://new.abb.com/news/detail/135969/abb-named-a-leader-in-green-quadrant-for-asset-performance-management-solutions');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat131_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat131_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party vendor documentation supporting this capability.'
FROM cat131_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Promote deployment only where current product-specific evidence is explicit.
INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.990
FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug IN('ge-vernova-apm','siemens-senseye-predictive-maintenance')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.990
FROM products p JOIN deployment_models d ON d.slug='on-premise'
WHERE p.slug='ge-vernova-apm'
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

-- Aspen Mtell cloud VM support, AVEVA cloud-enabled wording and ABB flexible deployment do not by themselves establish the commercial deployment labels used by this catalog.
INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000
FROM products p CROSS JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') x
WHERE p.slug IN('ge-vernova-apm','aspen-mtell','siemens-senseye-predictive-maintenance','aveva-predictive-analytics','abb-genix-apm')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,'mobile_web','supported','supported','vendor_documentation',0.990
FROM products p WHERE p.slug='siemens-senseye-predictive-maintenance'
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

COMMIT;
