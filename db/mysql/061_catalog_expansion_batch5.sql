-- TechSelectAI catalog expansion batch 5 for #259
-- Adds Observability/APM, Network Monitoring, Transportation Management Systems,
-- Document Management, and E-signature.
-- New products are seeded as DRAFT and use official vendor-owned sources only.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('Observability & APM','observability-apm','Application performance monitoring and observability platforms for metrics, traces, logs, dependencies, errors and service performance.',1),
('Network Monitoring','network-monitoring','Network availability, device health, performance, traffic and path monitoring software for enterprise infrastructure.',1),
('Transportation Management Systems','transportation-management-systems','Transportation management software for freight planning, carrier execution, shipment visibility, optimization and transportation operations.',1),
('Document Management','document-management','Enterprise document and content management platforms for storing, finding, governing, collaborating on and automating document-centric work.',1),
('E-signature','e-signature','Electronic signature platforms for preparing, sending, signing, routing and tracking business documents and agreements.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO modules(category_id,name,slug,description,is_active)
SELECT c.id,x.name,x.slug,x.description,1 FROM categories c JOIN (
 SELECT 'observability-apm' cat,'Application Observability' name,'apm-application-observability' slug,'Application performance, service health, errors and transaction visibility.' description UNION ALL
 SELECT 'observability-apm','Telemetry & Diagnostics','apm-telemetry-diagnostics','Distributed traces, logs, metrics, dependencies and diagnostic telemetry.' UNION ALL
 SELECT 'network-monitoring','Network Health','network-health','Device discovery, availability, health, faults and performance monitoring.' UNION ALL
 SELECT 'network-monitoring','Network Analysis','network-analysis','Traffic, paths, topology, capacity and troubleshooting analysis.' UNION ALL
 SELECT 'transportation-management-systems','Transportation Planning','tms-planning','Freight planning, routing, mode/carrier selection and optimization.' UNION ALL
 SELECT 'transportation-management-systems','Transportation Execution','tms-execution','Shipment execution, visibility, carrier collaboration, freight cost and exception workflows.' UNION ALL
 SELECT 'document-management','Content & Documents','dms-content','Document storage, metadata, search, versioning and collaboration.' UNION ALL
 SELECT 'document-management','Workflow & Governance','dms-governance','Content workflows, permissions, retention, governance and lifecycle controls.' UNION ALL
 SELECT 'e-signature','Signing Workflows','esign-workflows','Prepare, route, send and complete electronic signature requests.' UNION ALL
 SELECT 'e-signature','Signing Administration','esign-administration','Templates, tracking, audit trails, integrations and signing administration.'
) x ON x.cat=c.slug
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.sec,1 FROM modules m JOIN (
 SELECT 'apm-application-observability' ms,'Application performance metrics' name,'apm-performance-metrics' slug,'Monitor application response time, throughput, errors and service performance.' description,0 sec UNION ALL
 SELECT 'apm-application-observability','Service dependency / topology visibility','apm-service-dependencies','Visualize service relationships, dependencies or application topology.',0 UNION ALL
 SELECT 'apm-telemetry-diagnostics','Distributed tracing','apm-distributed-tracing','Trace requests across services, dependencies and distributed application components.',0 UNION ALL
 SELECT 'apm-telemetry-diagnostics','Logs / metrics / traces correlation','apm-telemetry-correlation','Correlate multiple telemetry types for troubleshooting and root-cause analysis.',0 UNION ALL
 SELECT 'apm-telemetry-diagnostics','Error / root-cause analysis','apm-root-cause','Identify errors, anomalies, bottlenecks or root causes affecting application performance.',0 UNION ALL
 SELECT 'network-health','Device discovery & inventory','network-device-discovery','Discover and inventory monitored network devices and infrastructure.',0 UNION ALL
 SELECT 'network-health','Availability & health monitoring','network-availability-health','Monitor device availability, health and operational status.',0 UNION ALL
 SELECT 'network-health','Network performance metrics','network-performance-metrics','Monitor latency, packet loss, utilization and other network performance indicators.',0 UNION ALL
 SELECT 'network-analysis','Alerts & fault management','network-alerts-faults','Detect network faults and notify operators through configurable alerts.',0 UNION ALL
 SELECT 'network-analysis','Traffic / path / topology analysis','network-traffic-path','Analyze traffic, paths, flows or topology to troubleshoot network performance.',0 UNION ALL
 SELECT 'tms-planning','Transportation planning & routing','tms-planning-routing','Plan routes, loads, modes, schedules or transportation requirements.',0 UNION ALL
 SELECT 'tms-planning','Carrier / mode selection & optimization','tms-carrier-optimization','Select and optimize carriers, modes, capacity or freight plans.',0 UNION ALL
 SELECT 'tms-execution','Shipment execution & tendering','tms-shipment-execution','Create, tender, book, dispatch or execute transportation shipments.',0 UNION ALL
 SELECT 'tms-execution','Shipment visibility & exception management','tms-shipment-visibility','Track shipment status, milestones, exceptions and execution progress.',0 UNION ALL
 SELECT 'tms-execution','Freight cost / settlement management','tms-freight-cost','Manage transportation rates, charges, audit, settlement or freight cost processes.',0 UNION ALL
 SELECT 'dms-content','Central document / content repository','dms-repository','Store and manage enterprise documents and content in a controlled repository.',1 UNION ALL
 SELECT 'dms-content','Metadata & enterprise search','dms-metadata-search','Classify, find and retrieve documents using metadata, search or contextual information.',0 UNION ALL
 SELECT 'dms-content','Versioning & collaboration','dms-version-collaboration','Support document versions, sharing, editing or collaborative content work.',0 UNION ALL
 SELECT 'dms-governance','Document workflow / automation','dms-workflow','Route, approve or automate document-centric processes and work.',0 UNION ALL
 SELECT 'dms-governance','Permissions, retention & governance','dms-governance-controls','Control document access, lifecycle, retention, records or governance policies.',1 UNION ALL
 SELECT 'esign-workflows','Send / request electronic signatures','esign-send-request','Prepare documents and request electronic signatures from recipients.',1 UNION ALL
 SELECT 'esign-workflows','Multi-recipient routing / signing order','esign-routing','Route signing requests across one or more recipients or workflow steps.',0 UNION ALL
 SELECT 'esign-administration','Templates / reusable agreements','esign-templates','Create reusable document or agreement templates for signing workflows.',0 UNION ALL
 SELECT 'esign-administration','Status tracking & audit trail','esign-audit-tracking','Track signing status and preserve audit or completion evidence.',1 UNION ALL
 SELECT 'esign-administration','APIs / business application integrations','esign-integrations','Integrate signing workflows with business applications, APIs or automation tools.',0
) x ON x.ms=m.slug
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Datadog','datadog','https://www.datadoghq.com/','Observability, monitoring and security platform vendor.','active'),
('New Relic','new-relic','https://newrelic.com/','Observability and application monitoring platform vendor.','active'),
('Dynatrace','dynatrace','https://www.dynatrace.com/','Enterprise observability and application performance platform vendor.','active'),
('Elastic','elastic','https://www.elastic.co/','Search, observability and security software vendor.','active'),
('SolarWinds','solarwinds','https://www.solarwinds.com/','IT infrastructure and network management software vendor.','active'),
('ManageEngine','manageengine','https://www.manageengine.com/','Enterprise IT operations, security and management software vendor.','active'),
('LogicMonitor','logicmonitor','https://www.logicmonitor.com/','Infrastructure observability and network monitoring vendor.','active'),
('SAP','sap','https://www.sap.com/','Enterprise application and supply-chain software vendor.','active'),
('Oracle','oracle','https://www.oracle.com/','Enterprise application, cloud and supply-chain software vendor.','active'),
('Blue Yonder','blue-yonder','https://blueyonder.com/','Supply-chain planning and execution software vendor.','active'),
('Descartes Systems Group','descartes','https://www.descartes.com/','Logistics and transportation management software vendor.','active'),
('Microsoft','microsoft','https://www.microsoft.com/','Enterprise productivity, cloud, content and application software vendor.','active'),
('M-Files','m-files','https://www.m-files.com/','Enterprise document management and information governance software vendor.','active'),
('OpenText','opentext','https://www.opentext.com/','Enterprise information and content management software vendor.','active'),
('Box','box','https://www.box.com/','Enterprise intelligent content management and collaboration vendor.','active'),
('Docusign','docusign','https://www.docusign.com/','Electronic signature and agreement management software vendor.','active'),
('Adobe','adobe','https://www.adobe.com/','Digital document, creative and electronic signature software vendor.','active'),
('Dropbox','dropbox','https://www.dropbox.com/','Cloud content, collaboration and electronic signature software vendor.','active'),
('Zoho','zoho','https://www.zoho.com/','Business software suite and electronic signature vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat61_products;
CREATE TEMPORARY TABLE cat61_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,source_url TEXT,source_title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat61_products VALUES
('datadog','observability-apm','Datadog APM','datadog-apm','Application performance monitoring for distributed tracing, service performance, code-level diagnostics and correlated observability telemetry.','https://www.datadoghq.com/product/apm/','Datadog Application Performance Monitoring','Datadog'),
('new-relic','observability-apm','New Relic APM 360','new-relic-apm-360','Application performance monitoring with service health, distributed tracing, errors, dependencies and full-stack telemetry correlation.','https://newrelic.com/platform/application-monitoring','New Relic Application Monitoring','New Relic'),
('dynatrace','observability-apm','Dynatrace Application Observability','dynatrace-application-observability','Application observability and performance monitoring with automatic dependency discovery, transaction visibility and AI-assisted root-cause analysis.','https://www.dynatrace.com/platform/application-observability/','Dynatrace Application Observability','Dynatrace'),
('elastic','observability-apm','Elastic APM','elastic-apm','Application performance monitoring built on the Elastic Stack for transactions, errors, metrics, dependencies and distributed application diagnostics.','https://www.elastic.co/docs/solutions/observability/apm','Elastic APM','Elastic'),
('solarwinds','network-monitoring','SolarWinds Network Performance Monitor','solarwinds-network-performance-monitor','Network performance monitoring for multi-vendor device discovery, availability, health, latency, packet loss and network path troubleshooting.','https://www.solarwinds.com/network-performance-monitor','SolarWinds Network Performance Monitor','SolarWinds'),
('manageengine','network-monitoring','ManageEngine OpManager','manageengine-opmanager','Network monitoring platform for routers, switches, firewalls, servers and other infrastructure with performance, fault, dashboard and alerting capabilities.','https://www.manageengine.com/network-monitoring/','ManageEngine OpManager','ManageEngine'),
('datadog','network-monitoring','Datadog Network Monitoring','datadog-network-monitoring','Cloud and hybrid network monitoring for traffic, dependencies, performance and network telemetry correlated with infrastructure and applications.','https://www.datadoghq.com/product/network-monitoring/','Datadog Network Monitoring','Datadog'),
('logicmonitor','network-monitoring','LogicMonitor Network Monitoring','logicmonitor-network-monitoring','Network monitoring for cloud, data center, edge and internet-connected infrastructure with automated discovery, health visibility and troubleshooting.','https://www.logicmonitor.com/network-monitoring','LogicMonitor Network Monitoring','LogicMonitor'),
('sap','transportation-management-systems','SAP Transportation Management','sap-transportation-management','Transportation management application for transportation planning, freight tendering, execution, visibility and freight settlement across logistics networks.','https://www.sap.com/mena/products/scm/transportation-logistics.html','SAP Transportation Management','SAP'),
('oracle','transportation-management-systems','Oracle Transportation Management','oracle-transportation-management','Global transportation management system for multimodal planning, carrier collaboration, shipment execution, visibility and logistics optimization.','https://docs.oracle.com/en/cloud/saas/transportation/26b/','Oracle Transportation Management','Oracle'),
('blue-yonder','transportation-management-systems','Blue Yonder Transportation Management','blue-yonder-transportation-management','Transportation management solution for multimodal planning, optimization, execution, trading-partner connectivity and transportation operations.','https://blueyonder.com/solutions/transportation-management','Blue Yonder Transportation Management','Blue Yonder'),
('descartes','transportation-management-systems','Descartes Transportation Manager','descartes-transportation-manager','Multimodal transportation management for shipment planning, carrier selection, execution, visibility, freight audit and logistics optimization.','https://www.descartes.com/solutions/transportation-management/tms?language=en','Descartes Transportation Manager','Descartes'),
('microsoft','document-management','Microsoft SharePoint','microsoft-sharepoint','Microsoft 365 content and document management platform for storing, managing, finding, sharing and governing organizational content.','https://www.microsoft.com/en-us/microsoft-365/content-management-solutions','Microsoft 365 Content Management Solutions','Microsoft'),
('m-files','document-management','M-Files','m-files-document-management','Metadata-driven enterprise document management for contextual search, document lifecycle, workflow automation, governance and Microsoft 365 work.','https://www.m-files.com/m-files-platform/','M-Files Platform','M-Files'),
('opentext','document-management','OpenText Content Management','opentext-content-management','Enterprise content management for document capture, organization, version control, business workspaces, governance and content-centric processes.','https://www.opentext.com/products/content-management','OpenText Content Management','OpenText'),
('box','document-management','Box','box-intelligent-content-management','Enterprise intelligent content management platform for secure document storage, search, collaboration, governance, workflow and AI-enabled content work.','https://www.box.com/overview','Box Intelligent Content Management','Box'),
('docusign','e-signature','Docusign eSignature','docusign-esignature','Electronic signature platform for preparing, sending, routing, signing and tracking business agreements with templates, verification and integrations.','https://www.docusign.com/products/electronic-signature','Docusign eSignature','Docusign'),
('adobe','e-signature','Adobe Acrobat Sign','adobe-acrobat-sign','Electronic signature solution for sending, signing, routing, tracking and managing digital agreements across business workflows.','https://www.adobe.com/acrobat/business/sign.html','Adobe Acrobat Sign','Adobe'),
('dropbox','e-signature','Dropbox Sign','dropbox-sign','Cloud electronic signature service for sending signature requests, signing documents, templates and tracking completed agreements.','https://help.dropbox.com/en-us/sign','Dropbox Sign','Dropbox'),
('zoho','e-signature','Zoho Sign','zoho-sign','Electronic and digital signature platform for sending, signing, managing and tracking documents with workflows, templates and integrations.','https://www.zoho.com/sign/','Zoho Sign','Zoho');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.source_url,'draft',NOW()
FROM cat61_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),short_description=VALUES(short_description),website_url=VALUES(website_url),last_reviewed_at=NOW();

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',x.source_url,x.source_title,x.publisher,1,'verified','high',NOW()
FROM cat61_products x JOIN products p ON p.slug=x.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=x.source_url);

