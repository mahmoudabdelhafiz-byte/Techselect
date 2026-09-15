-- TechSelectAI Transportation Management Systems depth pass.
-- Enriches the existing canonical category from migration 061, promotes four researched drafts,
-- and adds Manhattan Active Transportation Management as a fifth peer using first-party evidence.
-- Unknown != Unsupported. No Fit Score or recommendation-ranking logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

SET @tms_cat=(SELECT id FROM categories WHERE slug='transportation-management-systems' LIMIT 1);

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Manhattan Associates','manhattan-associates','https://www.manh.com/','Supply chain, warehouse and transportation management software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat95_products;
CREATE TEMPORARY TABLE cat95_products(
  vendor_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT
);
INSERT INTO cat95_products VALUES
('sap','SAP Transportation Management','sap-transportation-management','Transportation management for freight planning, carrier selection, execution, shipment monitoring and freight settlement across integrated logistics processes.','https://www.sap.com/products/scm/transportation-logistics.html'),
('oracle','Oracle Transportation Management','oracle-transportation-management','Cloud transportation management for multimodal planning, shipment execution, carrier collaboration, visibility and freight cost management.','https://www.oracle.com/scm/logistics/transportation-management/'),
('blue-yonder','Blue Yonder Transportation Management','blue-yonder-transportation-management','Transportation management combining multimodal planning and optimization, carrier and fleet execution, shipment visibility and transportation analytics.','https://blueyonder.com/solutions/transportation-management'),
('descartes','Descartes Transportation Manager','descartes-transportation-manager','Cloud transportation management for multimodal planning, carrier selection, shipment execution, real-time visibility, freight audit and settlement workflows.','https://www.descartes.com/solutions/transportation-management/tms'),
('manhattan-associates','Manhattan Active Transportation Management','manhattan-active-transportation-management','Transportation management that unifies planning, execution, visibility and settlement with adaptive optimization across transportation operations.','https://www.manh.com/solutions/supply-chain-management-software/transportation-management');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,@tms_cat,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat95_products x JOIN vendors v ON v.slug=x.vendor_slug
ON DUPLICATE KEY UPDATE
  vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),
  short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS cat95_sources;
