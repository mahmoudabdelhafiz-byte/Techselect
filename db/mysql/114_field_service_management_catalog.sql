-- TechSelectAI Field Service Management catalog expansion.
-- Adds one canonical FSM category and five evidence-backed current products.
-- Official first-party evidence reviewed Sep 2026. Presence is not an endorsement.
-- Unknown != Unsupported. No Fit Score, recommendation ranking, review score, follower/community popularity or commercial placement logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('Field Service Management','field-service-management','Software for planning, scheduling, dispatching, executing and analyzing service work performed by technicians at customer or asset locations.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @fsm_cat=(SELECT id FROM categories WHERE slug='field-service-management' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@fsm_cat,'Planning, Scheduling & Work','fsm-planning-work','Work orders, technician scheduling, dispatch, routing and customer appointment coordination.',1),
(@fsm_cat,'Field Execution & Service Insight','fsm-execution-insight','Mobile/offline execution, parts, customer communication, reporting and enterprise integrations.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.sec,1
FROM modules m JOIN (
 SELECT 'fsm-planning-work' module_slug,'Work order / service job management' name,'fsm-work-orders' slug,'Create, manage, assign and track field service work orders, service jobs or activities through completion.' description,0 sec UNION ALL
 SELECT 'fsm-planning-work','Scheduling & dispatch optimization','fsm-scheduling-dispatch','Schedule, dispatch and optimize technicians or crews based on availability, skills, location, priority and service constraints.',0 UNION ALL
 SELECT 'fsm-planning-work','Routing / travel optimization','fsm-routing-optimization','Optimize routes, travel time or appointment sequencing for field resources.',0 UNION ALL
 SELECT 'fsm-planning-work','Customer appointment communication / self-service','fsm-customer-appointments','Provide appointment booking, notifications, ETA/tracking, rescheduling or other customer-facing service coordination.',0 UNION ALL
 SELECT 'fsm-execution-insight','Mobile technician execution','fsm-mobile-technician','Allow technicians to access schedules, work orders, customer/asset details, forms, signatures and service tasks from mobile devices.',0 UNION ALL
 SELECT 'fsm-execution-insight','Offline field execution','fsm-offline-execution','Allow technicians to continue supported field workflows without network connectivity and synchronize when service returns.',0 UNION ALL
 SELECT 'fsm-execution-insight','Parts / field inventory','fsm-parts-inventory','Track or consume spare parts, technician stock, depot/warehouse inventory or material usage during field service.',0 UNION ALL
 SELECT 'fsm-execution-insight','Service analytics & KPIs','fsm-analytics-kpis','Provide dashboards, operational KPIs, SLA, productivity, utilization, first-time-fix or service-performance reporting.',0 UNION ALL
 SELECT 'fsm-execution-insight','Enterprise integrations / APIs','fsm-enterprise-integrations','Connect field service work with CRM, ERP, EAM, IoT, finance or external applications through APIs or packaged integrations.',0
) x ON x.module_slug=m.slug
WHERE m.category_id=@fsm_cat
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Salesforce','salesforce','https://www.salesforce.com/','CRM, service, field service and enterprise cloud software vendor.','active'),
('Microsoft','microsoft','https://www.microsoft.com/','Enterprise software, cloud, productivity and business applications vendor.','active'),
('Oracle','oracle','https://www.oracle.com/','Enterprise applications, database, cloud and field service software vendor.','active'),
('IFS','ifs','https://www.ifs.com/','Industrial software vendor spanning ERP, EAM and field service management.','active'),
('PTC','ptc','https://www.ptc.com/','Industrial software vendor for product lifecycle, IoT, augmented reality and field service applications.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat114_products;
CREATE TEMPORARY TABLE cat114_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO cat114_products VALUES
('salesforce','field-service-management','Salesforce Field Service','salesforce-field-service','Field service platform for work orders, appointment scheduling, dispatch optimization, mobile technician execution, inventory and customer service coordination within the Salesforce ecosystem.','https://www.salesforce.com/service/field-service-management/'),
('microsoft','field-service-management','Dynamics 365 Field Service','dynamics-365-field-service','Field service application for work orders, resource scheduling, dispatch, mobile execution, customer communication, inventory and connected service operations.','https://www.microsoft.com/en-us/dynamics-365/products/field-service'),
('oracle','field-service-management','Oracle Fusion Field Service','oracle-fusion-field-service','Cloud field service platform for routing, scheduling, mobile workforce execution, offline work and connected service operations.','https://www.oracle.com/cx/service/field-service/'),
('ifs','field-service-management','IFS Cloud Field Service Management','ifs-cloud-field-service-management','Field service management within IFS Cloud for AI-guided scheduling, dispatch, mobile execution, service logistics and asset/service lifecycle coordination.','https://www.ifs.com/en/products/fsm'),
('ptc','field-service-management','ServiceMax Core','servicemax-core','Enterprise field service management platform for work orders, scheduling and dispatch, technician mobility, parts, service contracts and customer self-service.','https://www.ptc.com/en/products/servicemax/core');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat114_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS cat114_sources;
CREATE TEMPORARY TABLE cat114_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat114_sources VALUES
('salesforce-field-service','https://help.salesforce.com/s/articleView?id=service.pfs_scheduling_services.htm&language=en_US&type=5','Salesforce Field Service Scheduling and Optimization','Salesforce'),
('salesforce-field-service','https://help.salesforce.com/s/articleView?id=service.mfs_overview.htm&language=en_US&type=5','Salesforce Field Service Mobile App','Salesforce'),
('salesforce-field-service','https://help.salesforce.com/s/articleView?id=service.fs_work_order_guidelines.htm&language=en_US&type=5','Salesforce Field Service Work Orders','Salesforce'),
('salesforce-field-service','https://help.salesforce.com/s/articleView?id=service.mfs_appointment_assistant_sss_parent.htm&language=en_US&type=5','Salesforce Appointment Assistant Self-Service Scheduling','Salesforce'),
('dynamics-365-field-service','https://learn.microsoft.com/en-us/dynamics365/field-service/','Dynamics 365 Field Service Documentation','Microsoft'),
('dynamics-365-field-service','https://learn.microsoft.com/en-us/dynamics365/field-service/reports','Dynamics 365 Field Service Overview and Capabilities','Microsoft'),
('dynamics-365-field-service','https://learn.microsoft.com/en-us/dynamics365/field-service/mobile/work-offline','Dynamics 365 Field Service Offline Mode','Microsoft'),
('dynamics-365-field-service','https://www.microsoft.com/en-us/dynamics-365/products/field-service','Dynamics 365 Field Service Product Page','Microsoft'),
('oracle-fusion-field-service','https://docs.oracle.com/en/cloud/saas/field-service/faglo/routing.html','Oracle Fusion Field Service Routing','Oracle'),
('oracle-fusion-field-service','https://docs.oracle.com/en/cloud/saas/field-service/faaca/c-work-offline.html','Oracle Fusion Field Service Work Offline','Oracle'),
('oracle-fusion-field-service','https://docs.oracle.com/en/cloud/saas/field-service/famca/c-mca-activity-work-order-data-flow.html','Oracle Fusion Field Service Work Order Data Flow','Oracle'),
('ifs-cloud-field-service-management','https://www.ifs.com/en/products/fsm','IFS Field Service Management','IFS'),
('ifs-cloud-field-service-management','https://www.ifs.com/en/ifs-cloud','IFS Cloud','IFS'),
('ifs-cloud-field-service-management','https://www.ifs.com/en/insights/assets/ifs-ai-in-ifs-cloud-field-service-management','IFS.ai in Field Service Management','IFS'),
('servicemax-core','https://www.ptc.com/en/products/servicemax/core','ServiceMax Core','PTC'),
('servicemax-core','https://support.ptc.com/help/servicemaxcore/en/articles/core/work-order-lifecycle.html','ServiceMax Work Order Lifecycle','PTC'),
('servicemax-core','https://support.ptc.com/help/servicemaxcore/en/articles/core/inventory-management.html','ServiceMax Inventory Management','PTC'),
('servicemax-core','https://support.ptc.com/help/servicemaxcore/en/articles/go/phone-introduction-to-servicemax-mobile-app.html','ServiceMax Go Mobile App','PTC');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM cat114_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS cat114_facts;
CREATE TEMPORARY TABLE cat114_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat114_facts VALUES
-- Salesforce
('salesforce-field-service','fsm-work-orders','supported',0.990,'Salesforce documents work orders, line items and service appointments as core Field Service records.','https://help.salesforce.com/s/articleView?id=service.fs_work_order_guidelines.htm&language=en_US&type=5'),
('salesforce-field-service','fsm-scheduling-dispatch','supported',0.990,'Salesforce documents manual, semi-automated and optimized scheduling/dispatch for service appointments.','https://help.salesforce.com/s/articleView?id=service.pfs_scheduling_services.htm&language=en_US&type=5'),
('salesforce-field-service','fsm-routing-optimization','supported',0.980,'Salesforce scheduling optimization considers travel time, resource skills, availability and service objectives; exact optimization features depend on enabled Field Service components.','https://help.salesforce.com/s/articleView?id=service.pfs_scheduling_services.htm&language=en_US&type=5'),
('salesforce-field-service','fsm-customer-appointments','partially_supported',0.950,'Appointment Assistant supports customer booking, confirmation, rescheduling and cancellation, but requires the relevant managed package and permission-set licensing.','https://help.salesforce.com/s/articleView?id=service.mfs_appointment_assistant_sss_parent.htm&language=en_US&type=5'),
('salesforce-field-service','fsm-mobile-technician','supported',0.990,'Salesforce Field Service mobile supports technician work, configurable actions, inventory and field data capture.','https://help.salesforce.com/s/articleView?id=service.mfs_overview.htm&language=en_US&type=5'),
('salesforce-field-service','fsm-offline-execution','supported',0.990,'Salesforce documents offline capability for the Field Service mobile app.','https://help.salesforce.com/s/articleView?id=service.mfs_overview.htm&language=en_US&type=5'),
('salesforce-field-service','fsm-parts-inventory','supported',0.990,'Salesforce documents mobile inventory management for consumption, product requests and technician inventory.','https://help.salesforce.com/s/articleView?id=service.mfs_overview.htm&language=en_US&type=5'),

-- Microsoft
('dynamics-365-field-service','fsm-work-orders','supported',0.990,'Microsoft documents end-to-end work order creation, lifecycle, products and services in Dynamics 365 Field Service.','https://learn.microsoft.com/en-us/dynamics365/field-service/'),
('dynamics-365-field-service','fsm-scheduling-dispatch','supported',0.990,'Dynamics 365 Field Service includes schedule board, schedule assistant and resource scheduling optimization capabilities.','https://learn.microsoft.com/en-us/dynamics365/field-service/reports'),
('dynamics-365-field-service','fsm-routing-optimization','supported',0.980,'Microsoft documents resource scheduling based on location, skills, availability, routes and travel time; automated optimization may require Resource Scheduling Optimization.','https://learn.microsoft.com/en-us/dynamics365/field-service/reports'),
('dynamics-365-field-service','fsm-customer-appointments','supported',0.980,'Microsoft documents self-service scheduling, appointment visibility, reminders and notifications through Field Service and Power Apps capabilities.','https://www.microsoft.com/en-us/dynamics-365/products/field-service'),
('dynamics-365-field-service','fsm-mobile-technician','supported',0.990,'Microsoft documents mobile technician execution for iOS, Android and Windows clients.','https://learn.microsoft.com/en-us/dynamics365/field-service/reports'),
('dynamics-365-field-service','fsm-offline-execution','partially_supported',0.950,'Offline mode is supported through configured offline profiles in the classic mobile experience, while the refreshed mobile experience currently does not support offline operation.','https://learn.microsoft.com/en-us/dynamics365/field-service/mobile/work-offline'),
('dynamics-365-field-service','fsm-parts-inventory','supported',0.980,'Microsoft Field Service documentation includes inventory, purchasing and product/service usage in work-order execution.','https://learn.microsoft.com/en-us/dynamics365/field-service/'),
('dynamics-365-field-service','fsm-enterprise-integrations','supported',0.980,'Microsoft documents connected integration with Microsoft 365, Business Central, Dataverse and related Dynamics platform services.','https://www.microsoft.com/en-us/dynamics-365/products/field-service'),

-- Oracle
('oracle-fusion-field-service','fsm-work-orders','supported',0.970,'Oracle Fusion Field Service activities integrate with Oracle Maintenance work orders and service execution; work-order semantics depend on the connected Oracle application.','https://docs.oracle.com/en/cloud/saas/field-service/famca/c-mca-activity-work-order-data-flow.html'),
('oracle-fusion-field-service','fsm-scheduling-dispatch','supported',0.990,'Oracle documents routing algorithms that assign activities to resources based on calendars, work zones and skills.','https://docs.oracle.com/en/cloud/saas/field-service/faglo/routing.html'),
('oracle-fusion-field-service','fsm-routing-optimization','supported',0.990,'Oracle Field Service routing optimizes assignment and sequencing across mobile workers and scheduled activities.','https://docs.oracle.com/en/cloud/saas/field-service/faglo/routing.html'),
('oracle-fusion-field-service','fsm-mobile-technician','supported',0.990,'Oracle Field Service supports browser/mobile-worker execution of scheduled activities and route tasks.','https://docs.oracle.com/en/cloud/saas/field-service/faaca/c-work-offline.html'),
('oracle-fusion-field-service','fsm-offline-execution','supported',0.990,'Oracle documents offline route/activity execution with synchronization when connectivity returns for supported service editions.','https://docs.oracle.com/en/cloud/saas/field-service/faaca/c-work-offline.html'),

-- IFS
('ifs-cloud-field-service-management','fsm-work-orders','supported',0.980,'IFS describes Field Service Management as coordinating service work, dispatch and execution within the connected asset/service lifecycle.','https://www.ifs.com/en/products/fsm'),
('ifs-cloud-field-service-management','fsm-scheduling-dispatch','supported',0.990,'IFS documents AI-driven workforce scheduling and dispatch optimization for complex field service environments.','https://www.ifs.com/en/products/fsm'),
('ifs-cloud-field-service-management','fsm-routing-optimization','supported',0.990,'IFS documents route/travel optimization and resource utilization as part of AI-guided field service planning.','https://www.ifs.com/en/insights/assets/ifs-ai-in-ifs-cloud-field-service-management'),
('ifs-cloud-field-service-management','fsm-mobile-technician','supported',0.980,'IFS documents mobile execution as part of its field service operations; exact device/offline scope should be validated for the selected IFS Cloud release and configuration.','https://www.ifs.com/en/ifs-cloud'),
('ifs-cloud-field-service-management','fsm-enterprise-integrations','supported',0.990,'IFS Cloud connects field service with ERP, EAM, supply chain and asset lifecycle functions on the same platform.','https://www.ifs.com/en/ifs-cloud'),

-- ServiceMax
('servicemax-core','fsm-work-orders','supported',0.990,'ServiceMax documents work order management across creation, entitlement, assignment, execution, parts, service reports and closure.','https://support.ptc.com/help/servicemaxcore/en/articles/core/work-order-lifecycle.html'),
('servicemax-core','fsm-scheduling-dispatch','supported',0.990,'ServiceMax Service Board provides scheduling, dispatch and optimization using skills, location, workload and availability.','https://www.ptc.com/en/products/servicemax/core'),
('servicemax-core','fsm-routing-optimization','supported',0.980,'ServiceMax Service Board documents optimization using location and real-time service context; exact routing features depend on configured Service Board capabilities.','https://www.ptc.com/en/products/servicemax/core'),
('servicemax-core','fsm-customer-appointments','partially_supported',0.950,'ServiceMax Engage provides customer self-service scheduling, service updates and asset visibility; it is an extension of ServiceMax Core and should not be treated as universally included in Core.','https://www.ptc.com/en/products/servicemax/core'),
('servicemax-core','fsm-mobile-technician','supported',0.990,'ServiceMax Go supports technician schedules, work orders, signatures, inventory, asset history and field workflows on mobile devices.','https://support.ptc.com/help/servicemaxcore/en/articles/go/phone-introduction-to-servicemax-mobile-app.html'),
('servicemax-core','fsm-offline-execution','supported',0.990,'ServiceMax Go supports offline work-order processing with synchronization after connectivity returns.','https://support.ptc.com/help/servicemaxcore/en/articles/go/phone-introduction-to-servicemax-mobile-app.html'),
('servicemax-core','fsm-parts-inventory','supported',0.990,'ServiceMax documents field, depot and warehouse inventory, parts requests, receipts, transfers and stock history.','https://support.ptc.com/help/servicemaxcore/en/articles/core/inventory-management.html'),
('servicemax-core','fsm-enterprise-integrations','supported',0.970,'ServiceMax documents APIs, Salesforce-based workflows and third-party integrations; exact integration scope varies by deployment and extension.','https://www.ptc.com/en/products/servicemax/core');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat114_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat114_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party vendor documentation supporting this capability.'
FROM cat114_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Platform-specific mobile access is promoted only where current product documentation is explicit.
INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'supported','supported','vendor_documentation',0.990
FROM products p CROSS JOIN (SELECT 'android' platform UNION ALL SELECT 'ios') x
WHERE p.slug IN('dynamics-365-field-service','servicemax-core')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000
FROM products p CROSS JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') x
WHERE p.slug IN('salesforce-field-service','oracle-fusion-field-service','ifs-cloud-field-service-management')
   OR (p.slug IN('dynamics-365-field-service','servicemax-core') AND x.platform='mobile_web')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

COMMIT;