DROP TEMPORARY TABLE IF EXISTS cat61_facts;
CREATE TEMPORARY TABLE cat61_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3));

-- Core APM facts verified across all four official product sources.
INSERT INTO cat61_facts
SELECT p.product_slug,c.capability_slug,'supported',0.92 FROM
(SELECT 'datadog-apm' product_slug UNION ALL SELECT 'new-relic-apm-360' UNION ALL SELECT 'dynatrace-application-observability' UNION ALL SELECT 'elastic-apm') p
CROSS JOIN
(SELECT 'apm-performance-metrics' capability_slug UNION ALL SELECT 'apm-distributed-tracing' UNION ALL SELECT 'apm-root-cause') c;
INSERT INTO cat61_facts VALUES
('datadog-apm','apm-telemetry-correlation','supported',0.98),('new-relic-apm-360','apm-telemetry-correlation','supported',0.98),('dynatrace-application-observability','apm-service-dependencies','supported',0.98),('dynatrace-application-observability','apm-telemetry-correlation','supported',0.97),('elastic-apm','apm-telemetry-correlation','supported',0.93);

-- Core network monitoring facts.
INSERT INTO cat61_facts
SELECT p.product_slug,c.capability_slug,'supported',0.90 FROM
(SELECT 'solarwinds-network-performance-monitor' product_slug UNION ALL SELECT 'manageengine-opmanager' UNION ALL SELECT 'datadog-network-monitoring' UNION ALL SELECT 'logicmonitor-network-monitoring') p
CROSS JOIN
(SELECT 'network-availability-health' capability_slug UNION ALL SELECT 'network-performance-metrics' UNION ALL SELECT 'network-alerts-faults') c;
INSERT INTO cat61_facts VALUES
('solarwinds-network-performance-monitor','network-device-discovery','supported',0.97),('solarwinds-network-performance-monitor','network-traffic-path','supported',0.96),
('manageengine-opmanager','network-device-discovery','supported',0.97),
('datadog-network-monitoring','network-traffic-path','supported',0.96),
('logicmonitor-network-monitoring','network-device-discovery','supported',0.96),('logicmonitor-network-monitoring','network-traffic-path','supported',0.92);

