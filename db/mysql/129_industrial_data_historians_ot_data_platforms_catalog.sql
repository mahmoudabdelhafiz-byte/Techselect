-- TechSelectAI Industrial Data Historians & OT Data Platforms catalog expansion.
-- Adds one canonical historian/OT-data category and five evidence-backed current products.
-- Official first-party evidence reviewed Sep 2026. Presence is not an endorsement.
-- Unknown != Unsupported. No Fit Score, recommendation ranking, review score, follower/community popularity or commercial placement logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('Industrial Data Historians & OT Data Platforms','industrial-data-historians-ot-data-platforms','Industrial time-series and operations-data platforms for collecting, compressing, storing, contextualizing, visualizing and distributing plant and process data across OT and enterprise environments.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @hist_cat=(SELECT id FROM categories WHERE slug='industrial-data-historians-ot-data-platforms' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@hist_cat,'Historian Core & Industrial Data Collection','historian-core-collection','High-rate time-series ingestion, efficient historical storage, industrial connectivity, event/alarm capture and resilient data collection.',1),
(@hist_cat,'Context, Analysis & Enterprise Data Access','historian-context-enterprise','Asset/context modeling, visualization, calculations/analytics, APIs, enterprise federation and high-availability operations.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.sec,1
FROM modules m JOIN (
 SELECT 'historian-core-collection' module_slug,'High-rate time-series & operations-data ingestion' name,'hist-timeseries-ingestion' slug,'Collect and ingest industrial time-series, process, sensor or operations data at production scale.' description,0 sec UNION ALL
 SELECT 'historian-core-collection','Compression, archive & long-term historical storage','hist-compression-storage','Store large volumes of historical operations data efficiently using historian-native storage, compression or archival mechanisms.',0 UNION ALL
 SELECT 'historian-core-collection','Industrial collectors, protocols & source connectivity','hist-industrial-connectivity','Collect from PLCs, DCS, SCADA, OPC, MQTT, databases or other industrial/enterprise sources using supported collectors or interfaces.',0 UNION ALL
 SELECT 'historian-core-collection','Events, alarms & operational-event history','hist-events-alarms','Store, correlate, monitor or expose alarms, events, batch events or other operational-event information alongside time-series data.',0 UNION ALL
 SELECT 'historian-core-collection','Store-and-forward / resilient data collection','hist-store-forward','Buffer and recover data during network or source disruptions to preserve historical continuity where explicitly supported.',0 UNION ALL
 SELECT 'historian-context-enterprise','Asset models, metadata & data contextualization','hist-contextualization','Organize historian tags and data using asset models, metadata, hierarchies or contextual structures that make raw operations data easier to consume.',0 UNION ALL
 SELECT 'historian-context-enterprise','Trends, dashboards & operational visualization','hist-visualization-trending','Provide or integrate historian-oriented trends, dashboards, process displays and self-service visualization for operations data.',0 UNION ALL
 SELECT 'historian-context-enterprise','Calculations, KPIs & historian analytics','hist-calculations-analytics','Create calculated tags, aggregates, events, KPIs, statistics or other historian-native analytical outputs where supported.',0 UNION ALL
 SELECT 'historian-context-enterprise','APIs, data feeds & enterprise integration','hist-api-enterprise-integration','Expose current and historical data through APIs, SDKs, SQL/ODBC, connectors or other interfaces to BI, AI, ERP, MES, cloud and enterprise applications.',0 UNION ALL
 SELECT 'historian-context-enterprise','Multi-site federation, redundancy & enterprise scale','hist-enterprise-scale-ha','Scale historian/data access across multiple plants or sites and support redundancy, failover or centralized enterprise operations where explicitly documented.',0
) x ON x.module_slug=m.slug
WHERE m.category_id=@hist_cat
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('AVEVA','aveva','https://www.aveva.com/','Industrial software and operations-data platform vendor.','active'),
('Canary Labs','canary-labs','https://www.canarylabs.com/','Industrial historian and operations-data software vendor.','active'),
('GE Vernova','ge-vernova','https://www.gevernova.com/','Energy and industrial software provider including Proficy historian products.','active'),
('Aspen Technology','aspentech','https://www.aspentech.com/','Industrial process optimization and operations-data software vendor.','active'),
('Honeywell','honeywell','https://www.honeywell.com/','Industrial automation, controls and operations-data software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat129_products;
CREATE TEMPORARY TABLE cat129_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO cat129_products VALUES
('aveva','industrial-data-historians-ot-data-platforms','AVEVA PI System','aveva-pi-system','Operations-data infrastructure for collecting, storing, enriching, contextualizing, visualizing and distributing real-time and historical industrial data across assets, plants and enterprise applications.','https://www.aveva.com/en/products/aveva-pi-system/'),
('canary-labs','industrial-data-historians-ot-data-platforms','Canary Historian','canary-historian','Industrial historian and data platform for lossless time-series storage, OPC/MQTT/SQL collection, store-and-forward, asset modeling, calculations, events, visualization and APIs.','https://www.canarylabs.com/product/step-1.html'),
('ge-vernova','industrial-data-historians-ot-data-platforms','Proficy Historian','proficy-historian','Industrial operations historian for high-speed time-series and alarm/event collection, compression, cloud or on-prem storage, retrieval, analysis and enterprise data distribution.','https://www.gevernova.com/software/products/proficy/historian'),
('aspentech','industrial-data-historians-ot-data-platforms','Aspen InfoPlus.21','aspen-infoplus21','Real-time industrial process historian for collecting, storing, organizing, visualizing and analyzing continuous and batch process data across process-industry operations.','https://www.aspentech.com/en/products/msc/aspen-infoplus21'),
('honeywell','industrial-data-historians-ot-data-platforms','Honeywell Uniformance PHD','honeywell-uniformance-phd','Process History Database for collecting, storing and replaying long-term industrial process and event data across distributed plants and enterprise operations, with analytics and integration through the Uniformance ecosystem.','https://process.honeywell.com/us/en/products/industrial-software/operational-excellence/enterprise-data-management');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat129_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS cat129_sources;
CREATE TEMPORARY TABLE cat129_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat129_sources VALUES
('aveva-pi-system','https://www.aveva.com/en/products/aveva-pi-system/','AVEVA PI System','AVEVA'),
('aveva-pi-system','https://www.aveva.com/en/perspectives/blog/historian-vs-data-infrastructure-what-s-the-difference/','Historian vs Data Infrastructure','AVEVA'),
('canary-historian','https://www.canarylabs.com/product/step-1.html','Canary Historian - Collect and Store','Canary Labs'),
('canary-historian','https://www.canarylabs.com/product/data-collectors','Canary Data Collectors','Canary Labs'),
('canary-historian','https://www.canarylabs.com/product','Canary Industrial Data Platform','Canary Labs'),
('canary-historian','https://www.canarylabs.com/product/virtual-views','Canary Virtual Views','Canary Labs'),
('canary-historian','https://www.canarylabs.com/product/calculation-server.html','Canary Calculation Server','Canary Labs'),
('canary-historian','https://www.canarylabs.com/product/axiom','Canary Axiom','Canary Labs'),
('proficy-historian','https://www.gevernova.com/software/products/proficy/historian','Proficy Historian','GE Vernova'),
('proficy-historian','https://www.gevernova.com/software/products/proficy/historian/cloud','Proficy Historian for Cloud','GE Vernova'),
('proficy-historian','https://www.gevernova.com/software/resources/webinar/proficy-2026','Proficy Historian 2026','GE Vernova'),
('aspen-infoplus21','https://www.aspentech.com/en/products/msc/aspen-infoplus21','Aspen InfoPlus.21','AspenTech'),
('aspen-infoplus21','https://www.aspentech.com/en/resources/brochure/aspen-infoplus-21','Aspen InfoPlus.21 Brochure','AspenTech'),
('honeywell-uniformance-phd','https://process.honeywell.com/us/en/products/industrial-software/operational-excellence/enterprise-data-management','Honeywell Enterprise Data Management - Uniformance PHD','Honeywell'),
('honeywell-uniformance-phd','https://process.honeywell.com/content/process/us/en/products/trainings/honeywell-connected-industrial/uniformance-phd-uni','Uniformance PHD','Honeywell'),
('honeywell-uniformance-phd','https://process.honeywell.com/content/dam/process/en/documents/training-docs/honeywell-connected-industrial/uni/UNI-0004-Uniformance-PHD-Advanced-Interfaces-And-System-Administration.pdf','Uniformance PHD Advanced Interfaces and System Administration','Honeywell');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM cat129_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS cat129_facts;
CREATE TEMPORARY TABLE cat129_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat129_facts VALUES
-- AVEVA PI System
('aveva-pi-system','hist-timeseries-ingestion','supported',0.990,'AVEVA PI System collects real-time operations data from industrial assets and sources with sub-second granularity.','https://www.aveva.com/en/products/aveva-pi-system/'),
('aveva-pi-system','hist-compression-storage','supported',0.990,'PI System provides scalable time-series storage for historical real-time operations data.','https://www.aveva.com/en/products/aveva-pi-system/'),
('aveva-pi-system','hist-industrial-connectivity','supported',0.990,'AVEVA documents broad vendor-neutral connectivity for collecting operations data from many industrial sources.','https://www.aveva.com/en/products/aveva-pi-system/'),
('aveva-pi-system','hist-contextualization','supported',0.990,'PI System enriches and contextualizes operations data using asset-oriented structures and metadata.','https://www.aveva.com/en/products/aveva-pi-system/'),
('aveva-pi-system','hist-visualization-trending','supported',0.990,'PI System includes configurable operations-data visualization and dashboard capabilities through the PI portfolio.','https://www.aveva.com/en/products/aveva-pi-system/'),
('aveva-pi-system','hist-calculations-analytics','supported',0.980,'PI System supports foundational analysis, event tracking, notifications and processing of historical and real-time data; advanced AI/ML remains external/adjacent unless separately licensed.','https://www.aveva.com/en/products/aveva-pi-system/'),
('aveva-pi-system','hist-api-enterprise-integration','supported',0.990,'AVEVA documents delivery of trusted operations data to remote users, applications, BI, analytics and AI tools.','https://www.aveva.com/en/products/aveva-pi-system/'),
('aveva-pi-system','hist-enterprise-scale-ha','supported',0.980,'PI System is positioned as enterprise operations-data infrastructure supporting complex multi-asset and multi-site environments; exact redundancy architecture depends on deployed components.','https://www.aveva.com/en/perspectives/blog/historian-vs-data-infrastructure-what-s-the-difference/'),

-- Canary Historian
('canary-historian','hist-timeseries-ingestion','supported',0.990,'Canary Historian is designed for high-throughput industrial time-series collection and storage.','https://www.canarylabs.com/product/step-1.html'),
('canary-historian','hist-compression-storage','supported',0.990,'Canary explicitly documents lossless compression, scalable historian storage and performance that is independent of archive size.','https://www.canarylabs.com/product'),
('canary-historian','hist-industrial-connectivity','supported',0.990,'Canary collectors support OPC DA, OPC UA, MQTT Sparkplug B, SCADA systems, SQL databases, CSV and custom APIs.','https://www.canarylabs.com/product/data-collectors'),
('canary-historian','hist-events-alarms','supported',0.980,'Canary Event Monitoring can create condition-based asset events and retain event metadata and statistics; alarm-event-system parity with SCADA alarm historians is not inferred.','https://www.canarylabs.com/product'),
('canary-historian','hist-store-forward','supported',0.990,'Canary documents store-and-forward buffering to preserve data delivery through network disruptions.','https://www.canarylabs.com/product/step-1.html'),
('canary-historian','hist-contextualization','supported',0.990,'Canary Virtual Views create asset models and metadata-based contextual views without changing archived tags.','https://www.canarylabs.com/product/virtual-views'),
('canary-historian','hist-visualization-trending','supported',0.990,'Canary Axiom provides HTML-based trends, dashboards, reports, playback and visualization.','https://www.canarylabs.com/product/axiom'),
('canary-historian','hist-calculations-analytics','supported',0.990,'Canary Calculation Server creates calculated tags, aggregates and asset-model calculations that can be backfilled.','https://www.canarylabs.com/product/calculation-server.html'),
('canary-historian','hist-api-enterprise-integration','supported',0.990,'Canary exposes historian data through MQTT publishing, JSON/WebSocket, gRPC, Web API, ODBC and other data feeds.','https://www.canarylabs.com/product'),

-- Proficy Historian
('proficy-historian','hist-timeseries-ingestion','supported',0.990,'Proficy Historian collects industrial operations time-series and alarm/event data at very high speed.','https://www.gevernova.com/software/products/proficy/historian'),
('proficy-historian','hist-compression-storage','supported',0.990,'GE Vernova documents proprietary file-based storage and advanced compression for efficient historian retention.','https://www.gevernova.com/software/products/proficy/historian'),
('proficy-historian','hist-industrial-connectivity','supported',0.980,'Proficy Historian uses collectors and industrial data interfaces for plant data ingestion; exact collector availability varies by product edition and release.','https://www.gevernova.com/software/resources/webinar/proficy-2026'),
('proficy-historian','hist-events-alarms','supported',0.990,'Proficy Historian explicitly collects and stores A&E data alongside industrial time-series information.','https://www.gevernova.com/software/products/proficy/historian'),
('proficy-historian','hist-visualization-trending','partially_supported',0.960,'Historian provides retrieval and analysis, while richer web visualization is delivered through connected Proficy products such as Operations Hub rather than assumed core entitlement.','https://www.gevernova.com/software/products/proficy'),
('proficy-historian','hist-calculations-analytics','partially_supported',0.970,'Historian enables fast retrieval and analysis, but advanced analytics/AI are provided through adjacent Proficy analytics products and are not treated as core Historian entitlement.','https://www.gevernova.com/software/products/proficy'),
('proficy-historian','hist-api-enterprise-integration','supported',0.980,'Proficy Historian distributes industrial data for downstream applications and analytics across cloud or on-prem environments.','https://www.gevernova.com/software/products/proficy/historian'),
('proficy-historian','hist-enterprise-scale-ha','supported',0.990,'GE Vernova documents high availability, scalability and cloud/on-prem architectures, including very high ingestion scale.','https://www.gevernova.com/software/products/proficy/historian'),

-- Aspen InfoPlus.21
('aspen-infoplus21','hist-timeseries-ingestion','supported',0.990,'Aspen InfoPlus.21 is a real-time historian that collects and merges large-scale industrial time-series data.','https://www.aspentech.com/en/products/msc/aspen-infoplus21'),
('aspen-infoplus21','hist-compression-storage','supported',0.980,'Aspen IP.21 stores large-scale process historian data for long-term monitoring and analysis; exact compression implementation is not inferred from the reviewed page.','https://www.aspentech.com/en/resources/brochure/aspen-infoplus-21'),
('aspen-infoplus21','hist-industrial-connectivity','partially_supported',0.960,'IP.21 collects process data across industrial operations and applications, but a current public collector/protocol matrix is not inferred from the reviewed product evidence.','https://www.aspentech.com/en/products/msc/aspen-infoplus21'),
('aspen-infoplus21','hist-contextualization','supported',0.980,'IP.21 organizes operations data into tailored record structures for process and asset analysis.','https://www.aspentech.com/en/products/msc/aspen-infoplus21'),
('aspen-infoplus21','hist-visualization-trending','partially_supported',0.980,'Aspen provides process visualization through aspenONE Process Explorer, which is a related product rather than assumed universally bundled in IP.21.','https://www.aspentech.com/en/products/msc/aspen-infoplus21'),
('aspen-infoplus21','hist-calculations-analytics','supported',0.990,'IP.21 includes real-time computation engines for KPI and SPC/SQC analysis and supports advanced analytics over historian data.','https://www.aspentech.com/en/products/msc/aspen-infoplus21'),
('aspen-infoplus21','hist-api-enterprise-integration','partially_supported',0.960,'IP.21 is designed to disseminate operations data across the organization, but a current public API/connector catalogue is not inferred from the reviewed sources.','https://www.aspentech.com/en/products/msc/aspen-infoplus21'),
('aspen-infoplus21','hist-enterprise-scale-ha','supported',0.980,'Aspen documents scalable infrastructure and enterprise-wide benchmarking/collaboration across industrial operations.','https://www.aspentech.com/en/products/msc/aspen-infoplus21'),

-- Honeywell Uniformance PHD
('honeywell-uniformance-phd','hist-timeseries-ingestion','supported',0.990,'Uniformance PHD collects and stores historical and continuous plant process data from distributed control and industrial data sources.','https://process.honeywell.com/us/en/products/industrial-software/operational-excellence/enterprise-data-management'),
('honeywell-uniformance-phd','hist-compression-storage','supported',0.980,'Honeywell positions PHD as long-term process-data storage with archive management and history recovery; specific compression algorithms are not inferred.','https://process.honeywell.com/content/dam/process/en/documents/training-docs/honeywell-connected-industrial/uni/UNI-0004-Uniformance-PHD-Advanced-Interfaces-And-System-Administration.pdf'),
('honeywell-uniformance-phd','hist-industrial-connectivity','supported',0.990,'Uniformance PHD integrates with control systems and third-party data sources using RDIs, links, OPC and other interfaces.','https://process.honeywell.com/content/dam/process/en/documents/training-docs/honeywell-connected-industrial/uni/UNI-0004-Uniformance-PHD-Advanced-Interfaces-And-System-Administration.pdf'),
('honeywell-uniformance-phd','hist-events-alarms','supported',0.980,'Uniformance PHD includes Consolidated Event Journal capabilities for operational alarms, events and process changes.','https://process.honeywell.com/content/dam/process/en/documents/training-docs/honeywell-connected-industrial/uni/UNI-0004-Uniformance-PHD-Advanced-Interfaces-And-System-Administration.pdf'),
('honeywell-uniformance-phd','hist-store-forward','supported',0.980,'Honeywell documents robust data collection with backup shadow-server behavior, collection failover and automatic history recovery.','https://process.honeywell.com/us/en/products/industrial-software/operational-excellence/enterprise-data-management'),
('honeywell-uniformance-phd','hist-visualization-trending','partially_supported',0.980,'Process visualization and trending are delivered through Uniformance Insight and Process Studio, which are companion components rather than assumed PHD core entitlement.','https://process.honeywell.com/us/en/products/industrial-software/operational-excellence/enterprise-data-management'),
('honeywell-uniformance-phd','hist-calculations-analytics','partially_supported',0.970,'PHD supports virtual tags and on-demand calculations, while broader KPI/analytics capabilities are delivered through additional Uniformance products.','https://process.honeywell.com/content/dam/process/en/documents/training-docs/honeywell-connected-industrial/uni/UNI-0004-Uniformance-PHD-Advanced-Interfaces-And-System-Administration.pdf'),
('honeywell-uniformance-phd','hist-api-enterprise-integration','supported',0.990,'Honeywell documents PHD APIs including .NET, OLE DB and application data access for enterprise integration.','https://process.honeywell.com/content/dam/process/en/documents/training-docs/honeywell-connected-industrial/uni/UNI-0004-Uniformance-PHD-Advanced-Interfaces-And-System-Administration.pdf'),
('honeywell-uniformance-phd','hist-enterprise-scale-ha','supported',0.990,'PHD supports collection across multiple plants/sites plus failover, shadow-server and enterprise consolidation architectures.','https://process.honeywell.com/us/en/products/industrial-software/operational-excellence/enterprise-data-management');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat129_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat129_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party vendor documentation supporting this capability.'
FROM cat129_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Promote deployment only where the current product-specific evidence is explicit.
INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.990
FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug='proficy-historian'
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.990
FROM products p JOIN deployment_models d ON d.slug='on-premise'
WHERE p.slug='proficy-historian'
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

-- Do not infer mobile platforms from browser/dashboard access.
INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000
FROM products p CROSS JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') x
WHERE p.slug IN('aveva-pi-system','canary-historian','proficy-historian','aspen-infoplus21','honeywell-uniformance-phd')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

COMMIT;
