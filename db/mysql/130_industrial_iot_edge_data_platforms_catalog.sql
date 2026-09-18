-- TechSelectAI Industrial IoT & Edge Data Platforms catalog expansion.
-- Adds one canonical industrial edge-data category and five evidence-backed current products.
-- Official first-party evidence reviewed Sep 2026. Presence is not an endorsement.
-- Unknown != Unsupported. No Fit Score, recommendation ranking, review score, follower/community popularity or commercial placement logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('Industrial IoT & Edge Data Platforms','industrial-iot-edge-data-platforms','Industrial edge software for connecting OT assets, normalizing and contextualizing machine data, publishing MQTT/UNS-oriented streams, buffering through outages, running local workloads and integrating plant-floor data with enterprise and cloud systems.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @edge_cat=(SELECT id FROM categories WHERE slug='industrial-iot-edge-data-platforms' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@edge_cat,'Industrial Connectivity & DataOps','edge-connectivity-dataops','Industrial protocol connectivity, MQTT/UNS-oriented publishing, data transformation, contextualization and resilient data delivery.',1),
(@edge_cat,'Edge Runtime, Integration & Fleet Operations','edge-runtime-operations','Local analytics/application execution, bidirectional action, cloud/enterprise integration and centralized management of distributed edge deployments.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.sec,1
FROM modules m JOIN (
 SELECT 'edge-connectivity-dataops' module_slug,'Industrial protocol & device connectivity' name,'edge-industrial-connectivity' slug,'Connect PLCs, controllers, sensors, SCADA systems, databases and other OT sources using native industrial drivers, OPC UA, Modbus, EtherNet/IP, S7 or comparable supported protocols.' description,0 sec UNION ALL
 SELECT 'edge-connectivity-dataops','MQTT, Sparkplug & UNS-oriented publication','edge-mqtt-uns-publication','Publish or bridge operational data through MQTT, Sparkplug or equivalent event-driven topic structures suitable for OT/IT integration and Unified Namespace architectures.' description,0 UNION ALL
 SELECT 'edge-connectivity-dataops','Data normalization, transformation & routing','edge-data-transformation','Normalize values and schemas, filter or transform payloads, apply routing logic and deliver curated industrial data to downstream systems.' description,0 UNION ALL
 SELECT 'edge-connectivity-dataops','Asset modeling, metadata & contextualization','edge-contextualization-modeling','Enrich raw machine signals with asset structures, metadata, hierarchies, schemas or reusable data models for consistent enterprise consumption.' description,0 UNION ALL
 SELECT 'edge-connectivity-dataops','Store-and-forward & offline buffering','edge-store-forward','Buffer or persist operational messages when downstream connectivity is interrupted and forward them after connectivity is restored.' description,0 UNION ALL
 SELECT 'edge-runtime-operations','Local edge analytics & AI execution','edge-local-analytics-ai','Run analytics, anomaly detection, ML/AI inference or comparable operational calculations locally at or near the industrial edge where explicitly supported.' description,0 UNION ALL
 SELECT 'edge-runtime-operations','Containerized edge application runtime','edge-container-app-runtime','Host, deploy and manage containerized or equivalent custom applications directly on edge infrastructure where the platform provides an application runtime.' description,0 UNION ALL
 SELECT 'edge-runtime-operations','Bidirectional writeback & governed control','edge-bidirectional-control','Support governed southbound writes, commands or closed-loop actions from enterprise/MQTT/application layers back toward connected OT assets where explicitly supported.' description,0 UNION ALL
 SELECT 'edge-runtime-operations','Cloud, data-platform & enterprise integration','edge-cloud-enterprise-integration','Connect curated edge data with cloud services, data platforms, message brokers, databases, APIs, MES, ERP, analytics or AI services.' description,0 UNION ALL
 SELECT 'edge-runtime-operations','Centralized fleet, device & configuration management','edge-fleet-central-management','Centrally onboard, monitor, configure, update or govern multiple distributed edge instances, gateways, devices or applications across sites.' description,0
) x ON x.module_slug=m.slug
WHERE m.category_id=@edge_cat
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('HighByte','highbyte','https://www.highbyte.com/','Industrial DataOps and edge-data software vendor.','active'),
('Litmus Automation','litmus','https://litmus.io/','Industrial edge data and Industrial AI platform vendor.','active'),
('Siemens','siemens','https://www.siemens.com/','Industrial automation, edge computing and manufacturing software vendor.','active'),
('Microsoft','microsoft','https://www.microsoft.com/','Cloud, edge, industrial IoT and enterprise software vendor.','active'),
('HiveMQ','hivemq','https://www.hivemq.com/','MQTT platform and industrial edge gateway software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat130_products;
CREATE TEMPORARY TABLE cat130_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO cat130_products VALUES
('highbyte','industrial-iot-edge-data-platforms','HighByte Intelligence Hub','highbyte-intelligence-hub','Industrial DataOps software for edge-based OT/IT connectivity, data modeling, transformation, reliable store-and-forward, bidirectional data movement and centralized configuration of distributed hubs.','https://www.highbyte.com/intelligence-hub'),
('litmus','industrial-iot-edge-data-platforms','Litmus Edge','litmus-edge','Industrial edge data platform for broad OT connectivity, contextualization, local time-series processing, analytics/AI, Docker application hosting and enterprise/cloud integration, with fleet operations available through Litmus Edge Manager.','https://litmus.io/litmus-edge'),
('siemens','industrial-iot-edge-data-platforms','Siemens Industrial Edge','siemens-industrial-edge','Industrial edge computing platform combining OT connectors, Docker-based application runtime, local data processing, enterprise/cloud integration and centralized device/application management across manufacturing sites.','https://www.siemens.com/en-us/products/industrial-edge/'),
('microsoft','industrial-iot-edge-data-platforms','Azure IoT Operations','microsoft-azure-iot-operations','Edge-native industrial data plane running on Azure Arc-enabled Kubernetes with OPC UA connectivity, MQTT broker, data flows, transformation/contextualization, buffering and cloud/enterprise data routing.','https://learn.microsoft.com/en-us/azure/iot-operations/overview-iot-operations'),
('hivemq','industrial-iot-edge-data-platforms','HiveMQ Edge','hivemq-edge','Software-based industrial MQTT edge gateway with protocol adapters, local MQTT broker, data policy/transformation, offline buffering and bidirectional OT/IT bridging for edge-to-enterprise data flows.','https://www.hivemq.com/products/hivemq-edge/');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat130_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS cat130_sources;
CREATE TEMPORARY TABLE cat130_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat130_sources VALUES
('highbyte-intelligence-hub','https://www.highbyte.com/intelligence-hub','HighByte Intelligence Hub','HighByte'),
('highbyte-intelligence-hub','https://www.highbyte.com/intelligence-hub/connections','HighByte Intelligence Hub Connections','HighByte'),
('highbyte-intelligence-hub','https://www.highbyte.com/intelligence-hub/faqs','HighByte Intelligence Hub FAQs','HighByte'),
('highbyte-intelligence-hub','https://guide.highbyte.com/archive/central_configuration/','HighByte Central Configuration','HighByte'),
('litmus-edge','https://litmus.io/litmus-edge','Litmus Edge','Litmus'),
('litmus-edge','https://litmus.io/edge-data-platform','Litmus Edge Data Platform','Litmus'),
('litmus-edge','https://litmus.io/litmus-edge-manager','Litmus Edge Manager','Litmus'),
('litmus-edge','https://litmus.io/blog/run-any-app-at-the-edge-litmus-industrial-application-hosting','Litmus Edge Application Hosting','Litmus'),
('litmus-edge','https://docs.litmus.io/litmusedge/product-features/integration/add-a-connector','Litmus Edge Connectors and Store Forward','Litmus'),
('siemens-industrial-edge','https://www.siemens.com/en-us/products/industrial-edge/','Siemens Industrial Edge','Siemens'),
('siemens-industrial-edge','https://www.siemens.com/en-us/products/industrial-edge/edge-computing-architecture/','Siemens Industrial Edge Architecture','Siemens'),
('siemens-industrial-edge','https://www.siemens.com/en-us/products/industrial-edge/management-license/','Siemens Industrial Edge Management License','Siemens'),
('siemens-industrial-edge','https://www.siemens.com/en-gb/products/industrial-edge/management-cloud/','Siemens Industrial Edge Management Cloud','Siemens'),
('microsoft-azure-iot-operations','https://learn.microsoft.com/en-us/azure/iot-operations/overview-iot-operations','Azure IoT Operations Overview','Microsoft'),
('microsoft-azure-iot-operations','https://learn.microsoft.com/en-us/azure/iot-operations/connect-to-cloud/overview-dataflow','Azure IoT Operations Data Flows','Microsoft'),
('microsoft-azure-iot-operations','https://learn.microsoft.com/en-us/azure/iot-operations/discover-manage-assets/howto-configure-opc-ua','Azure IoT Operations OPC UA Connector','Microsoft'),
('microsoft-azure-iot-operations','https://learn.microsoft.com/en-us/azure/iot-operations/deployment-plan/deployment-planning','Azure IoT Operations Deployment Planning','Microsoft'),
('hivemq-edge','https://www.hivemq.com/products/hivemq-edge/','HiveMQ Edge','HiveMQ'),
('hivemq-edge','https://docs.hivemq.com/hivemq-edge/index.html','HiveMQ Edge Documentation','HiveMQ'),
('hivemq-edge','https://docs.hivemq.com/hivemq-edge/protocol-adapters.html','HiveMQ Edge Protocol Adapters','HiveMQ'),
('hivemq-edge','https://docs.hivemq.com/hivemq-edge/configuration.html','HiveMQ Edge Configuration and Offline Buffering','HiveMQ');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM cat130_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS cat130_facts;
CREATE TEMPORARY TABLE cat130_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat130_facts VALUES
('highbyte-intelligence-hub','edge-industrial-connectivity','supported',0.990,'HighByte connects OPC UA, Modbus, MQTT/Sparkplug, files, SQL, historians, REST and enterprise/cloud data sources through native connections.','https://www.highbyte.com/intelligence-hub/connections'),
('highbyte-intelligence-hub','edge-mqtt-uns-publication','supported',0.990,'HighByte supports bidirectional MQTT and Sparkplug connectivity and publishes modeled industrial data into broker-based architectures.','https://www.highbyte.com/intelligence-hub/connections'),
('highbyte-intelligence-hub','edge-data-transformation','supported',0.990,'Intelligence Hub pipelines transform, filter, route and curate industrial payloads between connected systems.','https://www.highbyte.com/intelligence-hub'),
('highbyte-intelligence-hub','edge-contextualization-modeling','supported',0.990,'HighByte explicitly models industrial assets and reusable instances to contextualize raw OT data before delivery.','https://www.highbyte.com/intelligence-hub'),
('highbyte-intelligence-hub','edge-store-forward','supported',0.990,'HighByte supports disk-based store-and-forward buffering for output connections when the target is unavailable.','https://www.highbyte.com/intelligence-hub'),
('highbyte-intelligence-hub','edge-bidirectional-control','supported',0.980,'HighByte connections expose inputs and outputs for bidirectional read/write data movement; exact southbound write authority depends on the configured source system and governance.','https://www.highbyte.com/intelligence-hub/connections'),
('highbyte-intelligence-hub','edge-cloud-enterprise-integration','supported',0.990,'HighByte provides native connections to AWS, Azure, Databricks, Snowflake, Kafka, databases, historians, REST and other enterprise destinations.','https://www.highbyte.com/intelligence-hub/connections'),
('highbyte-intelligence-hub','edge-fleet-central-management','supported',0.980,'HighByte Central Configuration lets one hub centrally configure, compare and synchronize multiple remote hubs.','https://guide.highbyte.com/archive/central_configuration/'),

('litmus-edge','edge-industrial-connectivity','supported',0.990,'Litmus Edge provides broad industrial connectivity across PLCs, sensors, SCADA, historians and databases using native drivers and discovery.','https://litmus.io/litmus-edge'),
('litmus-edge','edge-mqtt-uns-publication','partially_supported',0.980,'Litmus Edge publishes data over MQTT and integrates with broker-based architectures, while the governed Unified Namespace product is Litmus Unify rather than assumed core Edge entitlement.','https://litmus.io/edge-data-platform'),
('litmus-edge','edge-data-transformation','supported',0.990,'Litmus Edge normalizes, transforms, routes and orchestrates industrial data locally through DataOps pipelines.','https://litmus.io/litmus-edge'),
('litmus-edge','edge-contextualization-modeling','supported',0.990,'Litmus Edge builds reusable asset/data models with attributes, metadata and hierarchical industrial context.','https://litmus.io/litmus-edge'),
('litmus-edge','edge-store-forward','supported',0.990,'Litmus Edge connectors support persistent storage and store-and-forward when downstream cloud or enterprise systems are unavailable.','https://docs.litmus.io/litmusedge/product-features/integration/add-a-connector'),
('litmus-edge','edge-local-analytics-ai','supported',0.990,'Litmus Edge runs local analytics, statistical processing and AI/ML inference workloads directly at the edge.','https://litmus.io/litmus-edge'),
('litmus-edge','edge-container-app-runtime','supported',0.990,'Litmus Edge supports hosting Docker-based containerized applications directly on edge systems.','https://litmus.io/blog/run-any-app-at-the-edge-litmus-industrial-application-hosting'),
('litmus-edge','edge-bidirectional-control','partially_supported',0.960,'Litmus documents governed closed-loop actions and local workflow automation, but universal writeback support across every industrial connector is not inferred.','https://litmus.io/edge-data-platform'),
('litmus-edge','edge-cloud-enterprise-integration','supported',0.990,'Litmus provides managed integrations with cloud, database, message-broker, enterprise and AI platforms.','https://litmus.io/edge-data-platform'),
('litmus-edge','edge-fleet-central-management','partially_supported',0.990,'Centralized device, application, data-model and AI lifecycle management is delivered through the companion Litmus Edge Manager product rather than assumed inside every Litmus Edge license.','https://litmus.io/litmus-edge-manager'),

('siemens-industrial-edge','edge-industrial-connectivity','supported',0.990,'Siemens Industrial Edge includes shop-floor connectivity for S7/S7+, OPC UA, MQTT and other industrial protocols through system apps and connectors.','https://www.siemens.com/en-us/products/industrial-edge/management-license/'),
('siemens-industrial-edge','edge-mqtt-uns-publication','supported',0.980,'Industrial Edge includes an MQTT Cloud Connector and supports broker-oriented OT/IT data exchange; a complete governed UNS layer is not inferred from MQTT support alone.','https://www.siemens.com/en-us/products/industrial-edge/management-license/'),
('siemens-industrial-edge','edge-data-transformation','partially_supported',0.980,'Industrial Edge provides local data acquisition, aggregation and low-code flow processing through system applications; exact transformation scope depends on installed apps.','https://www.siemens.com/en-us/products/industrial-edge/edge-computing-architecture/'),
('siemens-industrial-edge','edge-contextualization-modeling','partially_supported',0.970,'Siemens documents industrial data management and semantic/context apps within the Industrial Edge ecosystem, but contextualization is app-dependent rather than assumed base-runtime functionality.','https://www.siemens.com/en-us/products/industrial-edge/edge-computing-architecture/'),
('siemens-industrial-edge','edge-local-analytics-ai','supported',0.990,'Industrial Edge supports real-time local data processing and deployment of analytics and AI workloads at the shop floor.','https://www.siemens.com/en-us/products/industrial-edge/'),
('siemens-industrial-edge','edge-container-app-runtime','supported',0.990,'Industrial Edge is built on Docker-standard containers and supports Siemens, third-party and customer-developed edge applications.','https://www.siemens.com/en-us/products/industrial-edge/edge-computing-architecture/'),
('siemens-industrial-edge','edge-cloud-enterprise-integration','supported',0.990,'Industrial Edge connects factory data to cloud platforms, IIoT services, ERP, MES/SCADA and MQTT brokers.','https://www.siemens.com/en-us/products/industrial-edge/'),
('siemens-industrial-edge','edge-fleet-central-management','supported',0.990,'Industrial Edge Management centrally manages distributed devices, applications, updates and configurations across sites.','https://www.siemens.com/en-us/products/industrial-edge/edge-computing-architecture/'),

('microsoft-azure-iot-operations','edge-industrial-connectivity','supported',0.990,'Azure IoT Operations connects industrial assets through OPC UA and extensible device/asset services at the edge.','https://learn.microsoft.com/en-us/azure/iot-operations/discover-manage-assets/howto-configure-opc-ua'),
('microsoft-azure-iot-operations','edge-mqtt-uns-publication','supported',0.990,'Azure IoT Operations includes an industrial-grade edge-native MQTT broker used by OPC UA connectors, data flows and event-driven architectures.','https://learn.microsoft.com/en-us/azure/iot-operations/overview-iot-operations'),
('microsoft-azure-iot-operations','edge-data-transformation','supported',0.990,'Azure IoT Operations data flows route, transform and enrich edge data before delivery to MQTT, cloud or enterprise destinations.','https://learn.microsoft.com/en-us/azure/iot-operations/connect-to-cloud/overview-dataflow'),
('microsoft-azure-iot-operations','edge-contextualization-modeling','supported',0.980,'Azure IoT Operations uses device/asset definitions and data-flow enrichment to give industrial signals friendly names and operational context.','https://learn.microsoft.com/en-us/azure/iot-operations/discover-manage-assets/howto-configure-opc-ua'),
('microsoft-azure-iot-operations','edge-store-forward','supported',0.980,'Azure IoT Operations supports disk persistence/data buffering and can continue edge operation during temporary cloud disconnection, subject to documented offline limits.','https://learn.microsoft.com/en-us/azure/iot-operations/connect-to-cloud/overview-dataflow'),
('microsoft-azure-iot-operations','edge-bidirectional-control','partially_supported',0.960,'Data-flow MQTT endpoints support bidirectional messaging, but general-purpose southbound control of arbitrary OT protocols is not inferred from MQTT routing alone.','https://learn.microsoft.com/en-us/azure/iot-operations/connect-to-cloud/overview-dataflow'),
('microsoft-azure-iot-operations','edge-cloud-enterprise-integration','supported',0.990,'Azure IoT Operations routes edge data to Azure services and other endpoints using data flows and cloud connectors.','https://learn.microsoft.com/en-us/azure/iot-operations/connect-to-cloud/overview-dataflow'),
('microsoft-azure-iot-operations','edge-fleet-central-management','partially_supported',0.980,'Azure IoT Operations is deployed and governed through Azure Arc and Azure resource tooling, but a standalone vendor-neutral edge fleet manager is not inferred beyond that Azure control plane.','https://learn.microsoft.com/en-us/azure/iot-operations/deployment-plan/deployment-planning'),

('hivemq-edge','edge-industrial-connectivity','supported',0.990,'HiveMQ Edge provides protocol adapters for OPC UA, Modbus, S7, EtherNet/IP, BACnet, databases and additional OT sources.','https://docs.hivemq.com/hivemq-edge/protocol-adapters.html'),
('hivemq-edge','edge-mqtt-uns-publication','supported',0.990,'HiveMQ Edge includes an edge-optimized MQTT broker, MQTT bridge and Unified Namespace-oriented topic hierarchy capabilities.','https://docs.hivemq.com/hivemq-edge/index.html'),
('hivemq-edge','edge-data-transformation','partially_supported',0.990,'HiveMQ Data Hub on Edge provides schema validation, filtering and transformation, but these capabilities require the commercial feature set rather than the open-source base.','https://docs.hivemq.com/hivemq-edge/index.html'),
('hivemq-edge','edge-contextualization-modeling','partially_supported',0.970,'HiveMQ Edge can enrich and contextualize OT data through the Data Policy Engine and database integrations, but a general-purpose digital-twin/asset-modeling layer is not inferred.','https://www.hivemq.com/products/hivemq-edge/'),
('hivemq-edge','edge-store-forward','partially_supported',0.990,'Offline disk buffering and store-and-forward are supported for bridge traffic as a commercial HiveMQ Edge feature.','https://docs.hivemq.com/hivemq-edge/configuration.html'),
('hivemq-edge','edge-bidirectional-control','partially_supported',0.980,'HiveMQ Edge supports southbound MQTT-to-OPC-UA writes, but southbound control is currently adapter-specific and part of the commercial feature set.','https://docs.hivemq.com/hivemq-edge/protocol-adapters.html'),
('hivemq-edge','edge-cloud-enterprise-integration','supported',0.990,'HiveMQ Edge bridges local industrial MQTT traffic to remote enterprise/cloud MQTT brokers and exposes extensibility through protocol adapters and APIs.','https://www.hivemq.com/products/hivemq-edge/');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat130_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat130_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party vendor documentation supporting this capability.'
FROM cat130_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.990
FROM products p JOIN deployment_models d ON d.slug='on-premise'
WHERE p.slug IN('highbyte-intelligence-hub','litmus-edge','siemens-industrial-edge','hivemq-edge')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.990
FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug='siemens-industrial-edge'
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

-- Azure IoT Operations has an edge data plane plus Azure cloud control plane; do not collapse that hybrid architecture into a generic SaaS/on-premises label here.
INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000
FROM products p CROSS JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') x
WHERE p.slug IN('highbyte-intelligence-hub','litmus-edge','siemens-industrial-edge','microsoft-azure-iot-operations','hivemq-edge')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

COMMIT;
