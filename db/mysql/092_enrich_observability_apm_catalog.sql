-- TechSelectAI Observability & APM depth pass.
-- Enriches the existing canonical category from migration 061, promotes four researched drafts,
-- and adds Splunk APM as a fifth peer using current first-party evidence.
-- Unknown != Unsupported. No Fit Score or recommendation-ranking logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

SET @apm_cat=(SELECT id FROM categories WHERE slug='observability-apm' LIMIT 1);

-- Reuse the canonical Splunk vendor if it already exists (for example from SIEM); otherwise create it.
INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Splunk','splunk','https://www.splunk.com/','Observability, security and operational intelligence software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),status='active';

DROP TEMPORARY TABLE IF EXISTS cat92_products;
CREATE TEMPORARY TABLE cat92_products(
  vendor_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT
);
INSERT INTO cat92_products VALUES
('datadog','Datadog APM','datadog-apm','Application performance monitoring for service health, distributed tracing, dependency mapping, telemetry correlation and troubleshooting across distributed applications.','https://www.datadoghq.com/product/apm/'),
('new-relic','New Relic APM 360','new-relic-apm-360','Application performance monitoring for service performance, distributed tracing, dependency visibility, errors and correlated application telemetry.','https://newrelic.com/platform/application-monitoring'),
('dynatrace','Dynatrace Application Observability','dynatrace-application-observability','Application observability with real-time performance intelligence, distributed tracing, automatic topology and dependency visibility, telemetry correlation and AI-assisted root-cause analysis.','https://www.dynatrace.com/platform/application-observability/'),
('elastic','Elastic APM','elastic-apm','Application performance monitoring for distributed tracing, service dependency mapping, performance analysis and correlated observability data across instrumented services.','https://www.elastic.co/observability/application-performance-monitoring'),
('splunk','Splunk APM','splunk-apm','Application performance monitoring within Splunk Observability Cloud for service health, full-fidelity distributed tracing, dependency mapping, correlated troubleshooting and root-cause analysis.','https://www.splunk.com/en_us/products/apm-application-performance-monitoring.html');

-- Update the four existing draft rows and add Splunk APM, all in the existing canonical category.
INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,@apm_cat,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat92_products x JOIN vendors v ON v.slug=x.vendor_slug
ON DUPLICATE KEY UPDATE
  vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),
  short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS cat92_sources;