-- Core TMS facts.
INSERT INTO cat61_facts
SELECT p.product_slug,c.capability_slug,'supported',0.91 FROM
(SELECT 'sap-transportation-management' product_slug UNION ALL SELECT 'oracle-transportation-management' UNION ALL SELECT 'blue-yonder-transportation-management' UNION ALL SELECT 'descartes-transportation-manager') p
CROSS JOIN
(SELECT 'tms-planning-routing' capability_slug UNION ALL SELECT 'tms-carrier-optimization' UNION ALL SELECT 'tms-shipment-execution' UNION ALL SELECT 'tms-shipment-visibility') c;
INSERT INTO cat61_facts VALUES
('sap-transportation-management','tms-freight-cost','supported',0.96),('oracle-transportation-management','tms-freight-cost','supported',0.94),('descartes-transportation-manager','tms-freight-cost','supported',0.96);

-- Core document-management facts.
INSERT INTO cat61_facts
SELECT p.product_slug,c.capability_slug,'supported',0.91 FROM
(SELECT 'microsoft-sharepoint' product_slug UNION ALL SELECT 'm-files-document-management' UNION ALL SELECT 'opentext-content-management' UNION ALL SELECT 'box-intelligent-content-management') p
CROSS JOIN
(SELECT 'dms-repository' capability_slug UNION ALL SELECT 'dms-metadata-search' UNION ALL SELECT 'dms-version-collaboration') c;
INSERT INTO cat61_facts VALUES
('microsoft-sharepoint','dms-workflow','supported',0.90),('microsoft-sharepoint','dms-governance-controls','supported',0.92),
('m-files-document-management','dms-workflow','supported',0.98),('m-files-document-management','dms-governance-controls','supported',0.98),
('opentext-content-management','dms-workflow','supported',0.96),('opentext-content-management','dms-governance-controls','supported',0.98),
('box-intelligent-content-management','dms-workflow','supported',0.96),('box-intelligent-content-management','dms-governance-controls','supported',0.97);