CREATE TEMPORARY TABLE cat95_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat95_sources VALUES
('sap-transportation-management','https://help.sap.com/docs/SAP_S4HANA_CLOUD/a376cd9ea00d476b96f18dea1247e6a5/6486beeb38114fdc94261ef2829d5b03.html','SAP Transportation Management - planning, execution and settlement','SAP'),
('sap-transportation-management','https://learning.sap.com/courses/implementing-sap-s-4hana-cloud-public-edition-transportation-management/introducing-transportation-management_ef758595-447f-44c9-befd-76cc95f9962d','Introducing Transportation Management','SAP'),
('oracle-transportation-management','https://docs.oracle.com/en/cloud/saas/transportation/26c/','Oracle Transportation and Global Trade Management 26C','Oracle'),
('oracle-transportation-management','https://docs.oracle.com/en/cloud/saas/transportation/25c/otmol/configuration/setting_up_otm/transport_planning.htm','Oracle Transportation Management transport planning','Oracle'),
('oracle-transportation-management','https://docs.oracle.com/en/cloud/saas/transportation/26a/otmol/configuration/setting_up_otm/shipment_execution.htm','Oracle Transportation Management shipment execution and visibility','Oracle'),
('blue-yonder-transportation-management','https://blueyonder.com/solutions/transportation-management','Blue Yonder Transportation Management','Blue Yonder'),
('blue-yonder-transportation-management','https://blueyonder.com/solutions/transportation-management/transportation-planning','Blue Yonder Transportation Planning','Blue Yonder'),
('blue-yonder-transportation-management','https://blueyonder.com/solutions/transportation-management/transportation-execution','Blue Yonder Transportation Execution','Blue Yonder'),
('descartes-transportation-manager','https://www.descartes.com/solutions/transportation-management/tms','Descartes Transportation Management System','Descartes'),
('descartes-transportation-manager','https://www.descartes.com/resources/knowledge-center/faq-tms-and-visibility','Descartes TMS and visibility FAQ','Descartes'),
('descartes-transportation-manager','https://www.descartes.com/solutions/transportation-management/analytics-reporting','Descartes transportation analytics and reporting','Descartes'),
('manhattan-active-transportation-management','https://www.manh.com/solutions/supply-chain-management-software/transportation-management','Manhattan Active Transportation Management','Manhattan Associates');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM cat95_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS cat95_facts;
CREATE TEMPORARY TABLE cat95_facts(
  product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT
);
INSERT INTO cat95_facts VALUES
-- SAP Transportation Management
('sap-transportation-management','tms-planning-routing','supported',0.990,'SAP documents transportation planning and freight-unit based planning processes.','https://help.sap.com/docs/SAP_S4HANA_CLOUD/a376cd9ea00d476b96f18dea1247e6a5/6486beeb38114fdc94261ef2829d5b03.html'),
('sap-transportation-management','tms-carrier-optimization','supported',0.960,'SAP documents carrier selection and load-planning methods within transportation planning.','https://learning.sap.com/courses/implementing-sap-s-4hana-cloud-public-edition-transportation-management/introducing-transportation-management_ef758595-447f-44c9-befd-76cc95f9962d'),
('sap-transportation-management','tms-shipment-execution','supported',0.990,'SAP documents freight-order execution as a core TM process.','https://help.sap.com/docs/SAP_S4HANA_CLOUD/a376cd9ea00d476b96f18dea1247e6a5/6486beeb38114fdc94261ef2829d5b03.html'),
('sap-transportation-management','tms-shipment-visibility','supported',0.950,'SAP TM supports monitoring and status visibility across transportation execution.','https://learning.sap.com/courses/implementing-sap-s-4hana-cloud-public-edition-transportation-management/introducing-transportation-management_ef758595-447f-44c9-befd-76cc95f9962d'),
('sap-transportation-management','tms-freight-cost','supported',0.990,'SAP documents charge calculation, freight cost confirmation and freight settlement.','https://help.sap.com/docs/SAP_S4HANA_CLOUD/a376cd9ea00d476b96f18dea1247e6a5/6486beeb38114fdc94261ef2829d5b03.html'),
-- Oracle Transportation Management
('oracle-transportation-management','tms-planning-routing','supported',0.990,'Oracle documents shipment building, bulk planning and transport planning.','https://docs.oracle.com/en/cloud/saas/transportation/25c/otmol/configuration/setting_up_otm/transport_planning.htm'),
('oracle-transportation-management','tms-carrier-optimization','supported',0.950,'Oracle OTM planning uses rates, modes and service-provider data in transportation planning workflows.','https://docs.oracle.com/en/cloud/saas/transportation/25c/otmol/configuration/setting_up_otm/transport_planning.htm'),
('oracle-transportation-management','tms-shipment-execution','supported',0.990,'Oracle documents shipment execution and operational event handling.','https://docs.oracle.com/en/cloud/saas/transportation/26a/otmol/configuration/setting_up_otm/shipment_execution.htm'),
('oracle-transportation-management','tms-shipment-visibility','supported',0.990,'Oracle documents shipment tracking events, shipment visibility, order visibility and track-and-trace.','https://docs.oracle.com/en/cloud/saas/transportation/26a/otmol/configuration/setting_up_otm/shipment_execution.htm'),
('oracle-transportation-management','tms-freight-cost','supported',0.940,'Oracle Transportation Management centrally manages transportation operations including rates and shipment charges; deeper settlement detail remains edition/workflow dependent.','https://docs.oracle.com/en/cloud/saas/transportation/26c/'),
-- Blue Yonder Transportation Management
('blue-yonder-transportation-management','tms-planning-routing','supported',0.990,'Blue Yonder documents multimodal transportation optimization, routing and load planning.','https://blueyonder.com/solutions/transportation-management/transportation-planning'),
('blue-yonder-transportation-management','tms-carrier-optimization','supported',0.990,'Blue Yonder explicitly documents optimization across routes, carriers, modes and consolidation strategies.','https://blueyonder.com/solutions/transportation-management/transportation-planning'),
('blue-yonder-transportation-management','tms-shipment-execution','supported',0.990,'Blue Yonder documents shipment building, tendering and multimodal execution.','https://blueyonder.com/solutions/transportation-management/transportation-execution'),
('blue-yonder-transportation-management','tms-shipment-visibility','supported',0.990,'Blue Yonder documents network-powered transportation visibility and execution updates.','https://blueyonder.com/solutions/transportation-management/transportation-execution'),
-- Descartes Transportation Manager
('descartes-transportation-manager','tms-planning-routing','supported',0.980,'Descartes documents multimodal planning, consolidation and route-planning capabilities.','https://www.descartes.com/solutions/transportation-management/tms'),
('descartes-transportation-manager','tms-carrier-optimization','supported',0.980,'Descartes documents automated carrier selection and carrier connectivity.','https://www.descartes.com/solutions/transportation-management/tms'),
('descartes-transportation-manager','tms-shipment-execution','supported',0.970,'Descartes documents end-to-end transportation execution and carrier communication.','https://www.descartes.com/solutions/transportation-management/tms'),
('descartes-transportation-manager','tms-shipment-visibility','supported',0.990,'Descartes documents real-time shipment visibility, status and exception management.','https://www.descartes.com/resources/knowledge-center/faq-tms-and-visibility'),
('descartes-transportation-manager','tms-freight-cost','supported',0.980,'Descartes documents freight audit and settlement plus cost analytics.','https://www.descartes.com/solutions/transportation-management/tms'),
-- Manhattan Active Transportation Management
('manhattan-active-transportation-management','tms-planning-routing','supported',0.990,'Manhattan positions Active Transportation Management as unifying transportation planning with adaptive execution.','https://www.manh.com/solutions/supply-chain-management-software/transportation-management'),
('manhattan-active-transportation-management','tms-shipment-execution','supported',0.990,'Manhattan explicitly documents transportation execution as part of the unified TMS.','https://www.manh.com/solutions/supply-chain-management-software/transportation-management'),
('manhattan-active-transportation-management','tms-shipment-visibility','supported',0.990,'Manhattan explicitly documents transportation visibility as part of the unified TMS.','https://www.manh.com/solutions/supply-chain-management-software/transportation-management'),
('manhattan-active-transportation-management','tms-freight-cost','supported',0.980,'Manhattan explicitly documents settlement as part of the unified TMS.','https://www.manh.com/solutions/supply-chain-management-software/transportation-management');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score,limitations,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.confidence,f.limitations,NOW()
FROM cat95_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score),limitations=VALUES(limitations),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat95_products x JOIN products p ON p.slug=x.product_slug
JOIN modules m ON m.category_id=@tms_cat JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party source supporting this capability.'
FROM cat95_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Products added/promoted after the mobile-access foundation receive explicit unknown rows rather than inferred availability.
INSERT INTO product_mobile_access(product_id,platform,support_status,scope,evidence_url,last_verified_at)
SELECT p.id,plat.platform,'not_yet_verified','Mobile access has not yet been verified from product-specific first-party evidence.',NULL,NULL
FROM products p
JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') plat
WHERE p.slug IN('sap-transportation-management','oracle-transportation-management','blue-yonder-transportation-management','descartes-transportation-manager','manhattan-active-transportation-management')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope=VALUES(scope);

COMMIT;