CREATE TEMPORARY TABLE cat92_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat92_sources VALUES
('datadog-apm','https://docs.datadoghq.com/tracing/','Datadog APM documentation','Datadog'),
('datadog-apm','https://docs.datadoghq.com/tracing/services/services_map/','Datadog APM Service Map','Datadog'),
('datadog-apm','https://docs.datadoghq.com/tracing/other_telemetry/connect_logs_and_traces/','Datadog correlate logs and traces','Datadog'),
('new-relic-apm-360','https://docs.newrelic.com/docs/apm/new-relic-apm/getting-started/introduction-apm/','New Relic APM overview','New Relic'),
('new-relic-apm-360','https://docs.newrelic.com/docs/distributed-tracing/concepts/introduction-distributed-tracing/','New Relic distributed tracing','New Relic'),
('new-relic-apm-360','https://docs.newrelic.com/docs/new-relic-solutions/new-relic-one/ui-data/service-maps/service-maps/','New Relic service map','New Relic'),
('new-relic-apm-360','https://docs.newrelic.com/docs/logs/logs-context/logs-in-context/','New Relic logs in context','New Relic'),
('new-relic-apm-360','https://docs.newrelic.com/docs/errors-inbox/errors-inbox/','New Relic error tracking','New Relic'),
('dynatrace-application-observability','https://www.dynatrace.com/platform/application-observability/','Dynatrace Application Observability','Dynatrace'),
('dynatrace-application-observability','https://docs.dynatrace.com/docs/observe/application-observability/distributed-tracing','Dynatrace distributed tracing','Dynatrace'),
('elastic-apm','https://www.elastic.co/observability/application-performance-monitoring','Elastic application performance monitoring','Elastic'),
('elastic-apm','https://www.elastic.co/docs/solutions/observability/apm/service-map','Elastic APM service map','Elastic'),
('elastic-apm','https://www.elastic.co/docs/solutions/observability/apm/traces','Elastic APM traces','Elastic'),
('splunk-apm','https://www.splunk.com/en_us/products/apm-application-performance-monitoring.html','Splunk Application Performance Monitoring','Splunk'),
('splunk-apm','https://help.splunk.com/en/splunk-observability-cloud/monitor-application-performance/manage-services-spans-and-traces-in-splunk-apm/use-the-service-view-in-splunk-apm','Splunk APM service view','Splunk'),
('splunk-apm','https://help.splunk.com/en/splunk-observability-cloud/monitor-application-performance/manage-services-spans-and-traces-in-splunk-apm/view-dependencies-in-the-service-map','Splunk APM service map','Splunk'),
('splunk-apm','https://help.splunk.com/en/splunk-observability-cloud/monitor-application-performance/set-up-splunk-apm','Set up Splunk APM','Splunk'),
('splunk-apm','https://help.splunk.com/en/splunk-observability-cloud/monitor-application-performance/manage-services-spans-and-traces-in-splunk-apm/view-and-filter-for-spans-within-a-trace','Splunk APM trace analysis','Splunk');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM cat92_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS cat92_facts;
CREATE TEMPORARY TABLE cat92_facts(
  product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT
);
INSERT INTO cat92_facts VALUES
-- Datadog APM
('datadog-apm','apm-performance-metrics','supported',0.990,'Datadog APM documents service health and performance analysis through service and resource pages.','https://docs.datadoghq.com/tracing/'),
('datadog-apm','apm-service-dependencies','supported',0.990,'The Service Map draws observed dependencies among component services in real time.','https://docs.datadoghq.com/tracing/services/services_map/'),
('datadog-apm','apm-distributed-tracing','supported',0.990,'Datadog APM provides end-to-end trace exploration across distributed services.','https://docs.datadoghq.com/tracing/'),
('datadog-apm','apm-telemetry-correlation','supported',0.990,'Datadog documents correlation of APM traces with logs and other telemetry; configuration and sampling affect available correlations.','https://docs.datadoghq.com/tracing/other_telemetry/connect_logs_and_traces/'),
('datadog-apm','apm-root-cause','supported',0.970,'Trace Explorer and APM views are documented for identifying performance bottlenecks and troubleshooting errors; automated root-cause semantics vary by workflow.','https://docs.datadoghq.com/tracing/'),

-- New Relic APM 360
('new-relic-apm-360','apm-performance-metrics','supported',0.980,'New Relic APM exposes response time, throughput, error and related application performance data.','https://docs.newrelic.com/docs/apm/new-relic-apm/getting-started/introduction-apm/'),
('new-relic-apm-360','apm-service-dependencies','supported',0.990,'Service map displays relationships among applications, databases, hosts, servers and external services.','https://docs.newrelic.com/docs/new-relic-solutions/new-relic-one/ui-data/service-maps/service-maps/'),
('new-relic-apm-360','apm-distributed-tracing','supported',0.990,'New Relic distributed tracing tracks requests and spans across distributed services.','https://docs.newrelic.com/docs/distributed-tracing/concepts/introduction-distributed-tracing/'),
('new-relic-apm-360','apm-telemetry-correlation','supported',0.980,'Logs in context links log data with APM, distributed tracing and error experiences.','https://docs.newrelic.com/docs/logs/logs-context/logs-in-context/'),
('new-relic-apm-360','apm-root-cause','supported',0.960,'Errors Inbox and APM troubleshooting provide stack, trace and contextual signals used to surface causes; specific automated analysis depends on the feature and data available.','https://docs.newrelic.com/docs/errors-inbox/errors-inbox/'),

-- Dynatrace Application Observability
('dynatrace-application-observability','apm-performance-metrics','supported',0.990,'Dynatrace documents real-time application and service performance intelligence, latency/error baselines and health tracking.','https://www.dynatrace.com/platform/application-observability/'),
('dynatrace-application-observability','apm-service-dependencies','supported',0.990,'Dynatrace documents real-time topology discovery and dependency mapping across services and databases.','https://www.dynatrace.com/platform/application-observability/'),
('dynatrace-application-observability','apm-distributed-tracing','supported',0.990,'Dynatrace Distributed Tracing follows requests across services and components.','https://docs.dynatrace.com/docs/observe/application-observability/distributed-tracing'),
('dynatrace-application-observability','apm-telemetry-correlation','supported',0.990,'Application Observability documents traces, metrics, logs and exceptions automatically correlated in context.','https://www.dynatrace.com/platform/application-observability/'),
('dynatrace-application-observability','apm-root-cause','supported',0.990,'Dynatrace documents AI-powered root-cause and impact analysis across application telemetry.','https://www.dynatrace.com/platform/application-observability/'),

