-- TechSelectAI OT / ICS Cybersecurity & Asset Visibility catalog expansion.
-- Adds one canonical specialized OT-security category and five evidence-backed current products.
-- Official first-party evidence reviewed Sep 2026. Presence is not an endorsement.
-- Unknown != Unsupported. No Fit Score, recommendation ranking, review score, follower/community popularity or commercial placement logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('OT / ICS Cybersecurity & Asset Visibility Platforms','ot-ics-cybersecurity-asset-visibility','Specialized cybersecurity platforms for operational technology and industrial control systems covering asset discovery, safe active enrichment, industrial network mapping, vulnerability prioritization, behavioral threat detection, engineering-change monitoring, segmentation validation, OT threat intelligence, SOC integration and distributed/air-gapped operations.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @otsec_cat=(SELECT id FROM categories WHERE slug='ot-ics-cybersecurity-asset-visibility' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@otsec_cat,'OT Asset Visibility & Exposure Management','otsec-visibility-exposure','Passive and active asset discovery, protocol/topology visibility, vulnerability prioritization and industrial configuration-change monitoring.',1),
(@otsec_cat,'Threat Detection, Segmentation & SOC Operations','otsec-detection-operations','Behavioral detections, network segmentation/policy validation, OT threat intelligence, enterprise security integrations and distributed deployment.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.sec,1
FROM modules m JOIN (
 SELECT 'otsec-visibility-exposure' module_slug,'Passive OT/ICS asset discovery & fingerprinting' name,'otsec-passive-discovery' slug,'Continuously discover and classify PLCs, RTUs, HMIs, DCS/SCADA systems, industrial endpoints and related OT/IoT assets from network traffic without disrupting operations.' description,1 sec UNION ALL
 SELECT 'otsec-visibility-exposure','Safe active querying & asset enrichment','otsec-active-enrichment','Use OT-safe active queries, collectors or equivalent mechanisms to enrich passive inventory with firmware, backplane, configuration, patch or non-communicating asset details.' description,1 UNION ALL
 SELECT 'otsec-visibility-exposure','Industrial network topology & communication mapping','otsec-topology-mapping','Visualize industrial assets, connections, zones, Purdue levels, protocols and communication paths to understand OT architecture and dependencies.' description,1 UNION ALL
 SELECT 'otsec-visibility-exposure','OT vulnerability & exposure prioritization','otsec-vulnerability-exposure','Map known vulnerabilities and unsafe configurations to actual industrial assets and prioritize remediation using OT/business context, exploitability or exposure risk.' description,1 UNION ALL
 SELECT 'otsec-visibility-exposure','Controller, logic & configuration change monitoring','otsec-engineering-change-monitoring','Detect or record PLC/controller mode, firmware, program, function-block, configuration, tag/write or other engineering changes that may affect operational integrity.' description,1 UNION ALL
 SELECT 'otsec-detection-operations','Behavioral anomaly & OT threat detection','otsec-threat-anomaly-detection','Detect malicious, suspicious or abnormal communications and operational behavior using industrial protocol awareness, baselines, signatures, threat intelligence or behavioral analytics.' description,1 UNION ALL
 SELECT 'otsec-detection-operations','Segmentation, zones & policy-violation monitoring','otsec-segmentation-policy','Model zones and conduits, validate segmentation, identify boundary/policy violations and support enforcement through firewall/NAC integrations where available.' description,1 UNION ALL
 SELECT 'otsec-detection-operations','OT threat intelligence & ATT&CK context','otsec-threat-intelligence','Enrich OT alerts and exposures with industrial threat intelligence, IOCs/TTPs, adversary context, MITRE ATT&CK for ICS mappings or vendor research.' description,1 UNION ALL
 SELECT 'otsec-detection-operations','SIEM, SOAR, firewall & SOC integration','otsec-soc-integration','Integrate OT asset, alert, vulnerability and context data into enterprise SOC, SIEM/SOAR, firewall, NAC, ticketing or response workflows.' description,1 UNION ALL
 SELECT 'otsec-detection-operations','Multi-site, hybrid & air-gapped OT operations','otsec-distributed-deployment','Support centralized security across multiple plants/sites and deployment patterns that may include SaaS, on-premises, hybrid, remote or air-gapped industrial environments.' description,1
) x ON x.module_slug=m.slug
WHERE m.category_id=@otsec_cat
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Nozomi Networks','nozomi-networks','https://www.nozominetworks.com/','OT, IoT and cyber-physical systems visibility and cybersecurity vendor.','active'),
('Claroty','claroty','https://claroty.com/','Cyber-physical systems and industrial cybersecurity vendor.','active'),
('Dragos','dragos','https://www.dragos.com/','Operational technology cybersecurity platform and threat-intelligence vendor.','active'),
('Tenable','tenable','https://www.tenable.com/','Exposure management and OT cybersecurity software vendor.','active'),
('Microsoft','microsoft','https://www.microsoft.com/','Cloud, enterprise security and IoT/OT cybersecurity software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat136_products;
CREATE TEMPORARY TABLE cat136_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO cat136_products VALUES
('nozomi-networks','ot-ics-cybersecurity-asset-visibility','Nozomi Networks Platform','nozomi-networks-platform','Modular OT/IoT cybersecurity platform combining Guardian network sensors, Vantage or on-premises management, asset/vulnerability visibility, anomaly detection, optional Smart Polling, optional threat intelligence and enterprise security integrations.','https://www.nozominetworks.com/platform'),
('claroty','ot-ics-cybersecurity-asset-visibility','Claroty Continuous Threat Detection (CTD)','claroty-ctd','On-premises CPS/OT security platform for passive/active asset discovery, industrial process visibility, exposure management, behavioral threat detection, network zones and ecosystem integrations.','https://claroty.com/industrial-cybersecurity/ctd'),
('dragos','ot-ics-cybersecurity-asset-visibility','Dragos Platform','dragos-platform','OT-native cybersecurity platform for asset discovery, industrial network monitoring, vulnerability prioritization, segmentation validation, threat detection, OT intelligence, incident response and enterprise SOC integration.','https://www.dragos.com/cybersecurity-platform/'),
('tenable','ot-ics-cybersecurity-asset-visibility','Tenable One OT Exposure','tenable-one-ot-exposure','Cyber-physical exposure-management platform combining passive monitoring, Safe Active Query, industrial asset inventory, vulnerability prioritization, controller-change monitoring, anomaly detection, segmentation visibility and enterprise integrations.','https://www.tenable.com/products/ot-security'),
('microsoft','ot-ics-cybersecurity-asset-visibility','Microsoft Defender for IoT','microsoft-defender-for-iot','OT/IoT cybersecurity solution using industrial network sensors and Microsoft cloud/SOC services for asset inventory, vulnerability management, behavioral alerts, operational-change detection, site monitoring and SIEM integration.','https://www.microsoft.com/en-us/security/business/endpoint-security/microsoft-defender-iot');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat136_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS cat136_sources;
CREATE TEMPORARY TABLE cat136_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat136_sources VALUES
('nozomi-networks-platform','https://www.nozominetworks.com/platform','Nozomi Networks OT Security Platform','Nozomi Networks'),
('nozomi-networks-platform','https://www.nozominetworks.com/platform/vantage','Nozomi Vantage','Nozomi Networks'),
('nozomi-networks-platform','https://www.nozominetworks.com/platform/guardian','Nozomi Guardian','Nozomi Networks'),
('nozomi-networks-platform','https://www.nozominetworks.com/platform/smart-polling','Nozomi Smart Polling','Nozomi Networks'),
('nozomi-networks-platform','https://www.nozominetworks.com/platform/threat-intelligence','Nozomi Threat Intelligence','Nozomi Networks'),
('nozomi-networks-platform','https://www.nozominetworks.com/platform/technical-specifications','Nozomi Platform Technical Specifications','Nozomi Networks'),
('nozomi-networks-platform','https://technicaldocs.nozominetworks.com/reference-guides/products/n2os/topics/autogenerated/security_features/r_n2os_alerts_sign_configuration_change.html','Nozomi Guardian Configuration Change Alert','Nozomi Networks'),
('nozomi-networks-platform','https://www.nozominetworks.com/blog/whats-new-in-nozomi-q2-2026-vantage-iq-ai-powered-integrations-and-guardian-air-updates','Nozomi Q2 2026 Vantage Update','Nozomi Networks'),
('claroty-ctd','https://claroty.com/industrial-cybersecurity/ctd','Claroty Continuous Threat Detection','Claroty'),
('claroty-ctd','https://claroty.com/blog/pillars-detect','Claroty CTD Threat Detection and Operational Behaviors','Claroty'),
('claroty-ctd','https://claroty.com/blog/feature-spotlight-claroty-threat-detection-engines','Claroty CTD Threat Detection Engines','Claroty'),
('claroty-ctd','https://web-assets.claroty.com/resource-downloads/2025-zt-for-ot-wp.pdf','Claroty Zero Trust for OT','Claroty'),
('dragos-platform','https://www.dragos.com/cybersecurity-platform/','Dragos Platform','Dragos'),
('dragos-platform','https://www.dragos.com/cybersecurity-platform/asset-visibility/','Dragos Asset Visibility','Dragos'),
('dragos-platform','https://www.dragos.com/cybersecurity-platform/threat-detection/','Dragos Threat Detection','Dragos'),
('dragos-platform','https://www.dragos.com/resources/press-release/dragos-named-leader-2026-gartner-magic-quadrant-cps-protection-platforms','Dragos Platform 2026 Capabilities','Dragos'),
('dragos-platform','https://www.dragos.com/partner/microsoft','Dragos Microsoft Integration and Deployment','Dragos'),
('dragos-platform','https://www.dragos.com/partner/splunk/app','Dragos OT Add-On for Splunk','Dragos'),
('tenable-one-ot-exposure','https://www.tenable.com/products/ot-security','Tenable One OT Exposure','Tenable'),
('tenable-one-ot-exposure','https://docs.tenable.com/OT-security/4_5/Content/Introduction/Technologies.htm','Tenable One OT Exposure Technologies','Tenable'),
('tenable-one-ot-exposure','https://docs.tenable.com/release-notes/Content/OT-security/2026.htm','Tenable One OT Exposure 2026 Release Notes','Tenable'),
('tenable-one-ot-exposure','https://docs.tenable.com/OT-security/4_2/Content/Network/NetworkMap.htm','Tenable One OT Exposure Network Map','Tenable'),
('microsoft-defender-for-iot','https://www.microsoft.com/en-us/security/business/endpoint-security/microsoft-defender-iot','Microsoft Defender for IoT','Microsoft'),
('microsoft-defender-for-iot','https://learn.microsoft.com/en-us/azure/defender-for-iot/organizations/device-inventory','Defender for IoT Device Inventory','Microsoft'),
('microsoft-defender-for-iot','https://learn.microsoft.com/en-us/azure/defender-for-iot/organizations/vulnerability-management','Defender for IoT Vulnerability Management','Microsoft'),
('microsoft-defender-for-iot','https://learn.microsoft.com/en-us/azure/defender-for-iot/organizations/alerts','Defender for IoT Alerts','Microsoft'),
('microsoft-defender-for-iot','https://learn.microsoft.com/en-us/azure/defender-for-iot/organizations/architecture','Defender for IoT OT Architecture','Microsoft'),
('microsoft-defender-for-iot','https://learn.microsoft.com/en-us/azure/defender-for-iot/organizations/ot-deploy/ot-deploy-path','Defender for IoT OT Deployment','Microsoft'),
('microsoft-defender-for-iot','https://learn.microsoft.com/en-us/azure/defender-for-iot/organizations/ot-deploy/air-gapped-deploy','Defender for IoT Air-Gapped Deployment','Microsoft');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM cat136_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS cat136_facts;
CREATE TEMPORARY TABLE cat136_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat136_facts VALUES
-- Nozomi Networks Platform
('nozomi-networks-platform','otsec-passive-discovery','supported',0.990,'Guardian passively observes mirrored OT/IoT traffic and continuously builds detailed asset inventory without generating additional control-network traffic.','https://www.nozominetworks.com/platform/guardian'),
('nozomi-networks-platform','otsec-active-enrichment','partially_supported',0.990,'Smart Polling adds low-volume active asset enrichment, but it is an add-on capability rather than assumed in every Nozomi platform deployment.','https://www.nozominetworks.com/platform/smart-polling'),
('nozomi-networks-platform','otsec-topology-mapping','supported',0.990,'Guardian and Vantage provide network visualization, asset/connection views and zone-aware visibility across OT/IoT environments.','https://www.nozominetworks.com/platform'),
('nozomi-networks-platform','otsec-vulnerability-exposure','supported',0.990,'The platform identifies vulnerabilities and asset risk, while Vantage provides customizable asset-risk scoring; Asset Intelligence can further enrich classification and vulnerability context as an add-on.','https://www.nozominetworks.com/platform/vantage'),
('nozomi-networks-platform','otsec-engineering-change-monitoring','supported',0.980,'Guardian includes explicit configuration-change alerts when changed configurations are uploaded to OT devices.','https://technicaldocs.nozominetworks.com/reference-guides/products/n2os/topics/autogenerated/security_features/r_n2os_alerts_sign_configuration_change.html'),
('nozomi-networks-platform','otsec-threat-anomaly-detection','supported',0.990,'Guardian continuously monitors industrial communications and baselines behavior to detect suspicious communications, malware, unwanted operations and operational anomalies.','https://www.nozominetworks.com/platform/guardian'),
('nozomi-networks-platform','otsec-segmentation-policy','partially_supported',0.980,'Nozomi provides zones, network/communication visibility and segmentation analysis, but actual enforcement depends on external firewalls/NAC and related integrations.','https://www.nozominetworks.com/blog/whats-new-in-nozomi-q2-2026-vantage-iq-ai-powered-integrations-and-guardian-air-updates'),
('nozomi-networks-platform','otsec-threat-intelligence','partially_supported',0.990,'Nozomi OT/IoT Threat Intelligence enriches the platform with signatures, IOCs, TTPs and zero-day detections, but it is a distinct subscription/add-on.','https://www.nozominetworks.com/platform/threat-intelligence'),
('nozomi-networks-platform','otsec-soc-integration','supported',0.990,'Nozomi documents SIEM, SOAR, firewall, NAC, ticketing, cloud and OpenAPI integrations across the platform.','https://www.nozominetworks.com/platform/technical-specifications'),
('nozomi-networks-platform','otsec-distributed-deployment','supported',0.980,'The platform offers Vantage cloud management and an on-premises Central Management Console, with remote collectors and multi-site sensor hierarchies; exact air-gapped design depends on selected components.','https://www.nozominetworks.com/platform'),

-- Claroty CTD
('claroty-ctd','otsec-passive-discovery','supported',0.990,'CTD combines passive discovery with deep industrial protocol visibility to build a detailed centralized inventory of XIoT/OT assets.','https://claroty.com/industrial-cybersecurity/ctd'),
('claroty-ctd','otsec-active-enrichment','supported',0.990,'CTD explicitly combines Passive, Active and AppDB discovery methods for deeper asset visibility.','https://claroty.com/industrial-cybersecurity/ctd'),
('claroty-ctd','otsec-topology-mapping','supported',0.990,'CTD maps asset communications and automatically creates Virtual Zones representing normal communication groups.','https://claroty.com/industrial-cybersecurity/ctd'),
('claroty-ctd','otsec-vulnerability-exposure','supported',0.990,'CTD compares assets against insecure protocols, configurations, security practices and CVE data to prioritize exposures.','https://claroty.com/industrial-cybersecurity/ctd'),
('claroty-ctd','otsec-engineering-change-monitoring','supported',0.990,'CTD Operational Behaviors detect configuration downloads/uploads, firmware upgrades, mode/key-state changes and other industrial engineering operations.','https://claroty.com/blog/feature-spotlight-claroty-threat-detection-engines'),
('claroty-ctd','otsec-threat-anomaly-detection','supported',0.990,'CTD uses multiple detection engines including anomaly, security behavior, known-threat, operational-behavior and custom-rule detections.','https://claroty.com/industrial-cybersecurity/ctd'),
('claroty-ctd','otsec-segmentation-policy','partially_supported',0.990,'CTD creates Virtual Zones and detects cross-zone violations; policy enforcement is performed through firewall/NAC integrations rather than assumed as native inline enforcement.','https://claroty.com/industrial-cybersecurity/ctd'),
('claroty-ctd','otsec-threat-intelligence','supported',0.980,'CTD detection content is enriched with Claroty/Team82 research, signatures and MITRE ATT&CK for ICS context.','https://web-assets.claroty.com/resource-downloads/2025-zt-for-ot-wp.pdf'),
('claroty-ctd','otsec-soc-integration','supported',0.980,'Claroty documents standardized logging to SIEM/syslog and ecosystem integrations, alongside firewall/NAC and xDome Secure Access integration.','https://web-assets.claroty.com/resource-downloads/2025-zt-for-ot-wp.pdf'),

-- Dragos Platform
('dragos-platform','otsec-passive-discovery','supported',0.990,'Dragos uses passive-first industrial discovery and continuously maintains OT/xOT asset inventory without operational disruption.','https://www.dragos.com/cybersecurity-platform/asset-visibility/'),
('dragos-platform','otsec-active-enrichment','supported',0.990,'Dragos Active Collector adds targeted active collection for firmware, OS, patch and device details while preserving passive-first discovery.','https://www.dragos.com/cybersecurity-platform/asset-visibility/'),
('dragos-platform','otsec-topology-mapping','supported',0.990,'Dragos maps OT assets, protocols and communications and supports network/zone maps for architecture and segmentation analysis.','https://www.dragos.com/resources/press-release/dragos-named-leader-2026-gartner-magic-quadrant-cps-protection-platforms'),
('dragos-platform','otsec-vulnerability-exposure','supported',0.990,'Dragos maps vulnerabilities to real assets and prioritizes them with OT-corrected scoring and the Now, Next, Never remediation framework.','https://www.dragos.com/cybersecurity-platform/asset-visibility/'),
('dragos-platform','otsec-engineering-change-monitoring','partially_supported',0.960,'Dragos monitors OT communications and abnormal operational behavior, but a universal code-diff/configuration-control function for every controller family is not inferred from the reviewed sources.','https://www.dragos.com/cybersecurity-platform/threat-detection/'),
('dragos-platform','otsec-threat-anomaly-detection','supported',0.990,'Dragos continuously inspects industrial communications and behavior using OT-native detections, adversary intelligence and known/unknown behavior context.','https://www.dragos.com/cybersecurity-platform/threat-detection/'),
('dragos-platform','otsec-segmentation-policy','supported',0.990,'Dragos explicitly provides segmentation validation, zone/connection maps and firewall checks to verify industrial network architecture and policy.','https://www.dragos.com/resources/press-release/dragos-named-leader-2026-gartner-magic-quadrant-cps-protection-platforms'),
('dragos-platform','otsec-threat-intelligence','supported',0.990,'The Dragos Intelligence Fabric and OT threat detections provide adversary research, IOCs/TTPs and MITRE ATT&CK for ICS context directly in analyst workflows.','https://www.dragos.com/cybersecurity-platform/threat-detection/'),
('dragos-platform','otsec-soc-integration','supported',0.990,'Dragos integrates OT asset, alert, vulnerability and threat-intelligence data with SIEM/SOAR platforms including Microsoft Sentinel and Splunk.','https://www.dragos.com/partner/splunk/app'),
('dragos-platform','otsec-distributed-deployment','supported',0.990,'Current Dragos deployment options explicitly include managed SaaS on Azure, on-premises and hybrid models for distributed industrial environments.','https://www.dragos.com/partner/microsoft'),

-- Tenable One OT Exposure
('tenable-one-ot-exposure','otsec-passive-discovery','supported',0.990,'Tenable continuously monitors OT traffic to discover and classify PLCs, IoT and other industrial assets without disruption.','https://www.tenable.com/products/ot-security'),
('tenable-one-ot-exposure','otsec-active-enrichment','supported',0.990,'Safe Active Query uses vendor-approved native industrial protocols to enrich assets with firmware, backplane, lifecycle and vulnerability details.','https://www.tenable.com/products/ot-security'),
('tenable-one-ot-exposure','otsec-topology-mapping','supported',0.990,'Tenable provides network maps showing industrial assets, connections, communication patterns and Purdue-oriented context.','https://docs.tenable.com/OT-security/4_2/Content/Network/NetworkMap.htm'),
('tenable-one-ot-exposure','otsec-vulnerability-exposure','supported',0.990,'Tenable combines OT asset context, Nessus findings and VPR/exposure intelligence to prioritize vulnerabilities that matter to uptime and physical safety.','https://www.tenable.com/products/ot-security'),
('tenable-one-ot-exposure','otsec-engineering-change-monitoring','supported',0.990,'Tenable detects controller start/stop, code edits, function-block changes, tag writes/deletes, snapshot operations and related configuration events.','https://docs.tenable.com/release-notes/Content/OT-security/2026.htm'),
('tenable-one-ot-exposure','otsec-threat-anomaly-detection','supported',0.990,'Tenable uses policy, behavioral-anomaly and signature engines for OT threat detection.','https://docs.tenable.com/OT-security/4_5/Content/Introduction/Technologies.htm'),
('tenable-one-ot-exposure','otsec-segmentation-policy','supported',0.980,'Tenable maps communication patterns, identifies boundary violations and supports segmentation enforcement through integrated security infrastructure.','https://www.tenable.com/products/ot-security'),
('tenable-one-ot-exposure','otsec-threat-intelligence','partially_supported',0.970,'Tenable Research, VPR and IDS content enrich OT exposure and detections, but a separate OT adversary-intelligence workbench equivalent to dedicated CTI products is not inferred.','https://www.tenable.com/products/ot-security'),
('tenable-one-ot-exposure','otsec-soc-integration','supported',0.990,'Tenable integrates with SIEM/SOAR, firewalls and ticketing systems and can trigger automated response workflows through those integrations.','https://www.tenable.com/products/ot-security'),
('tenable-one-ot-exposure','otsec-distributed-deployment','supported',0.990,'Tenable explicitly supports cloud, on-premises and hybrid deployment plus disconnected/air-gapped OT agents and centralized multi-site management.','https://www.tenable.com/products/ot-security'),

-- Microsoft Defender for IoT
('microsoft-defender-for-iot','otsec-passive-discovery','supported',0.990,'Defender for IoT OT sensors passively analyze mirrored industrial traffic and build detailed OT asset inventory without endpoint agents.','https://www.microsoft.com/en-us/security/business/endpoint-security/microsoft-defender-iot'),
('microsoft-defender-for-iot','otsec-active-enrichment','partially_supported',0.980,'Microsoft documents passive and active agentless monitoring, but active-discovery depth varies by device and deployment and is not treated as equivalent to every vendor-specific safe-query implementation.','https://www.microsoft.com/en-us/security/business/endpoint-security/microsoft-defender-iot'),
('microsoft-defender-for-iot','otsec-topology-mapping','supported',0.980,'Defender for IoT sensor investigation includes device-map views and device communication context for monitored OT networks.','https://learn.microsoft.com/en-us/azure/defender-for-iot/organizations/alerts'),
('microsoft-defender-for-iot','otsec-vulnerability-exposure','supported',0.990,'Defender for IoT device inventory maps OT vulnerabilities and security recommendations to specific devices for risk-based remediation.','https://learn.microsoft.com/en-us/azure/defender-for-iot/organizations/vulnerability-management'),
('microsoft-defender-for-iot','otsec-engineering-change-monitoring','supported',0.980,'Defender for IoT operational alerts detect changes such as firmware version changes, PLC mode changes and unauthorized PLC code-change activity.','https://learn.microsoft.com/en-us/azure/defender-for-iot/organizations/alerts'),
('microsoft-defender-for-iot','otsec-threat-anomaly-detection','supported',0.990,'OT network sensors baseline industrial activity and trigger anomaly, protocol-violation, operational and security alerts for suspicious behavior.','https://learn.microsoft.com/en-us/azure/defender-for-iot/organizations/alerts'),
('microsoft-defender-for-iot','otsec-segmentation-policy','partially_supported',0.960,'Defender for IoT provides policy-violation alerts, network/device maps and Zero Trust visibility, but native firewall/NAC segmentation enforcement is not inferred.','https://learn.microsoft.com/en-us/azure/defender-for-iot/organizations/alerts'),
('microsoft-defender-for-iot','otsec-threat-intelligence','partially_supported',0.970,'Alerts include MITRE ATT&CK context and cloud-connected sensors receive threat-intelligence packages, but Defender for IoT is not treated as a standalone OT threat-intelligence product.','https://learn.microsoft.com/en-us/azure/defender-for-iot/organizations/alerts'),
('microsoft-defender-for-iot','otsec-soc-integration','supported',0.990,'Defender for IoT integrates out of the box with Microsoft Sentinel and can forward alerts to third-party SIEM platforms and SOC workflows.','https://learn.microsoft.com/en-us/azure/defender-for-iot/organizations/ot-deploy/ot-deploy-path'),
('microsoft-defender-for-iot','otsec-distributed-deployment','supported',0.980,'Microsoft supports cloud-connected, hybrid and air-gapped OT sensor deployments across sites; cloud-only management features are unavailable to isolated sensors.','https://learn.microsoft.com/en-us/azure/defender-for-iot/organizations/ot-deploy/air-gapped-deploy');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat136_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat136_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party vendor documentation supporting this capability.'
FROM cat136_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Promote deployment only where the current product/platform commercial model is explicit.
INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.990
FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug IN('nozomi-networks-platform','dragos-platform','tenable-one-ot-exposure')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.990
FROM products p JOIN deployment_models d ON d.slug='on-premise'
WHERE p.slug IN('nozomi-networks-platform','claroty-ctd','dragos-platform','tenable-one-ot-exposure')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

-- Defender for IoT combines Azure services with locally managed/cloud-connected/air-gapped OT sensors. Do not collapse this hybrid architecture into the catalog's generic public-SaaS or on-premises product labels.
-- Platform-specific mobile support remains unknown for all five products.
INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000
FROM products p CROSS JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') x
WHERE p.slug IN('nozomi-networks-platform','claroty-ctd','dragos-platform','tenable-one-ot-exposure','microsoft-defender-for-iot')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

COMMIT;
