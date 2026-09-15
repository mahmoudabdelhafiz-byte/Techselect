-- TechSelectAI Network Monitoring depth pass.
-- Enriches the existing canonical category from migration 061, promotes four researched drafts,
-- and adds Paessler PRTG Network Monitor as a fifth peer using current first-party evidence.
-- Unknown != Unsupported. No Fit Score or recommendation-ranking logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

SET @net_cat=(SELECT id FROM categories WHERE slug='network-monitoring' LIMIT 1);

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Paessler','paessler','https://www.paessler.com/','Network and infrastructure monitoring software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat93_products;
CREATE TEMPORARY TABLE cat93_products(
  vendor_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT
);
INSERT INTO cat93_products VALUES
('solarwinds','SolarWinds Network Performance Monitor','solarwinds-network-performance-monitor','Network performance monitoring for multi-vendor device discovery, availability, health, performance metrics, alerting, topology and network-path troubleshooting.','https://www.solarwinds.com/network-performance-monitor'),
('manageengine','ManageEngine OpManager','manageengine-opmanager','Network monitoring for device discovery, availability, health and performance, with fault alerting and topology visualization across enterprise infrastructure.','https://www.manageengine.com/network-monitoring/'),
('datadog','Datadog Network Monitoring','datadog-network-monitoring','Network monitoring for on-premises, cloud and hybrid environments covering network devices, performance, topology, traffic and path analysis with alerting.','https://www.datadoghq.com/product/network-monitoring/'),
('logicmonitor','LogicMonitor Network Monitoring','logicmonitor-network-monitoring','Infrastructure network monitoring with automated discovery, availability and performance metrics, topology, traffic analysis and alerting across hybrid environments.','https://www.logicmonitor.com/network-monitoring'),
('paessler','PRTG Network Monitor','prtg-network-monitor','Network and infrastructure monitoring with automated discovery, availability and performance sensors, alerts, traffic monitoring and network visualization.','https://www.paessler.com/monitoring/network');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,@net_cat,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat93_products x JOIN vendors v ON v.slug=x.vendor_slug
ON DUPLICATE KEY UPDATE
  vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),
  short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS cat93_sources;
CREATE TEMPORARY TABLE cat93_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat93_sources VALUES
('solarwinds-network-performance-monitor','https://www.solarwinds.com/network-performance-monitor','SolarWinds Network Performance Monitor','SolarWinds'),
('manageengine-opmanager','https://www.manageengine.com/network-monitoring/help/getting-started-discovery.html','OpManager discovery documentation','ManageEngine'),
('manageengine-opmanager','https://www.manageengine.com/network-monitoring/network-discovery-tool.html','OpManager network discovery and topology','ManageEngine'),
('manageengine-opmanager','https://www.manageengine.com/network-monitoring/network-monitoring-alerts.html','OpManager network monitoring alerts','ManageEngine'),
('manageengine-opmanager','https://www.manageengine.com/network-monitoring/help/what-you-should-monitor.html','OpManager network performance monitoring guide','ManageEngine'),
('datadog-network-monitoring','https://docs.datadoghq.com/network_monitoring/devices/','Datadog Network Device Monitoring','Datadog'),
('datadog-network-monitoring','https://docs.datadoghq.com/network_monitoring/devices/topology/','Datadog Device Topology Map','Datadog'),
('datadog-network-monitoring','https://docs.datadoghq.com/network_monitoring/network_path/','Datadog Network Path','Datadog'),
('datadog-network-monitoring','https://docs.datadoghq.com/monitors/types/network_path/','Datadog Network Path Monitor','Datadog'),
('logicmonitor-network-monitoring','https://www.logicmonitor.com/network-monitoring','LogicMonitor Network Monitoring','LogicMonitor'),
('logicmonitor-network-monitoring','https://www.logicmonitor.com/support/network-traffic-flow-monitoring-new-ui','LogicMonitor Network Traffic Flow Monitoring','LogicMonitor'),
('logicmonitor-network-monitoring','https://www.logicmonitor.com/support/forecasting/topology-mapping/topology-mapping-overview','LogicMonitor Topology Mapping','LogicMonitor'),
('paessler','https://www.paessler.com/monitoring/network','PRTG Network Monitoring','Paessler'),
('paessler','https://www.paessler.com/manuals/prtg/auto-discovery','PRTG Auto-Discovery','Paessler'),
('paessler','https://www.paessler.com/monitoring/network/network-monitoring-tool','PRTG Network Monitoring Tool','Paessler');