-- Core e-signature facts.
INSERT INTO cat61_facts
SELECT p.product_slug,c.capability_slug,'supported',0.94 FROM
(SELECT 'docusign-esignature' product_slug UNION ALL SELECT 'adobe-acrobat-sign' UNION ALL SELECT 'dropbox-sign' UNION ALL SELECT 'zoho-sign') p
CROSS JOIN
(SELECT 'esign-send-request' capability_slug UNION ALL SELECT 'esign-routing' UNION ALL SELECT 'esign-audit-tracking') c;
INSERT INTO cat61_facts VALUES
('docusign-esignature','esign-templates','supported',0.99),('docusign-esignature','esign-integrations','supported',0.99),
('adobe-acrobat-sign','esign-templates','supported',0.94),('adobe-acrobat-sign','esign-integrations','supported',0.94),
('dropbox-sign','esign-templates','supported',0.95),('dropbox-sign','esign-integrations','supported',0.90),
('zoho-sign','esign-templates','supported',0.98),('zoho-sign','esign-integrations','supported',0.98);

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.confidence,NOW()
FROM cat61_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat61_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Official vendor-owned source; broad category capability only.'
FROM cat61_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN cat61_products x ON x.product_slug=p.slug
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=x.source_url;

-- Assert SaaS deployment only where the official product is clearly delivered as a cloud service.
INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.90 FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug IN('datadog-apm','new-relic-apm-360','dynatrace-application-observability','datadog-network-monitoring','logicmonitor-network-monitoring','oracle-transportation-management','blue-yonder-transportation-management','descartes-transportation-manager','microsoft-sharepoint','m-files-document-management','opentext-content-management','box-intelligent-content-management','docusign-esignature','adobe-acrobat-sign','dropbox-sign','zoho-sign')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

COMMIT;