-- Elastic APM
('elastic-apm','apm-performance-metrics','supported',0.980,'Elastic APM documents end-to-end application visibility and analysis of service performance and latency.','https://www.elastic.co/observability/application-performance-monitoring'),
('elastic-apm','apm-service-dependencies','supported',0.990,'Elastic Service Map visualizes instrumented services and observed communication dependencies with service metrics.','https://www.elastic.co/docs/solutions/observability/apm/service-map'),
('elastic-apm','apm-distributed-tracing','supported',0.990,'Elastic APM distributed tracing tracks a request across multiple distributed services and components.','https://www.elastic.co/docs/solutions/observability/apm/traces'),
('elastic-apm','apm-telemetry-correlation','supported',0.970,'Elastic APM describes captured and correlated service/span/request context and correlation of symptoms across observability signals.','https://www.elastic.co/observability/application-performance-monitoring'),
('elastic-apm','apm-root-cause','supported',0.960,'Elastic APM uses correlation and machine learning to surface outliers, patterns and changes associated with performance issues; this is evidence of assisted cause analysis rather than a guarantee of definitive root cause.','https://www.elastic.co/observability/application-performance-monitoring'),

-- Splunk APM
('splunk-apm','apm-performance-metrics','supported',0.990,'Splunk APM service view exposes availability plus request, error, duration, runtime and infrastructure metrics.','https://help.splunk.com/en/splunk-observability-cloud/monitor-application-performance/manage-services-spans-and-traces-in-splunk-apm/use-the-service-view-in-splunk-apm'),
('splunk-apm','apm-service-dependencies','supported',0.990,'Splunk APM Service Map dynamically displays dependencies and connections among instrumented and inferred services.','https://help.splunk.com/en/splunk-observability-cloud/monitor-application-performance/manage-services-spans-and-traces-in-splunk-apm/view-dependencies-in-the-service-map'),
('splunk-apm','apm-distributed-tracing','supported',0.990,'Splunk APM monitors distributed applications using traces composed of spans.','https://help.splunk.com/en/splunk-observability-cloud/monitor-application-performance/set-up-splunk-apm'),
('splunk-apm','apm-telemetry-correlation','supported',0.980,'Splunk APM documents correlation of trace data with logs and related application/infrastructure resources within Observability Cloud.','https://help.splunk.com/en/splunk-observability-cloud/monitor-application-performance/set-up-splunk-apm'),
('splunk-apm','apm-root-cause','supported',0.990,'Splunk APM trace troubleshooting identifies bottlenecks and root-cause error spans, with AI-assisted investigation available for supported workflows.','https://help.splunk.com/en/splunk-observability-cloud/monitor-application-performance/manage-services-spans-and-traces-in-splunk-apm/view-and-filter-for-spans-within-a-trace');

-- Insert missing capability rows, then refresh any existing broad facts with the reviewed source-specific facts.
INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat92_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
WHERE NOT EXISTS(
  SELECT 1 FROM product_capabilities pc
  WHERE pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
);

UPDATE product_capabilities pc
JOIN products p ON p.id=pc.product_id
JOIN capabilities c ON c.id=pc.capability_id
JOIN cat92_facts f ON f.product_slug=p.slug AND f.capability_slug=c.slug
SET pc.support_status=f.support_status,
    pc.limitations=f.limitations,
    pc.confidence_score=f.confidence,
    pc.last_verified_at=NOW()
WHERE pc.edition_id IS NULL;

-- Explicit unknowns for any future/current canonical APM capability not covered by this research pass.
INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,c.id,NULL,'not_yet_verified',0.000
FROM cat92_products x
JOIN products p ON p.slug=x.product_slug
JOIN modules m ON m.category_id=@apm_cat AND m.is_active=1
JOIN capabilities c ON c.module_id=m.id AND c.is_active=1
WHERE NOT EXISTS(
  SELECT 1 FROM product_capabilities pc
  WHERE pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
);

-- Exact fact-to-evidence linkage.
INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,f.limitations
FROM cat92_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Ensure mobile evaluation rows exist after the products are active. No mobile support is inferred here.
INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000
FROM products p
CROSS JOIN (
  SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web'
) x
WHERE p.slug IN ('datadog-apm','new-relic-apm-360','dynatrace-application-observability','elastic-apm','splunk-apm')
ON DUPLICATE KEY UPDATE product_id=VALUES(product_id);

COMMIT;
