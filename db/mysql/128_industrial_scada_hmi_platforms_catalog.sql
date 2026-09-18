-- TechSelectAI Industrial SCADA & HMI Platforms catalog expansion.
-- Adds one canonical SCADA/HMI category and five evidence-backed current products.
-- Official first-party evidence reviewed Sep 2026. Presence is not an endorsement.
-- Unknown != Unsupported. No Fit Score, recommendation ranking, review score, follower/community popularity or commercial placement logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('Industrial SCADA & HMI Platforms','industrial-scada-hmi-platforms','Industrial supervisory-control and HMI software for operator visualization, alarms, industrial connectivity, historian/data logging, redundancy, remote access, extensibility, analytics and enterprise-scale plant supervision.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @scada_cat=(SELECT id FROM categories WHERE slug='industrial-scada-hmi-platforms' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@scada_cat,'Supervisory Operations & Operator Experience','scada-operations-control','Operator visualization and control, alarming, industrial connectivity and remote/mobile HMI access.',1),
(@scada_cat,'Data, Resilience & Enterprise Integration','scada-data-resilience','Historian/logging, redundancy, scripting/extensibility, analytics, multi-site architecture and security/governance capabilities.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.sec,1
FROM modules m JOIN (
 SELECT 'scada-operations-control' module_slug,'HMI visualization & supervisory control' name,'scada-hmi-visualization-control' slug,'Build and operate industrial visualization, control screens, trends and process displays for plant-floor or distributed supervisory operations.' description,0 sec UNION ALL
 SELECT 'scada-operations-control','Alarm & event management','scada-alarm-event-management','Configure, display, acknowledge, route, analyze or notify on process alarms and events with operator-focused workflows.',0 UNION ALL
 SELECT 'scada-operations-control','Industrial protocol & device connectivity','scada-industrial-connectivity','Connect PLCs, RTUs, devices and industrial software using supported native drivers, OPC UA/OPC, MQTT or other industrial protocols.',0 UNION ALL
 SELECT 'scada-operations-control','Web, mobile & remote operator access','scada-web-mobile-remote','Provide remote or browser-based operator visualization and control, including mobile-responsive access where explicitly documented.',0 UNION ALL
 SELECT 'scada-data-resilience','Historian, time-series & process-data logging','scada-historian-logging','Log, store, retrieve and trend historical process values, alarms or events using built-in logging or connected historian functions.',0 UNION ALL
 SELECT 'scada-data-resilience','Redundancy & high availability','scada-redundancy-high-availability','Support redundant servers, failover, continuity of alarms/data or other high-availability architectures for critical supervisory operations.',0 UNION ALL
 SELECT 'scada-data-resilience','Scripting, APIs & application extensibility','scada-scripting-extensibility','Extend SCADA behavior and integrate external systems using supported scripting, APIs, SDKs, custom objects or application frameworks.',0 UNION ALL
 SELECT 'scada-data-resilience','Reporting, dashboards & operational analytics','scada-reporting-analytics','Provide reports, dashboards, KPI visualization, trends or operational analysis using native or explicitly connected functions.',0 UNION ALL
 SELECT 'scada-data-resilience','Enterprise / multi-site SCADA management','scada-enterprise-multisite','Scale supervisory architecture across multiple plants, sites or distributed assets with centralized visibility, configuration or administration where supported.',0 UNION ALL
 SELECT 'scada-data-resilience','Role-based security, audit & secure operations','scada-security-rbac-audit','Provide authentication, user/role permissions, auditability or secure communications appropriate to industrial supervisory systems where explicitly documented.',1
) x ON x.module_slug=m.slug
WHERE m.category_id=@scada_cat
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Inductive Automation','inductive-automation','https://inductiveautomation.com/','Industrial SCADA, HMI, IIoT and automation software vendor.','active'),
('Siemens','siemens','https://www.siemens.com/','Industrial automation, HMI, SCADA and manufacturing software vendor.','active'),
('Rockwell Automation','rockwell-automation','https://www.rockwellautomation.com/','Industrial automation, HMI, SCADA and manufacturing software vendor.','active'),
('GE Vernova','ge-vernova','https://www.gevernova.com/','Energy and industrial software provider including Proficy HMI/SCADA products.','active'),
('Schneider Electric','schneider-electric','https://www.se.com/','Industrial automation, energy management and SCADA software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat128_products;
CREATE TEMPORARY TABLE cat128_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO cat128_products VALUES
('inductive-automation','industrial-scada-hmi-platforms','Ignition','inductive-automation-ignition','Modular cross-platform industrial software platform for SCADA, HMI, alarming, industrial connectivity, historian, reporting, enterprise administration and mobile-responsive applications.','https://inductiveautomation.com/ignition/'),
('siemens','industrial-scada-hmi-platforms','SIMATIC WinCC Unified','simatic-wincc-unified','Siemens HMI/SCADA platform spanning Unified Panels and PC runtime with web-native visualization, alarming, process-data logging, OPC UA connectivity, remote web clients and optional redundancy.','https://www.siemens.com/en-us/products/simatic-hmi/unified-edge-apps/'),
('rockwell-automation','industrial-scada-hmi-platforms','FactoryTalk View Site Edition','factorytalk-view-se','Distributed HMI/SCADA software for real-time visualization, alarms/events, industrial data connectivity, data logging, redundancy and web-client extensions in process, batch and discrete applications.','https://www.rockwellautomation.com/en-us/products/software/factorytalk/operationsuite/view/factorytalk-view-site-edition.html'),
('ge-vernova','industrial-scada-hmi-platforms','Proficy CIMPLICITY','ge-vernova-cimplicity','Enterprise HMI/SCADA platform for high-volume industrial monitoring and control with advanced alarms, broad device connectivity, redundancy, historization, HTML5 visualization, APIs and multi-site architectures.','https://www.gevernova.com/software/products/hmi-scada/cimplicity'),
('schneider-electric','industrial-scada-hmi-platforms','EcoStruxure Geo SCADA Expert','ecostruxure-geo-scada-expert','Telemetry and remote SCADA platform with alarm management, built-in historian, wide-area protocol connectivity, redundancy, web/mobile clients, scripting and scalable enterprise architecture.','https://www.se.com/sa/en/product-range/61264-ecostruxure-geo-scada-expert/');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat128_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS cat128_sources;
CREATE TEMPORARY TABLE cat128_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat128_sources VALUES
('inductive-automation-ignition','https://inductiveautomation.com/ignition/','Ignition Industrial Platform','Inductive Automation'),
('inductive-automation-ignition','https://inductiveautomation.com/ignition/modules','Ignition Modules','Inductive Automation'),
('inductive-automation-ignition','https://inductiveautomation.com/ignition/modules/ignition-opc-ua','Ignition OPC UA Module','Inductive Automation'),
('inductive-automation-ignition','https://inductiveautomation.com/ignition/platform','Ignition Platform','Inductive Automation'),
('simatic-wincc-unified','https://www.siemens.com/en-us/products/simatic-hmi/unified-edge-apps/','SIMATIC WinCC Unified for Industrial Edge','Siemens'),
('simatic-wincc-unified','https://support.industry.siemens.com/cs/attachments/109828368/WinCC_VisualizingProcessesUnified_enUS_en-US.pdf','WinCC Unified V19 System Manual','Siemens'),
('simatic-wincc-unified','https://support.industry.siemens.com/cs/attachments/109963850/Install_STEP7_WinCC_V20_enUS.pdf','WinCC Unified V20 Installation and Licensing','Siemens'),
('simatic-wincc-unified','https://press.siemens.com/global/en/pressrelease/tia-portal-v21-combines-engineering-efficiency-higher-plant-availability','TIA Portal V21 and WinCC Unified High Availability','Siemens'),
('factorytalk-view-se','https://www.rockwellautomation.com/en-us/products/software/factorytalk/operationsuite/view/factorytalk-view-site-edition.html','FactoryTalk View Site Edition','Rockwell Automation'),
('factorytalk-view-se','https://www.rockwellautomation.com/en-gb/docs/factorytalk-view/16-00-00/se-help-ditamap/factorytalk-view-site-edition-help/quick-start-steps.html','FactoryTalk View SE Quick Start','Rockwell Automation'),
('factorytalk-view-se','https://www.rockwellautomation.com/en-pl/docs/factorytalk-view/16-00-00/se-help-ditamap/factorytalk-view-se-tools/ftv-se-application-manager/create-a-backup.html','FactoryTalk View SE Application Manager','Rockwell Automation'),
('ge-vernova-cimplicity','https://www.gevernova.com/software/products/hmi-scada/cimplicity','CIMPLICITY Enterprise HMI SCADA','GE Vernova'),
('ge-vernova-cimplicity','https://www.gevernova.com/software/product-trials/cimplicity-hmi-scada','CIMPLICITY Trial and Installer','GE Vernova'),
('ecostruxure-geo-scada-expert','https://www.se.com/sa/en/product-range/61264-ecostruxure-geo-scada-expert/','EcoStruxure Geo SCADA Expert','Schneider Electric'),
('ecostruxure-geo-scada-expert','https://download.se.com/files?p_Doc_Ref=Geo_SCADA_Brochure&p_File_Name=998-23990200+TBULM01028+Geo+SCADA+Brochure_Letter_GMA_WEB.pdf&p_enDocType=Brochure','EcoStruxure Geo SCADA Expert 2025 Brochure','Schneider Electric'),
('ecostruxure-geo-scada-expert','https://www.se.com/sa/en/product/TBUCSRV-5000PT/license-ecostruxure-geo-scada-expert-server-5000-point/','EcoStruxure Geo SCADA Expert Server License','Schneider Electric'),
('ecostruxure-geo-scada-expert','https://www.se.com/us/en/product/TBUCWEB-0001CWC/license-ecostruxure-geo-scada-expert-webx-1-connection/','EcoStruxure Geo SCADA Expert WebX','Schneider Electric'),
('ecostruxure-geo-scada-expert','https://eshop.se.com/sa/driver-ecostruxure-geo-scada-expert-opc-server-opc-clients-tbuclic-opc.html','EcoStruxure Geo SCADA Expert OPC Driver','Schneider Electric');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM cat128_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS cat128_facts;
CREATE TEMPORARY TABLE cat128_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat128_facts VALUES
-- Ignition
('inductive-automation-ignition','scada-hmi-visualization-control','supported',0.990,'Ignition is explicitly positioned for SCADA/HMI applications with Vision and Perspective visualization modules; exact client experience depends on selected modules.','https://inductiveautomation.com/ignition/'),
('inductive-automation-ignition','scada-alarm-event-management','supported',0.990,'Ignition includes alarm-management capabilities, with additional notification channels delivered through dedicated notification modules.','https://inductiveautomation.com/ignition/'),
('inductive-automation-ignition','scada-industrial-connectivity','supported',0.990,'Ignition includes OPC UA client/server functionality and core drivers for major PLC families, with MQTT and additional drivers available through modules.','https://inductiveautomation.com/ignition/modules/ignition-opc-ua'),
('inductive-automation-ignition','scada-web-mobile-remote','partially_supported',0.990,'Ignition Perspective provides HTML5 mobile-responsive applications and iOS/Android access, but Perspective is a module rather than assumed in every platform configuration.','https://inductiveautomation.com/ignition/platform'),
('inductive-automation-ignition','scada-historian-logging','partially_supported',0.990,'Ignition provides Historian Core and SQL Historian modules, so historian capability is available but modular rather than universal in every license configuration.','https://inductiveautomation.com/ignition/modules'),
('inductive-automation-ignition','scada-scripting-extensibility','supported',0.990,'Ignition is built around extensible scripting and open technologies including Python, SQL, OPC UA and MQTT.','https://inductiveautomation.com/ignition/'),
('inductive-automation-ignition','scada-reporting-analytics','partially_supported',0.980,'Ignition provides reporting, historian visualization and alarm-analysis modules; exact reporting/analytics capability depends on the selected module set.','https://inductiveautomation.com/ignition/modules'),
('inductive-automation-ignition','scada-enterprise-multisite','partially_supported',0.980,'Ignition provides Enterprise Administration for centralized management of multiple Ignition installations; this is a dedicated module rather than universal base-platform entitlement.','https://inductiveautomation.com/ignition/modules'),

-- Siemens WinCC Unified
('simatic-wincc-unified','scada-hmi-visualization-control','supported',0.990,'Siemens documents WinCC Unified as a unified HMI/SCADA system spanning panels, PC runtime and distributed SCADA applications.','https://support.industry.siemens.com/cs/attachments/109828368/WinCC_VisualizingProcessesUnified_enUS_en-US.pdf'),
('simatic-wincc-unified','scada-alarm-event-management','supported',0.990,'WinCC Unified supports discrete, analog and OPC UA alarms, alarm classes and alarm logging.','https://support.industry.siemens.com/cs/attachments/109828368/WinCC_VisualizingProcessesUnified_enUS_en-US.pdf'),
('simatic-wincc-unified','scada-industrial-connectivity','supported',0.990,'WinCC Unified supports Siemens PLCs, third-party PLC protocols and OPC UA client/server connectivity.','https://support.industry.siemens.com/cs/attachments/109828368/WinCC_VisualizingProcessesUnified_enUS_en-US.pdf'),
('simatic-wincc-unified','scada-web-mobile-remote','supported',0.990,'WinCC Unified web clients can access runtime from PCs or smartphones through supported web browsers and remote-access licensing.','https://support.industry.siemens.com/cs/attachments/109828368/WinCC_VisualizingProcessesUnified_enUS_en-US.pdf'),
('simatic-wincc-unified','scada-historian-logging','supported',0.990,'WinCC Unified supports process-value and alarm logging, with current releases adding Unified Data Hub for central long-term archive scenarios.','https://press.siemens.com/global/en/pressrelease/tia-portal-v21-combines-engineering-efficiency-higher-plant-availability'),
('simatic-wincc-unified','scada-redundancy-high-availability','partially_supported',0.990,'WinCC Unified PC supports redundant server architectures, but redundancy requires a separate option license and has documented scope restrictions.','https://support.industry.siemens.com/cs/attachments/109963850/Install_STEP7_WinCC_V20_enUS.pdf'),
('simatic-wincc-unified','scada-scripting-extensibility','supported',0.970,'WinCC Unified uses web technologies and supports extensible application behavior and open interfaces; exact interfaces depend on runtime and licensed options.','https://www.siemens.com/en-us/products/simatic-hmi/unified-edge-apps/'),
('simatic-wincc-unified','scada-enterprise-multisite','partially_supported',0.970,'Current WinCC Unified architecture supports distributed systems and central archive across multiple PC runtimes, but this is not treated as a universal full enterprise-management layer.','https://press.siemens.com/global/en/pressrelease/tia-portal-v21-combines-engineering-efficiency-higher-plant-availability'),

-- FactoryTalk View SE
('factorytalk-view-se','scada-hmi-visualization-control','supported',0.990,'FactoryTalk View SE provides scalable HMI visualization and real-time operator control for process, batch and discrete applications.','https://www.rockwellautomation.com/en-us/products/software/factorytalk/operationsuite/view/factorytalk-view-site-edition.html'),
('factorytalk-view-se','scada-alarm-event-management','supported',0.990,'FactoryTalk View SE supports FactoryTalk Alarms and Events, alarm servers and current alarm-banner functionality.','https://www.rockwellautomation.com/en-gb/docs/factorytalk-view/16-00-00/se-help-ditamap/factorytalk-view-site-edition-help/quick-start-steps.html'),
('factorytalk-view-se','scada-industrial-connectivity','supported',0.990,'FactoryTalk View SE uses FactoryTalk Linx for Rockwell device connectivity and can also use third-party OPC servers.','https://www.rockwellautomation.com/en-gb/docs/factorytalk-view/16-00-00/se-help-ditamap/factorytalk-view-site-edition-help/quick-start-steps.html'),
('factorytalk-view-se','scada-web-mobile-remote','partially_supported',0.980,'FactoryTalk ViewPoint provides web-client access for FactoryTalk View SE, so browser access is available through a companion component rather than assumed core entitlement.','https://www.rockwellautomation.com/en-us/products/software/factorytalk/operationsuite/view/factorytalk-view-site-edition.html'),
('factorytalk-view-se','scada-historian-logging','partially_supported',0.990,'FactoryTalk View SE includes DataLog/DataLogPro logging, while FactoryTalk Historian SE is a separate historian product and must not be treated as bundled.','https://www.rockwellautomation.com/en-pl/docs/factorytalk-view/16-00-00/se-help-ditamap/factorytalk-view-se-tools/ftv-se-application-manager/create-a-backup.html'),
('factorytalk-view-se','scada-redundancy-high-availability','supported',0.990,'FactoryTalk View SE supports HMI-server and alarm/event redundancy in supported architectures.','https://www.rockwellautomation.com/en-pl/docs/factorytalk-view/16-00-00/se-help-ditamap/factorytalk-view-se-tools/ftv-se-application-manager/create-a-backup.html'),
('factorytalk-view-se','scada-scripting-extensibility','supported',0.970,'FactoryTalk View SE supports extensibility through application scripting and current releases add integration options such as MQTT libraries; exact scope depends on configuration.','https://www.rockwellautomation.com/en-us/products/software/factorytalk/operationsuite/view/factorytalk-view-site-edition.html'),
('factorytalk-view-se','scada-reporting-analytics','partially_supported',0.970,'FactoryTalk View SE supports trends and DataLogPro analytics-oriented logging, while advanced historian/analytics functions may require separate FactoryTalk products.','https://www.rockwellautomation.com/en-us/products/software/factorytalk/operationsuite/view/factorytalk-view-site-edition.html'),

-- GE Vernova CIMPLICITY
('ge-vernova-cimplicity','scada-hmi-visualization-control','supported',0.990,'CIMPLICITY provides high-performance enterprise HMI/SCADA visualization and supervisory control for large industrial operations.','https://www.gevernova.com/software/products/hmi-scada/cimplicity'),
('ge-vernova-cimplicity','scada-alarm-event-management','supported',0.990,'CIMPLICITY includes advanced alarming, notification and customizable event-management capabilities.','https://www.gevernova.com/software/products/hmi-scada/cimplicity'),
('ge-vernova-cimplicity','scada-industrial-connectivity','supported',0.990,'CIMPLICITY provides broad I/O drivers for mixed-vendor industrial devices and supports enterprise integration methods including APIs and SQL.','https://www.gevernova.com/software/products/hmi-scada/cimplicity'),
('ge-vernova-cimplicity','scada-web-mobile-remote','supported',0.980,'CIMPLICITY provides native and HTML5-based visualization and documents secure, mobile-friendly centralized operations.','https://www.gevernova.com/software/products/hmi-scada/cimplicity'),
('ge-vernova-cimplicity','scada-historian-logging','partially_supported',0.990,'CIMPLICITY supports SQL historization and integration with Proficy Historian, but the separate Proficy Historian product is not treated as universally bundled.','https://www.gevernova.com/software/products/hmi-scada/cimplicity'),
('ge-vernova-cimplicity','scada-redundancy-high-availability','supported',0.990,'CIMPLICITY explicitly supports high-availability and redundancy architectures for 24/7 industrial operation.','https://www.gevernova.com/software/products/hmi-scada/cimplicity'),
('ge-vernova-cimplicity','scada-scripting-extensibility','supported',0.990,'CIMPLICITY supports Python, .NET, VB scripting and APIs for custom behavior and integrations.','https://www.gevernova.com/software/products/hmi-scada/cimplicity'),
('ge-vernova-cimplicity','scada-reporting-analytics','supported',0.980,'CIMPLICITY includes KPI, dashboard, reporting and graphical replay functions for operational analysis.','https://www.gevernova.com/software/products/hmi-scada/cimplicity'),
('ge-vernova-cimplicity','scada-enterprise-multisite','supported',0.990,'GE Vernova documents CIMPLICITY as an enterprise SCADA platform supporting centralized multi-site and large-scale architectures.','https://www.gevernova.com/software/products/hmi-scada/cimplicity'),
('ge-vernova-cimplicity','scada-security-rbac-audit','partially_supported',0.970,'CIMPLICITY documents secure-by-design collection and role-based enterprise operation, but a full audit/compliance control matrix is not inferred from the reviewed product page.','https://www.gevernova.com/software/products/hmi-scada/cimplicity'),

-- Schneider Electric Geo SCADA Expert
('ecostruxure-geo-scada-expert','scada-hmi-visualization-control','supported',0.990,'Geo SCADA Expert provides visualization and control for wide-area telemetry and remote SCADA systems.','https://www.se.com/sa/en/product-range/61264-ecostruxure-geo-scada-expert/'),
('ecostruxure-geo-scada-expert','scada-alarm-event-management','supported',0.990,'Schneider Electric explicitly documents powerful alarm management including messaging and alarm redirection.','https://www.se.com/sa/en/product/TBUCSRV-5000PT/license-ecostruxure-geo-scada-expert-server-5000-point/'),
('ecostruxure-geo-scada-expert','scada-industrial-connectivity','supported',0.990,'Geo SCADA Expert supports advanced telemetry/device protocols and licensed OPC server/client connectivity.','https://eshop.se.com/sa/driver-ecostruxure-geo-scada-expert-opc-server-opc-clients-tbuclic-opc.html'),
('ecostruxure-geo-scada-expert','scada-web-mobile-remote','partially_supported',0.990,'Geo SCADA Expert supports full, web and mobile clients, but WebX and mobile access are licensed components rather than assumed in every server license.','https://download.se.com/files?p_Doc_Ref=Geo_SCADA_Brochure&p_File_Name=998-23990200+TBULM01028+Geo+SCADA+Brochure_Letter_GMA_WEB.pdf&p_enDocType=Brochure'),
('ecostruxure-geo-scada-expert','scada-historian-logging','supported',0.990,'Geo SCADA Expert explicitly includes a built-in historian for data, analytics, events and alarms.','https://www.se.com/sa/en/product/TBUCSRV-5000PT/license-ecostruxure-geo-scada-expert-server-5000-point/'),
('ecostruxure-geo-scada-expert','scada-redundancy-high-availability','supported',0.990,'Geo SCADA Expert supports redundant architectures from main/standby through triple redundancy and is designed for server changeover continuity.','https://download.se.com/files?p_Doc_Ref=Geo_SCADA_Brochure&p_File_Name=998-23990200+TBULM01028+Geo+SCADA+Brochure_Letter_GMA_WEB.pdf&p_enDocType=Brochure'),
('ecostruxure-geo-scada-expert','scada-scripting-extensibility','supported',0.980,'Geo SCADA Expert documents integrated Python programming and extensibility for interfaces and analytics.','https://download.se.com/files?p_Doc_Ref=Geo_SCADA_Brochure&p_File_Name=998-23990200+TBULM01028+Geo+SCADA+Brochure_Letter_GMA_WEB.pdf&p_enDocType=Brochure'),
('ecostruxure-geo-scada-expert','scada-reporting-analytics','partially_supported',0.970,'Geo SCADA Expert includes historian analytics and trending, but a broad enterprise BI/reporting suite is not inferred from the reviewed SCADA evidence.','https://www.se.com/sa/en/product/TBUCSRV-5000PT/license-ecostruxure-geo-scada-expert-server-5000-point/'),
('ecostruxure-geo-scada-expert','scada-enterprise-multisite','supported',0.980,'Schneider Electric documents Geo SCADA scaling from small systems to large enterprise environments and distributed wide-area architectures.','https://download.se.com/files?p_Doc_Ref=Geo_SCADA_Brochure&p_File_Name=998-23990200+TBULM01028+Geo+SCADA+Brochure_Letter_GMA_WEB.pdf&p_enDocType=Brochure'),
('ecostruxure-geo-scada-expert','scada-security-rbac-audit','partially_supported',0.960,'Geo SCADA supports user accounts, groups, permissions and secure operations, but a complete audit/compliance control set is not inferred from the reviewed source set.','https://download.se.com/files?p_Doc_Ref=Geo_SCADA_Brochure&p_File_Name=998-23990200+TBULM01028+Geo+SCADA+Brochure_Letter_GMA_WEB.pdf&p_enDocType=Brochure');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat128_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat128_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party vendor documentation supporting this capability.'
FROM cat128_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Promote on-premises deployment only where current product-specific evidence is explicit.
INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.990
FROM products p JOIN deployment_models d ON d.slug='on-premise'
WHERE p.slug IN('inductive-automation-ignition','simatic-wincc-unified','factorytalk-view-se','ecostruxure-geo-scada-expert')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

-- GE documents cloud/hybrid support, but that does not establish a public-SaaS commercial model; leave deployment unverified here.
-- Default platform-specific mobile evidence to unknown.
INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000
FROM products p CROSS JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') x
WHERE p.slug IN('inductive-automation-ignition','simatic-wincc-unified','factorytalk-view-se','ge-vernova-cimplicity','ecostruxure-geo-scada-expert')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

-- Promote only explicit current platform/browser support.
INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'supported','supported','vendor_documentation',0.990
FROM products p CROSS JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') x
WHERE p.slug='inductive-automation-ignition'
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,'mobile_web','supported','supported','vendor_documentation',0.990
FROM products p
WHERE p.slug IN('simatic-wincc-unified','factorytalk-view-se','ge-vernova-cimplicity','ecostruxure-geo-scada-expert')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

COMMIT;
