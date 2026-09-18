-- TechSelectAI Calibration & Metrology Management Software catalog expansion.
-- Adds one canonical specialized calibration/metrology category and five evidence-backed current products.
-- Official first-party evidence reviewed Sep 2026. Presence is not an endorsement.
-- Unknown != Unsupported. No Fit Score, recommendation ranking, review score, follower/community popularity or commercial placement logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('Calibration & Metrology Management Software','calibration-metrology-management','Specialized software for managing measurement assets, calibration schedules, procedures and test points, uncertainty, metrological traceability, out-of-tolerance workflows, certificates, instrument automation, regulated audit trails and enterprise calibration operations.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @cal_cat=(SELECT id FROM categories WHERE slug='calibration-metrology-management' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@cal_cat,'Calibration Planning & Metrology Execution','cal-planning-execution','Measurement-asset scheduling, guided/automated calibration procedures, uncertainty, traceability and as-found/as-left calibration execution.',1),
(@cal_cat,'Compliance, Documentation & Enterprise Operations','cal-compliance-enterprise','Certificates and signatures, calibrator integration, field execution, audit/compliance controls and enterprise integration/multi-site operations.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.sec,1
FROM modules m JOIN (
 SELECT 'cal-planning-execution' module_slug,'Measurement asset register & calibration scheduling' name,'cal-asset-scheduling' slug,'Maintain measurement/test-equipment records, calibration intervals, due dates, locations, status and scheduled calibration workload.' description,0 sec UNION ALL
 SELECT 'cal-planning-execution','Calibration procedures, test points & guided execution','cal-procedure-execution','Create or manage calibration procedures, test points, tolerances and step-by-step execution workflows for manual or automated calibration.' description,0 UNION ALL
 SELECT 'cal-planning-execution','Measurement uncertainty & decision-rule calculations','cal-uncertainty-decision-rules','Calculate, manage or report calibration measurement uncertainty, uncertainty budgets, guard bands or decision rules where explicitly supported.' description,0 UNION ALL
 SELECT 'cal-planning-execution','Reference standards & metrological traceability','cal-reference-traceability','Associate calibration work with reference standards and preserve an auditable traceability chain from calibrated assets to standards and calibration history.' description,0 UNION ALL
 SELECT 'cal-planning-execution','As-found / as-left & out-of-tolerance handling','cal-asfound-asleft-oot','Capture before/after adjustment results and identify, investigate or report failed and out-of-tolerance calibration conditions and their impact.' description,0 UNION ALL
 SELECT 'cal-compliance-enterprise','Calibration certificates, labels & electronic approval','cal-certificates-esign','Generate calibration certificates or labels and support controlled review, approval or electronic signatures where explicitly documented.' description,0 UNION ALL
 SELECT 'cal-compliance-enterprise','Calibrator / test-equipment integration & automation','cal-instrument-automation','Exchange procedures/results with documenting calibrators or automate calibration sequences using supported test equipment and interfaces.' description,0 UNION ALL
 SELECT 'cal-compliance-enterprise','Field & offline calibration execution','cal-field-offline','Execute and document calibration work away from the main system, including offline or detached field workflows where supported.' description,0 UNION ALL
 SELECT 'cal-compliance-enterprise','Regulated records, audit trail & standards support','cal-regulated-audit','Provide audit trails, controlled records and functionality supporting requirements such as ISO/IEC 17025, ISO 9001, FDA/GxP or 21 CFR Part 11 where explicitly documented.' description,1 UNION ALL
 SELECT 'cal-compliance-enterprise','ERP/CMMS integration & multi-site calibration operations','cal-enterprise-integration-scale','Integrate calibration data or work orders with ERP/CMMS/enterprise systems and scale standardized calibration operations across multiple sites where supported.' description,0
) x ON x.module_slug=m.slug
WHERE m.category_id=@cal_cat
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Beamex','beamex','https://www.beamex.com/','Calibration management software, calibrator and metrology technology vendor.','active'),
('Fluke Calibration','fluke-calibration','https://www.fluke.com/','Calibration software, electrical/RF metrology and calibration-equipment vendor.','active'),
('IndySoft','indysoft','https://www.indysoft.com/','Calibration management, tooling and maintenance software vendor.','active'),
('Prime Technologies','prime-technologies','https://www.primetechpa.com/','Calibration management and regulated calibration software vendor.','active'),
('CyberMetrics','cybermetrics','https://cybermetrics.com/','Calibration and maintenance management software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat135_products;
CREATE TEMPORARY TABLE cat135_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO cat135_products VALUES
('beamex','calibration-metrology-management','Beamex CMX','beamex-cmx','Calibration management software for instrumentation assets, scheduling, guided calibration, uncertainty, traceable history, regulated records, certificates, documenting-calibrator workflows, offline field execution and CMMS/ERP integration.','https://www.beamex.com/calibration-software/cmx/'),
('fluke-calibration','calibration-metrology-management','Fluke MET/CAL + MET/TEAM','fluke-metcal-metteam','Integrated calibration automation and asset/workflow management suite combining MET/CAL procedures/runtime with MET/TEAM scheduling, traceability, uncertainty, certificates, reporting, mobile modules and enterprise data access.','https://www.fluke.com/en/product/fluke-software/fluke-calibration-software'),
('indysoft','calibration-metrology-management','IndySoft Calibration Management','indysoft-calibration-management','Configurable calibration-management platform for asset scheduling, test-point execution, uncertainty budgets, traceability, certificates, audit trails, detached field calibration, SAP/ERP integration and global multi-site operations.','https://www.indysoft.com/solutions/clients'),
('prime-technologies','calibration-metrology-management','PCX','prime-pcx','Web-based SaaS calibration-management system for asset/test-specification execution, reference-standard traceability, calibration certificates, results trending, Fluke calibrator integration and regulated calibration workflows.','https://www.primetechpa.com/pcx-demo-b/'),
('cybermetrics','calibration-metrology-management','GAGEtrak','cybermetrics-gagetrak','Calibration management software for measurement/test equipment, schedules, procedures, calibration records, certificates, labels, electronic signatures, MSA, compliance controls and API-enabled integration.','https://gagetrak.com/');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat135_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS cat135_sources;
CREATE TEMPORARY TABLE cat135_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat135_sources VALUES
('beamex-cmx','https://www.beamex.com/calibration-software/cmx/','Beamex CMX Calibration Management Software','Beamex'),
('beamex-cmx','https://www.beamex.com/calibration-software/','Beamex Calibration Management Software','Beamex'),
('fluke-metcal-metteam','https://www.fluke.com/en/product/fluke-software/fluke-calibration-software','MET/CAL Calibration Management Software','Fluke'),
('fluke-metcal-metteam','https://www.fluke.com/en/product/fluke-software/fluke-calibration-software/met-team-asset-management-software','MET/TEAM Test Equipment Asset Management Software','Fluke'),
('indysoft-calibration-management','https://www.indysoft.com/solutions/clients','IndySoft Client Calibration Management','IndySoft'),
('indysoft-calibration-management','https://docs.indysoft.com/indysoft-eam/hm-scheduling2/','IndySoft Scheduling','IndySoft'),
('indysoft-calibration-management','https://docs.indysoft.com/indysoft-eam/uncertaintymodule-overview/','IndySoft Uncertainty Module','IndySoft'),
('indysoft-calibration-management','https://docs.indysoft.com/indysoft-eam/hm-calibration-info/','IndySoft Calibration Information and Traceability','IndySoft'),
('indysoft-calibration-management','https://docs.indysoft.com/indysoft-eam/next/hm-event-tabs-calibration-resul/','IndySoft Calibration Results','IndySoft'),
('indysoft-calibration-management','https://www.indysoft.com/solutions/commercial-labs','IndySoft Commercial Lab Management','IndySoft'),
('prime-pcx','https://www.primetechpa.com/pcx-demo-b/','PCX Calibration Management','Prime Technologies'),
('prime-pcx','https://helpcenter.primetechpa.com/hc/en-us','Prime Technologies PCX Knowledgebase','Prime Technologies'),
('prime-pcx','https://helpcenter.primetechpa.com/hc/en-us/sections/21160249342989-Test-Type-Package-User-Manuals','PCX Test Type Package Manuals','Prime Technologies'),
('cybermetrics-gagetrak','https://gagetrak.com/','GAGEtrak Calibration Management Software','CyberMetrics'),
('cybermetrics-gagetrak','https://gagetrak.com/features/','GAGEtrak Features','CyberMetrics');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM cat135_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS cat135_facts;
CREATE TEMPORARY TABLE cat135_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat135_facts VALUES
-- Beamex CMX
('beamex-cmx','cal-asset-scheduling','supported',0.990,'CMX manages instrumentation assets and plans/schedules calibration work with procedures and interval information.','https://www.beamex.com/calibration-software/cmx/'),
('beamex-cmx','cal-procedure-execution','supported',0.990,'CMX guides calibration step-by-step and can execute calibration workflows in CMX, documenting calibrators or the companion bMobile application.','https://www.beamex.com/calibration-software/cmx/'),
('beamex-cmx','cal-uncertainty-decision-rules','supported',0.990,'CMX permanently stores calibration results with calculated uncertainties and provides dedicated calibration calculations.','https://www.beamex.com/calibration-software/cmx/'),
('beamex-cmx','cal-reference-traceability','supported',0.990,'CMX maintains traceable calibration history and structured instrument/calibrator records for regulated calibration programs.','https://www.beamex.com/calibration-software/cmx/'),
('beamex-cmx','cal-asfound-asleft-oot','partially_supported',0.970,'CMX stores complete calibration results and trend/history data, but a dedicated impact-assessment workflow for every out-of-tolerance case is not inferred from the reviewed public page.','https://www.beamex.com/calibration-software/cmx/'),
('beamex-cmx','cal-certificates-esign','supported',0.990,'CMX generates reports/certificates and supports electronic signatures and controlled approval workflows for regulated records.','https://www.beamex.com/calibration-software/cmx/'),
('beamex-cmx','cal-instrument-automation','supported',0.990,'CMX exchanges procedures and results digitally with Beamex documenting calibrators to reduce manual data entry.','https://www.beamex.com/calibration-software/cmx/'),
('beamex-cmx','cal-field-offline','partially_supported',0.990,'Offline field execution is provided through the companion Beamex bMobile application rather than assumed as native functionality in every CMX client configuration.','https://www.beamex.com/calibration-software/cmx/'),
('beamex-cmx','cal-regulated-audit','supported',0.990,'CMX documents change tracking, electronic records/signatures and support for regulated requirements including FDA/GMP/GAMP and 21 CFR Part 11.','https://www.beamex.com/calibration-software/cmx/'),
('beamex-cmx','cal-enterprise-integration-scale','supported',0.980,'CMX can scale to new sites and connects with maintenance systems such as SAP and IBM Maximo through Beamex Business Bridge; that connector is a related commercial component.','https://www.beamex.com/calibration-software/cmx/'),

-- Fluke MET/CAL + MET/TEAM
('fluke-metcal-metteam','cal-asset-scheduling','supported',0.990,'MET/TEAM provides calibration workflow and asset management with automated alerts and status/history tracking.','https://www.fluke.com/en/product/fluke-software/fluke-calibration-software/met-team-asset-management-software'),
('fluke-metcal-metteam','cal-procedure-execution','supported',0.990,'MET/CAL Procedure Editor and Runtime create, execute, test and document automated calibration procedures.','https://www.fluke.com/en/product/fluke-software/fluke-calibration-software'),
('fluke-metcal-metteam','cal-uncertainty-decision-rules','supported',0.990,'MET/CAL configures and reports measurement-uncertainty parameters and verification data for calibration analysis.','https://www.fluke.com/en/product/fluke-software/fluke-calibration-software'),
('fluke-metcal-metteam','cal-reference-traceability','supported',0.990,'The MET/CAL/MET/TEAM suite tracks work-order history, traceability, status, locations and calibration verification data.','https://www.fluke.com/en/product/fluke-software/fluke-calibration-software'),
('fluke-metcal-metteam','cal-asfound-asleft-oot','partially_supported',0.970,'The suite records detailed calibration/verification results and history, but a universal out-of-tolerance impact-assessment workflow is not inferred from the reviewed overview.','https://www.fluke.com/en/product/fluke-software/fluke-calibration-software'),
('fluke-metcal-metteam','cal-certificates-esign','supported',0.980,'MET/TEAM produces customized calibration certificates and reports; electronic-signature depth depends on configured workflow and modules.','https://www.fluke.com/en/product/fluke-software/fluke-calibration-software'),
('fluke-metcal-metteam','cal-instrument-automation','supported',0.990,'MET/CAL automates calibration of dc/lf, RF, microwave and other test/measurement equipment using validated procedures.','https://www.fluke.com/en/product/fluke-software/fluke-calibration-software'),
('fluke-metcal-metteam','cal-field-offline','partially_supported',0.960,'MET/TEAM offers a Mobile module for on-site calibration, but offline/detached behavior and entitlement should be verified for the intended deployment.','https://www.fluke.com/en/product/fluke-software/fluke-calibration-software'),
('fluke-metcal-metteam','cal-regulated-audit','supported',0.990,'Fluke explicitly documents support for ISO 9000, ISO/IEC 17025, ANSI Z540.3 and other calibration-quality requirements with verification/audit data.','https://www.fluke.com/en/product/fluke-software/fluke-calibration-software'),
('fluke-metcal-metteam','cal-enterprise-integration-scale','partially_supported',0.970,'MET/TEAM can make calibration data available to other corporate systems and provides secure browser-based access, but global multi-site governance depth is not inferred.','https://www.fluke.com/en/product/fluke-software/fluke-calibration-software'),

-- IndySoft Calibration Management
('indysoft-calibration-management','cal-asset-scheduling','supported',0.990,'IndySoft manages asset lifecycle, location and configurable calibration schedules with due-date progression and reminders.','https://www.indysoft.com/solutions/clients'),
('indysoft-calibration-management','cal-procedure-execution','supported',0.990,'IndySoft calibration events collect test-point data, procedures, standards and pass/fail results through configurable workflows.','https://docs.indysoft.com/indysoft-eam/next/hm-event-tabs-calibration-resul/'),
('indysoft-calibration-management','cal-uncertainty-decision-rules','supported',0.990,'IndySoft includes an Uncertainty Module with uncertainty budgets, master rules, contributing items, studies and correlations applied to calibration test points.','https://docs.indysoft.com/indysoft-eam/uncertaintymodule-overview/'),
('indysoft-calibration-management','cal-reference-traceability','supported',0.990,'IndySoft records reference-standard assignments and traceability numbers and validates appropriate standards during uncertainty-enabled calibration.','https://docs.indysoft.com/indysoft-eam/hm-calibration-info/'),
('indysoft-calibration-management','cal-asfound-asleft-oot','supported',0.990,'Calibration events explicitly capture as-found and final/as-left readings, pass/fail, adjusted and limited-use results.','https://docs.indysoft.com/indysoft-eam/next/hm-event-tabs-calibration-resul/'),
('indysoft-calibration-management','cal-certificates-esign','supported',0.990,'IndySoft manages certificate templates, calibration certificates, digital sign-offs and paperless compliance documentation.','https://www.indysoft.com/solutions/clients'),
('indysoft-calibration-management','cal-field-offline','supported',0.980,'IndySoft supports detached off-site field calibration with automatic technician synchronization back to the main system.','https://www.indysoft.com/solutions/commercial-labs'),
('indysoft-calibration-management','cal-regulated-audit','supported',0.990,'IndySoft records user interactions in a complete audit trail and provides controls for regulated calibration environments.','https://www.indysoft.com/solutions/clients'),
('indysoft-calibration-management','cal-enterprise-integration-scale','supported',0.990,'IndySoft supports SAP/ERP integration and global multi-site operations with centralized or facility-specific workflows in one database.','https://www.indysoft.com/solutions/commercial-labs'),

-- Prime PCX
('prime-pcx','cal-asset-scheduling','partially_supported',0.960,'PCX manages calibration assets and technician workflows, but the reviewed public page does not establish the full depth of advanced interval/scheduling logic.','https://www.primetechpa.com/pcx-demo-b/'),
('prime-pcx','cal-procedure-execution','supported',0.990,'PCX provides purpose-built test specification types, calibrated-asset workflows and one-click calibration execution.','https://www.primetechpa.com/pcx-demo-b/'),
('prime-pcx','cal-uncertainty-decision-rules','partially_supported',0.980,'PCX provides a dedicated Uncertainty Test Type, but full uncertainty-budget and decision-rule functionality should be verified for the selected edition.','https://helpcenter.primetechpa.com/hc/en-us/sections/21160249342989-Test-Type-Package-User-Manuals'),
('prime-pcx','cal-reference-traceability','supported',0.990,'PCX explicitly supports referenced Test Standards, reverse-traceability reports and auditable asset/result records.','https://www.primetechpa.com/pcx-demo-b/'),
('prime-pcx','cal-asfound-asleft-oot','partially_supported',0.960,'PCX supports pass/fail test specifications and calibration result history, but a complete out-of-tolerance impact workflow is not inferred from the reviewed PCX material.','https://www.primetechpa.com/pcx-demo-b/'),
('prime-pcx','cal-certificates-esign','supported',0.980,'PCX generates certificate reports and secures asset/result records; exact electronic-signature/approval scope should be verified for the selected edition.','https://www.primetechpa.com/pcx-demo-b/'),
('prime-pcx','cal-instrument-automation','supported',0.990,'PCX has out-of-the-box compatibility with Fluke documenting process calibrators and preloaded calibrator settings.','https://www.primetechpa.com/pcx-demo-b/'),
('prime-pcx','cal-regulated-audit','partially_supported',0.960,'PCX is designed for calibration audit readiness, but legacy ProCalV5 regulatory claims are not automatically inherited as identical PCX compliance scope.','https://www.primetechpa.com/pcx-demo-b/'),

-- GAGEtrak
('cybermetrics-gagetrak','cal-asset-scheduling','supported',0.990,'GAGEtrak manages measurement/test equipment with flexible calibration schedules, reminders, due lists and calendar views.','https://gagetrak.com/features/'),
('cybermetrics-gagetrak','cal-procedure-execution','supported',0.980,'GAGEtrak manages linked calibration procedures and custom measurement formulas; dedicated automation through external instruments is not inferred.','https://gagetrak.com/features/'),
('cybermetrics-gagetrak','cal-reference-traceability','partially_supported',0.960,'GAGEtrak maintains detailed gage lifecycle and calibration histories, but metrological reference-chain depth is not inferred beyond the reviewed feature set.','https://gagetrak.com/features/'),
('cybermetrics-gagetrak','cal-asfound-asleft-oot','partially_supported',0.980,'GAGEtrak handles failed/out-of-tolerance calibration events and cost-curve analysis, but a full downstream impact-assessment workflow is not inferred.','https://gagetrak.com/features/'),
('cybermetrics-gagetrak','cal-certificates-esign','supported',0.990,'GAGEtrak provides calibration certificates, bar-coded labels and multi-level electronic calibration signatures.','https://gagetrak.com/features/'),
('cybermetrics-gagetrak','cal-regulated-audit','partially_supported',0.990,'GAGEtrak documents ISO/IEC 17025 and other quality standards; FDA 21 CFR Part 11 support requires the separate FDA Compliance Manager option.','https://gagetrak.com/features/'),
('cybermetrics-gagetrak','cal-enterprise-integration-scale','partially_supported',0.970,'GAGEtrak supports server/LAN deployment and optional Web API/MQTT integration, but global multi-site governance depth is not inferred from the reviewed product pages.','https://gagetrak.com/features/');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat135_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat135_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party vendor documentation supporting this capability.'
FROM cat135_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Promote deployment only where current product-specific evidence is explicit.
INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.990
FROM products p JOIN deployment_models d ON d.slug='on-premise'
WHERE p.slug IN('beamex-cmx','cybermetrics-gagetrak')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.990
FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug='prime-pcx'
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

-- Beamex CMX also documents cloud installation and IndySoft offers IndySoft Cloud, but those deployment forms are not automatically mapped to this catalog's public-SaaS label without clearer commercial-model evidence.
-- Fluke MET/TEAM browser access is not treated as evidence of a public-SaaS deployment model.
-- Platform-specific mobile support stays unknown: companion mobile/offline modules do not establish native Android/iOS/mobile-web support for the core product.
INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000
FROM products p CROSS JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') x
WHERE p.slug IN('beamex-cmx','fluke-metcal-metteam','indysoft-calibration-management','prime-pcx','cybermetrics-gagetrak')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

COMMIT;
