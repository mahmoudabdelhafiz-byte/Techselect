-- TechSelectAI Laboratory Information Management Systems catalog expansion.
-- Adds one canonical LIMS category and five evidence-backed current products.
-- Official first-party evidence reviewed Sep 2026. Presence is not an endorsement.
-- Unknown != Unsupported. No Fit Score, recommendation ranking, review score, follower/community popularity or commercial placement logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('Laboratory Information Management Systems (LIMS)','laboratory-information-management-systems','Laboratory informatics software for managing samples, testing workflows, instruments, inventory, stability and batch/lot quality, compliance, analytics and enterprise integration across manufacturing, pharma, chemicals, food, testing and research laboratories.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @lims_cat=(SELECT id FROM categories WHERE slug='laboratory-information-management-systems' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@lims_cat,'Laboratory Operations & Traceability','lims-lab-operations','Sample accessioning and chain of custody, laboratory workflow execution, instruments, inventory and manufacturing-quality testing workflows.',1),
(@lims_cat,'Compliance, Intelligence & Enterprise Connectivity','lims-compliance-connectivity','Regulated records, scheduling, analytics, multi-site governance and integration with ERP, MES, QMS and other enterprise systems.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.sec,1
FROM modules m JOIN (
 SELECT 'lims-lab-operations' module_slug,'Sample accessioning, tracking & chain of custody' name,'lims-sample-chain-custody' slug,'Register, identify, barcode, receive and trace samples and related lineage/location information from intake through testing and disposition.' description,0 sec UNION ALL
 SELECT 'lims-lab-operations','Test workflow, result review & laboratory execution','lims-test-workflow-execution','Configure and execute testing workflows, assign tests, capture/review results and enforce laboratory procedures from work request through final reporting.' description,0 UNION ALL
 SELECT 'lims-lab-operations','Instrument integration & laboratory automation','lims-instrument-integration','Connect analytical instruments, automation systems or scientific-data platforms for automated data capture, control, parsing or workflow exchange.',0 UNION ALL
 SELECT 'lims-lab-operations','Inventory, reagents, standards & consumables','lims-lab-inventory','Track reagents, standards, consumables, stock, lot numbers, locations, expiry, suppliers and laboratory-material usage where supported.',0 UNION ALL
 SELECT 'lims-lab-operations','Batch/lot quality, stability & certificate workflows','lims-batch-stability-coa','Support batch or lot testing, stability studies, product release, environmental monitoring or certificate-of-analysis workflows for manufacturing and regulated labs.',0 UNION ALL
 SELECT 'lims-compliance-connectivity','Audit trail, electronic signatures & regulated records','lims-regulated-records','Provide traceable audit history, access controls, electronic signatures or compliance-supporting records for regulated laboratory operations where explicitly documented.',1 UNION ALL
 SELECT 'lims-compliance-connectivity','Lab scheduling, workload & resource planning','lims-scheduling-resource-planning','Schedule samples, tests, analysts, instruments, work queues or other laboratory resources and workloads where supported.',0 UNION ALL
 SELECT 'lims-compliance-connectivity','Dashboards, analytics & laboratory KPIs','lims-analytics-kpis','Provide operational dashboards, reporting, trends, turnaround metrics, quality indicators or advanced laboratory analytics.',0 UNION ALL
 SELECT 'lims-compliance-connectivity','Multi-site & enterprise laboratory standardization','lims-multisite-enterprise','Standardize workflows, master data, visibility or governance across multiple laboratories, plants or locations where explicitly documented.',0 UNION ALL
 SELECT 'lims-compliance-connectivity','ERP, MES, QMS, SDMS & API integration','lims-enterprise-integration','Exchange laboratory, sample, product, result or quality data with ERP, MES, QMS, SDMS and other enterprise/scientific systems through supported interfaces or APIs.',0
) x ON x.module_slug=m.slug
WHERE m.category_id=@lims_cat
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('LabWare','labware','https://www.labware.com/','Laboratory information management and laboratory informatics software vendor.','active'),
('LabVantage Solutions','labvantage','https://www.labvantage.com/','Laboratory informatics, LIMS, ELN, LES and scientific-data software vendor.','active'),
('Thermo Fisher Scientific','thermo-fisher-scientific','https://www.thermofisher.com/','Scientific instruments and laboratory informatics software vendor.','active'),
('STARLIMS','starlims','https://www.starlims.com/','Laboratory information management and laboratory informatics software vendor.','active'),
('Sapio Sciences','sapio-sciences','https://www.sapiosciences.com/','Laboratory informatics, LIMS, ELN and scientific-data software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat127_products;
CREATE TEMPORARY TABLE cat127_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO cat127_products VALUES
('labware','laboratory-information-management-systems','LabWare LIMS','labware-lims','Enterprise LIMS for sample lifecycle, testing workflows, instrument connectivity, inventory, stability, lot/batch release, regulated records, dashboards and enterprise-system integration across manufacturing and testing laboratories.','https://www.labware.com/lims'),
('labvantage','laboratory-information-management-systems','LabVantage LIMS','labvantage-lims','Enterprise laboratory informatics platform for sample lifecycle, lab execution, instruments, scheduling, analytics, compliance and enterprise connectivity with both SaaS and on-premises deployment options.','https://www.labvantage.com/informatics/lims/'),
('thermo-fisher-scientific','laboratory-information-management-systems','Thermo Scientific SampleManager LIMS','thermo-samplemanager-lims','Laboratory management platform combining LIMS, SDMS and procedural LES capabilities for sample tracking, workflows, inventory, instruments, regulated records, analytics and enterprise integration.','https://www.thermofisher.com/order/catalog/product/INF-11000'),
('starlims','laboratory-information-management-systems','STARLIMS Quality Manufacturing LIMS','starlims-quality-manufacturing-lims','Quality-manufacturing LIMS for sample and batch testing, stability, environmental monitoring, inventory, instrument connectivity, regulated records, reporting and manufacturing-system integration.','https://www.starlims.com/rd-quality-manufacturing-informatics-platform/lims/'),
('sapio-sciences','laboratory-information-management-systems','Sapio LIMS','sapio-lims','Configurable LIMS for sample and workflow management, materials, instruments, chain of custody, analytics and GMP-oriented laboratory operations, with integrated scientific-data and no-code automation capabilities.','https://www.sapiosciences.com/products/lims/');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat127_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS cat127_sources;
CREATE TEMPORARY TABLE cat127_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat127_sources VALUES
('labware-lims','https://www.labware.com/lims','LabWare LIMS','LabWare'),
('labware-lims','https://www.labware.com/lims/self-hosted','LabWare Self-Hosted LIMS','LabWare'),
('labware-lims','https://www.labware.com/lims/saas','LabWare SaaS LIMS','LabWare'),
('labware-lims','https://www.labware.com/lims/integration','LabWare Integration Platform','LabWare'),
('labware-lims','https://www.labware.com/industries/process-chemical','LabWare Process and Chemical LIMS','LabWare'),
('labvantage-lims','https://www.labvantage.com/informatics/lims/','LabVantage LIMS','LabVantage Solutions'),
('labvantage-lims','https://www.labvantage.com/informatics/technology/','LabVantage LIMS Technology','LabVantage Solutions'),
('labvantage-lims','https://www.labvantage.com/informatics/ways-to-deploy/','LabVantage LIMS Deployment','LabVantage Solutions'),
('thermo-samplemanager-lims','https://www.thermofisher.com/order/catalog/product/INF-11000','Thermo Scientific SampleManager LIMS','Thermo Fisher Scientific'),
('thermo-samplemanager-lims','https://www.thermofisher.com/order/catalog/product/INF-11000/faqs','SampleManager LIMS FAQs','Thermo Fisher Scientific'),
('thermo-samplemanager-lims','https://documents.thermofisher.com/TFS-Assets/DSD/brochures/SampleManager-LIMS-Brochure-2025-EN.pdf','SampleManager LIMS Brochure','Thermo Fisher Scientific'),
('thermo-samplemanager-lims','https://www.thermofisher.com/us/en/home/digital-solutions/lab-informatics/lab-information-management-systems-lims/solutions/samplemanager/data-analytics.html','SampleManager Data Analytics','Thermo Fisher Scientific'),
('starlims-quality-manufacturing-lims','https://www.starlims.com/rd-quality-manufacturing-informatics-platform/lims/','STARLIMS Quality Manufacturing LIMS','STARLIMS'),
('starlims-quality-manufacturing-lims','https://www.starlims.com/resources/the-ultimate-lims-playbook-for-manufacturers/','STARLIMS Manufacturing LIMS Playbook','STARLIMS'),
('starlims-quality-manufacturing-lims','https://www.starlims.com/resources/digital-transformation-lab-4-0-git-article/','STARLIMS Lab 4.0 Integration','STARLIMS'),
('starlims-quality-manufacturing-lims','https://www.starlims.com/resources/lims-performance-improvements-qm-update/','STARLIMS QM Update','STARLIMS'),
('sapio-lims','https://www.sapiosciences.com/products/lims/','Sapio LIMS','Sapio Sciences'),
('sapio-lims','https://www.sapiosciences.com/solutions/gmp-lims/','Sapio GMP LIMS','Sapio Sciences'),
('sapio-lims','https://www.sapiosciences.com/solutions/sample-management/','Sapio Sample Management','Sapio Sciences'),
('sapio-lims','https://www.sapiosciences.com/products/sdms-scientific-data-cloud/','Sapio Scientific Data Cloud Integration','Sapio Sciences');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM cat127_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS cat127_facts;
CREATE TEMPORARY TABLE cat127_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat127_facts VALUES
-- LabWare LIMS
('labware-lims','lims-sample-chain-custody','supported',0.990,'LabWare documents sample login/management, sample tracking and chain-of-custody capabilities across laboratory workflows.','https://www.labware.com/lims'),
('labware-lims','lims-test-workflow-execution','supported',0.990,'LabWare manages testing workflows, work assignment, result entry/review and reporting from sample receipt through completion.','https://www.labware.com/lims'),
('labware-lims','lims-instrument-integration','supported',0.990,'LabWare documents direct, file-based, database and API-driven instrument/system integration through its Integration Platform.','https://www.labware.com/lims/integration'),
('labware-lims','lims-lab-inventory','supported',0.990,'LabWare manages laboratory inventory including quantity, location, expiry, vendor and stock requests/usage.','https://www.labware.com/lims'),
('labware-lims','lims-batch-stability-coa','supported',0.990,'LabWare documents lot/batch management, lot release, COA generation and approval plus stability-study workflows.','https://www.labware.com/lims'),
('labware-lims','lims-regulated-records','supported',0.990,'LabWare documents timestamped audit trails, electronic signatures, access controls and support for regulated laboratory compliance.','https://www.labware.com/lims'),
('labware-lims','lims-scheduling-resource-planning','supported',0.980,'LabWare documents schedulers, work assignment and stability/test scheduling; detailed workforce-optimization depth depends on configuration.','https://www.labware.com/lims/self-hosted'),
('labware-lims','lims-analytics-kpis','supported',0.990,'LabWare provides configurable dashboards, KPIs, reporting and data-analysis capabilities.','https://www.labware.com/lims'),
('labware-lims','lims-multisite-enterprise','supported',0.980,'LabWare explicitly positions LIMS for enterprise laboratories and standardization/visibility across multiple sites.','https://www.labware.com/lims'),
('labware-lims','lims-enterprise-integration','supported',0.990,'LabWare Integration Platform supports REST/JSON, XML, ASTM, HL7 and connections to ERP, MES and scientific systems.','https://www.labware.com/lims/integration'),

-- LabVantage LIMS
('labvantage-lims','lims-sample-chain-custody','supported',0.990,'LabVantage documents sample lifecycle, sample/consumables management, barcode generation and laboratory traceability.','https://www.labvantage.com/informatics/lims/'),
('labvantage-lims','lims-test-workflow-execution','supported',0.990,'LabVantage includes lab execution, workflow designer, ELN/LES integration, approvals and graphical workflows.','https://www.labvantage.com/informatics/lims/'),
('labvantage-lims','lims-instrument-integration','supported',0.990,'LabVantage supports instrument management, SDMS connectivity and instrument/system interfacing.','https://www.labvantage.com/informatics/technology/'),
('labvantage-lims','lims-lab-inventory','supported',0.980,'LabVantage documents sample and consumables management as part of the LIMS lifecycle; exact inventory depth varies by configured solution.','https://www.labvantage.com/informatics/lims/'),
('labvantage-lims','lims-batch-stability-coa','partially_supported',0.970,'LabVantage explicitly supports stability management and quality during batch/continuous manufacturing, but universal lot-release/COA workflow parity is not inferred from the reviewed core LIMS page.','https://www.labvantage.com/informatics/lims/'),
('labvantage-lims','lims-regulated-records','supported',0.990,'LabVantage documents electronic signatures, auditing, data integrity and support for regulated standards including GxP-oriented requirements.','https://www.labvantage.com/informatics/lims/'),
('labvantage-lims','lims-scheduling-resource-planning','supported',0.990,'LabVantage documents dynamic scheduling plus work and resource planning.','https://www.labvantage.com/informatics/lims/'),
('labvantage-lims','lims-analytics-kpis','supported',0.990,'LabVantage includes dashboards, reporting and advanced analytics within the laboratory informatics platform.','https://www.labvantage.com/informatics/lims/'),
('labvantage-lims','lims-multisite-enterprise','supported',0.980,'LabVantage supports centrally hosted global deployment, multiple locations and enterprise laboratory standardization.','https://www.labvantage.com/informatics/technology/'),
('labvantage-lims','lims-enterprise-integration','supported',0.990,'LabVantage documents SAP integration, RESTful web services and connectivity to ERP, MRP, MES, QMS and other enterprise systems.','https://www.labvantage.com/informatics/lims/'),

-- Thermo Scientific SampleManager LIMS
('thermo-samplemanager-lims','lims-sample-chain-custody','supported',0.990,'SampleManager supports sample receipt, barcode accessioning, tracking and chain of custody from receipt through report delivery.','https://www.thermofisher.com/order/catalog/product/INF-11000'),
('thermo-samplemanager-lims','lims-test-workflow-execution','supported',0.990,'SampleManager uses workflow-driven test planning and procedural LES/SOP execution with result tracking.','https://www.thermofisher.com/order/catalog/product/INF-11000/faqs'),
('thermo-samplemanager-lims','lims-instrument-integration','supported',0.990,'SampleManager integrates with instruments, equipment, CDS and enterprise data sources.','https://www.thermofisher.com/order/catalog/product/INF-11000'),
('thermo-samplemanager-lims','lims-lab-inventory','supported',0.990,'SampleManager manages stocks, reagents, standards, suppliers, lots, expiry and workflow consumption.','https://www.thermofisher.com/order/catalog/product/INF-11000/faqs'),
('thermo-samplemanager-lims','lims-batch-stability-coa','partially_supported',0.970,'Thermo Fisher provides SampleManager Stability and manufacturing/quality workflows, but the reviewed core product evidence does not establish universal lot-release/COA packaging for every deployment.','https://documents.thermofisher.com/TFS-Assets/DSD/brochures/SampleManager-LIMS-Brochure-2025-EN.pdf'),
('thermo-samplemanager-lims','lims-regulated-records','supported',0.990,'SampleManager documents configurable audit trails, compliant electronic signatures and regulated-record controls including 21 CFR Part 11/Annex 11 support.','https://www.thermofisher.com/order/catalog/product/INF-11000/faqs'),
('thermo-samplemanager-lims','lims-scheduling-resource-planning','supported',0.980,'SampleManager workflows assign tests to users and the platform manages resources/instruments; exact advanced resource-optimization depth is not inferred.','https://documents.thermofisher.com/TFS-Assets/DSD/brochures/SampleManager-LIMS-Brochure-2025-EN.pdf'),
('thermo-samplemanager-lims','lims-analytics-kpis','supported',0.990,'SampleManager provides data visualization and dedicated Data Analytics solutions including BI/AI options.','https://www.thermofisher.com/us/en/home/digital-solutions/lab-informatics/lab-information-management-systems-lims/solutions/samplemanager/data-analytics.html'),
('thermo-samplemanager-lims','lims-multisite-enterprise','supported',0.990,'Thermo Fisher explicitly documents SampleManager deployments from individual labs through global multi-site implementations.','https://www.thermofisher.com/order/catalog/product/INF-11000'),
('thermo-samplemanager-lims','lims-enterprise-integration','supported',0.990,'SampleManager integrates with ERP, PIMS, MES, CDS, instruments and equipment.','https://www.thermofisher.com/order/catalog/product/INF-11000'),

-- STARLIMS Quality Manufacturing LIMS
('starlims-quality-manufacturing-lims','lims-sample-chain-custody','supported',0.990,'STARLIMS Quality Manufacturing LIMS provides sample tracking and end-to-end testing workflows.','https://www.starlims.com/rd-quality-manufacturing-informatics-platform/lims/'),
('starlims-quality-manufacturing-lims','lims-test-workflow-execution','supported',0.990,'STARLIMS documents more than 15 out-of-the-box quality-manufacturing workflows including sample, batch, environmental and outsourced testing.','https://www.starlims.com/rd-quality-manufacturing-informatics-platform/lims/'),
('starlims-quality-manufacturing-lims','lims-instrument-integration','supported',0.990,'STARLIMS supports instrument connections and integration with laboratory and enterprise systems.','https://www.starlims.com/resources/digital-transformation-lab-4-0-git-article/'),
('starlims-quality-manufacturing-lims','lims-lab-inventory','supported',0.990,'STARLIMS Quality Manufacturing includes inventory/material management and current QM releases continue to maintain inventory-management workflows.','https://www.starlims.com/resources/lims-performance-improvements-qm-update/'),
('starlims-quality-manufacturing-lims','lims-batch-stability-coa','supported',0.990,'STARLIMS Quality Manufacturing explicitly documents batch testing with COA, stability, environmental testing and manufacturing-quality workflows.','https://www.starlims.com/rd-quality-manufacturing-informatics-platform/lims/'),
('starlims-quality-manufacturing-lims','lims-regulated-records','supported',0.990,'STARLIMS documents full audit trails and electronic signatures for quality-manufacturing compliance.','https://www.starlims.com/rd-quality-manufacturing-informatics-platform/lims/'),
('starlims-quality-manufacturing-lims','lims-scheduling-resource-planning','supported',0.980,'STARLIMS manufacturing documentation covers laboratory scheduling and resource/test planning; exact optimization depth depends on configured modules.','https://www.starlims.com/resources/the-ultimate-lims-playbook-for-manufacturers/'),
('starlims-quality-manufacturing-lims','lims-analytics-kpis','partially_supported',0.970,'STARLIMS includes extensive reporting and analysis; Advanced Analytics is a value-added/adjacent solution and is not assumed as universally bundled in core Quality Manufacturing LIMS.','https://www.starlims.com/rd-quality-manufacturing-informatics-platform/lims/'),
('starlims-quality-manufacturing-lims','lims-multisite-enterprise','supported',0.980,'STARLIMS documents integration of data from disparate laboratories and business systems across geographic locations.','https://www.starlims.com/resources/digital-transformation-lab-4-0-git-article/'),
('starlims-quality-manufacturing-lims','lims-enterprise-integration','supported',0.990,'STARLIMS interfaces with ERP, MES, PIMS, instruments and scientific systems using web services, file transfer and database communication.','https://www.starlims.com/resources/digital-transformation-lab-4-0-git-article/'),

-- Sapio LIMS
('sapio-lims','lims-sample-chain-custody','supported',0.990,'Sapio LIMS manages sample registration, real-time tracking, full lineage and chain of custody from test order through reporting.','https://www.sapiosciences.com/products/lims/'),
('sapio-lims','lims-test-workflow-execution','supported',0.990,'Sapio provides configurable no-code workflows, order processing, workflow automation and automated sample-processing rules.','https://www.sapiosciences.com/products/lims/'),
('sapio-lims','lims-instrument-integration','supported',0.990,'Sapio supports instrument integration and its Scientific Data Cloud documents automated collection from 200+ instruments plus flexible APIs.','https://www.sapiosciences.com/products/sdms-scientific-data-cloud/'),
('sapio-lims','lims-lab-inventory','supported',0.990,'Sapio LIMS includes materials and inventory management for reagents, locations, lots, expiry and ordering.','https://www.sapiosciences.com/products/lims/'),
('sapio-lims','lims-batch-stability-coa','partially_supported',0.980,'Sapio GMP LIMS explicitly covers QC batch creation, stability and environmental monitoring; universal COA/product-release scope across all Sapio LIMS editions is not inferred.','https://www.sapiosciences.com/solutions/gmp-lims/'),
('sapio-lims','lims-regulated-records','supported',0.980,'Sapio documents centralized audit trails and GMP/21 CFR Part 11/EU Annex 11 compliance capabilities in its regulated LIMS offerings.','https://www.sapiosciences.com/solutions/gmp-lims/'),
('sapio-lims','lims-scheduling-resource-planning','partially_supported',0.950,'Sapio supports workflow automation, test-plan scheduling and sample assignments, but a full laboratory resource-planning engine is not inferred from the reviewed evidence.','https://www.sapiosciences.com/solutions/gmp-lims/'),
('sapio-lims','lims-analytics-kpis','supported',0.990,'Sapio provides dashboards, charting, scientific reporting and advanced analytics across LIMS data.','https://www.sapiosciences.com/products/lims/'),
('sapio-lims','lims-multisite-enterprise','partially_supported',0.950,'Sapio positions the platform for organizations and multiple locations with enterprise-wide sample/material visibility, but explicit cross-site governance features are not inferred.','https://www.sapiosciences.com/products/lims/'),
('sapio-lims','lims-enterprise-integration','supported',0.980,'Sapio documents integration with instruments, IT systems and ERP through APIs and its unified data platform.','https://www.sapiosciences.com/solutions/sample-management/');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat127_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat127_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party vendor documentation supporting this capability.'
FROM cat127_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Promote deployment only where current product-specific evidence is explicit.
INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.990
FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug IN('labware-lims','labvantage-lims')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.990
FROM products p JOIN deployment_models d ON d.slug='on-premise'
WHERE p.slug IN('labware-lims','labvantage-lims','thermo-samplemanager-lims','sapio-lims')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

-- Hosted cloud or browser access is not automatically classified as public SaaS.
-- Platform-specific mobile access remains unknown for all five products.
INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000
FROM products p CROSS JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') x
WHERE p.slug IN('labware-lims','labvantage-lims','thermo-samplemanager-lims','starlims-quality-manufacturing-lims','sapio-lims')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

COMMIT;