-- Correct the PRTG source product slug before inserting evidence.
UPDATE cat93_sources SET product_slug='prtg-network-monitor' WHERE product_slug='paessler';

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM cat93_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS cat93_facts;
CREATE TEMPORARY TABLE cat93_facts(
  product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT
);
INSERT INTO cat93_facts VALUES
-- SolarWinds NPM
('solarwinds-network-performance-monitor','network-device-discovery','supported',0.990,'Official product documentation states that NPM automatically discovers network devices.','https://www.solarwinds.com/network-performance-monitor'),
('solarwinds-network-performance-monitor','network-availability-health','supported',0.990,'Official product documentation covers fault, availability and health monitoring across network devices.','https://www.solarwinds.com/network-performance-monitor'),
('solarwinds-network-performance-monitor','network-performance-metrics','supported',0.990,'Official product documentation identifies response time, packet loss, bandwidth utilization and device/interface health metrics.','https://www.solarwinds.com/network-performance-monitor'),
('solarwinds-network-performance-monitor','network-alerts-faults','supported',0.990,'Official product documentation describes alerts and fault monitoring.','https://www.solarwinds.com/network-performance-monitor'),
('solarwinds-network-performance-monitor','network-traffic-path','supported',0.990,'Official product documentation describes topology maps and NetPath path troubleshooting.','https://www.solarwinds.com/network-performance-monitor'),
-- ManageEngine OpManager
('manageengine-opmanager','network-device-discovery','supported',0.990,'OpManager documentation supports individual, bulk and scheduled device discovery.','https://www.manageengine.com/network-monitoring/help/getting-started-discovery.html'),
('manageengine-opmanager','network-availability-health','supported',0.980,'Official documentation describes continuous availability and health monitoring for discovered devices and interfaces.','https://www.manageengine.com/network-monitoring/help/what-you-should-monitor.html'),
('manageengine-opmanager','network-performance-metrics','supported',0.980,'Official documentation lists network performance monitoring including interface traffic, packet loss and latency.','https://www.manageengine.com/network-monitoring/help/what-you-should-monitor.html'),
('manageengine-opmanager','network-alerts-faults','supported',0.990,'Official OpManager documentation describes fault alerts, threshold violations, event handling and notification workflows.','https://www.manageengine.com/network-monitoring/network-monitoring-alerts.html'),
('manageengine-opmanager','network-traffic-path','supported',0.970,'Official network discovery documentation describes Layer-2 discovery, topology maps and network visualization.','https://www.manageengine.com/network-monitoring/network-discovery-tool.html'),
-- Datadog Network Monitoring
('datadog-network-monitoring','network-device-discovery','supported',0.990,'Datadog Network Device Monitoring documentation states that devices can be automatically discovered.','https://docs.datadoghq.com/network_monitoring/devices/'),
('datadog-network-monitoring','network-availability-health','supported',0.990,'Datadog Network Device Monitoring documents device up/down state and network-device health visibility.','https://docs.datadoghq.com/network_monitoring/devices/'),
('datadog-network-monitoring','network-performance-metrics','supported',0.990,'Datadog Network Device Monitoring documents bandwidth utilization and network-device metrics.','https://docs.datadoghq.com/network_monitoring/devices/'),
('datadog-network-monitoring','network-alerts-faults','supported',0.980,'Datadog Network Path monitors can alert on threshold breaches including RTT, packet loss and jitter.','https://docs.datadoghq.com/monitors/types/network_path/'),
('datadog-network-monitoring','network-traffic-path','supported',0.990,'Datadog documents topology maps and traceroute-based Network Path analysis.','https://docs.datadoghq.com/network_monitoring/network_path/'),
-- LogicMonitor Network Monitoring
('logicmonitor-network-monitoring','network-device-discovery','supported',0.990,'LogicMonitor states that scheduled discovery automatically detects routers, switches and firewalls.','https://www.logicmonitor.com/network-monitoring'),
('logicmonitor-network-monitoring','network-availability-health','supported',0.980,'Official LogicMonitor network monitoring documentation covers uptime, availability and device health monitoring.','https://www.logicmonitor.com/network-monitoring'),
('logicmonitor-network-monitoring','network-performance-metrics','supported',0.990,'LogicMonitor documents high-frequency monitoring of CPU, bandwidth, latency and related network metrics.','https://www.logicmonitor.com/network-monitoring'),
('logicmonitor-network-monitoring','network-alerts-faults','supported',0.980,'LogicMonitor documents anomaly detection, predictive alerting and automated alert routing.','https://www.logicmonitor.com/network-monitoring'),
('logicmonitor-network-monitoring','network-traffic-path','supported',0.990,'LogicMonitor documents dynamic topology and flow-level network traffic monitoring.','https://www.logicmonitor.com/support/forecasting/topology-mapping/topology-mapping-overview'),
-- PRTG Network Monitor
('prtg-network-monitor','network-device-discovery','supported',0.990,'PRTG documentation describes automatic network-device discovery and sensor creation.','https://www.paessler.com/manuals/prtg/auto-discovery'),
('prtg-network-monitor','network-availability-health','supported',0.990,'PRTG network monitoring documentation covers uptime, device health and availability monitoring.','https://www.paessler.com/monitoring/network'),
('prtg-network-monitor','network-performance-metrics','supported',0.990,'PRTG official documentation covers network performance, bandwidth, traffic and other infrastructure metrics.','https://www.paessler.com/monitoring/network/network-monitoring-tool'),
('prtg-network-monitor','network-alerts-faults','supported',0.990,'PRTG official documentation describes customizable alerts and notifications for network issues.','https://www.paessler.com/monitoring/network'),
('prtg-network-monitor','network-traffic-path','supported',0.960,'PRTG official documentation covers traffic monitoring and network maps; advanced automated Layer 2/3 topology can require PRTG UVexplorer.','https://www.paessler.com/monitoring/network');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score,limitations,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.confidence,f.limitations,NOW()
FROM cat93_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE
  support_status=VALUES(support_status),confidence_score=VALUES(confidence_score),limitations=VALUES(limitations),last_verified_at=NOW();

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party vendor evidence for this network-monitoring capability.'
FROM cat93_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Products added/promoted after the cross-category mobile migration receive explicit unknown mobile rows.
INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000
FROM products p
CROSS JOIN (
  SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web'
) x
WHERE p.slug IN(
  'solarwinds-network-performance-monitor','manageengine-opmanager','datadog-network-monitoring',
  'logicmonitor-network-monitoring','prtg-network-monitor'
)
ON DUPLICATE KEY UPDATE product_id=VALUES(product_id);

COMMIT;
