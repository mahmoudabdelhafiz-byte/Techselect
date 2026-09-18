-- TechSelectAI Dangerous Goods / Hazmat Compliance Software catalog expansion.
-- Adds one canonical specialized dangerous-goods category and five evidence-backed current products.
-- Official first-party evidence reviewed Sep 2026. Presence is not an endorsement.
-- Unknown != Unsupported. Suite modules/add-ons remain partial when they are not universal entitlement.
-- No Fit Score, recommendation ranking, review score, follower/community popularity or commercial placement logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('Dangerous Goods / Hazmat Compliance Software','dangerous-goods-hazmat-compliance','Specialized software for dangerous-goods and hazardous-material transport compliance across maritime, air, road and rail workflows, including regulatory validation, classification, packaging and labeling, segregation, declarations, regulatory-content maintenance, chemical transport data and enterprise logistics integration.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @dg_cat=(SELECT id FROM categories WHERE slug='dangerous-goods-hazmat-compliance' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@dg_cat,'Regulatory Classification & Shipment Validation','dg-regulatory-validation','Mode-specific dangerous-goods regulatory checks, classification, packaging/labeling and segregation/stowage validation.',1),
(@dg_cat,'Documentation, Operations & Integration','dg-documentation-operations','Dangerous-goods documents, SDS/transport data, regulatory maintenance, multimodal operations, terminal workflows and enterprise integration.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

-- Migration 087 predates this category. Create the category-scoped mobile criteria here
-- so canonical product_mobile_access facts remain buyer-selectable from day one.
INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@dg_cat,'Mobile Access','mobile-access','Buyer-selectable mobile access requirements. Availability is evidence-based; unknown is not unsupported.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @dg_mobile_module=(SELECT id FROM modules WHERE category_id=@dg_cat AND slug='mobile-access' LIMIT 1);

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active) VALUES
(@dg_mobile_module,'Android mobile application','dangerous-goods-hazmat-compliance-mobile-android-app','A vendor-supported Android application is available for the software.',0,1),
(@dg_mobile_module,'iOS mobile application','dangerous-goods-hazmat-compliance-mobile-ios-app','A vendor-supported iOS application is available for the software.',0,1),
(@dg_mobile_module,'Mobile web access','dangerous-goods-hazmat-compliance-mobile-web-access','The software provides vendor-supported mobile web or responsive browser access.',0,1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.sec,1
FROM modules m JOIN (
 SELECT 'dg-regulatory-validation' module_slug,'IMDG maritime dangerous-goods validation' name,'dg-imdg-validation' slug,'Validate dangerous-goods data, shipment rules or transport requirements against the International Maritime Dangerous Goods Code where explicitly supported.' description,0 sec UNION ALL
 SELECT 'dg-regulatory-validation','IATA / ICAO air dangerous-goods compliance','dg-iata-icao-compliance','Apply IATA Dangerous Goods Regulations or ICAO Technical Instructions to dangerous-goods classification, shipment preparation, declarations or validation where explicitly supported.' description,0 UNION ALL
 SELECT 'dg-regulatory-validation','ADR / RID road and rail dangerous-goods compliance','dg-adr-rid-compliance','Apply ADR road and RID rail dangerous-goods requirements, including declarations, classifications or shipment rules where explicitly supported.',0 UNION ALL
 SELECT 'dg-regulatory-validation','UN number, proper shipping name & transport classification','dg-un-classification','Search, classify or validate dangerous goods using UN/NA identifiers, proper shipping names, hazard classes, packing groups or equivalent transport-classification data.',0 UNION ALL
 SELECT 'dg-regulatory-validation','Packaging, quantity, marks, labels & placards','dg-packaging-labeling','Validate or guide packaging instructions, quantity limits, package marks, transport labels or placards for applicable dangerous-goods shipments.',0 UNION ALL
 SELECT 'dg-regulatory-validation','Segregation, compatibility & stowage validation','dg-segregation-stowage','Check dangerous-goods compatibility, segregation, stowage, mixed-load, CTU, vessel or related placement restrictions where explicitly supported.',0 UNION ALL
 SELECT 'dg-documentation-operations','Dangerous-goods declarations, shipping papers & manifests','dg-documents-manifests','Create, validate, store or exchange dangerous-goods declarations, transport documents, bills of lading, manifests, NOTOC or equivalent regulated shipping records.',0 UNION ALL
 SELECT 'dg-documentation-operations','SDS & Section 14 transport information','dg-sds-section14','Create, manage or use safety data sheets and Section 14 transport information as part of dangerous-goods or chemical-compliance workflows.',0 UNION ALL
 SELECT 'dg-documentation-operations','Maintained regulatory content & amendment updates','dg-regulatory-updates','Provide maintained dangerous-goods regulatory content, rules, amendments or updates so compliance logic can track current requirements.',0 UNION ALL
 SELECT 'dg-documentation-operations','Multimodal dangerous-goods shipment compliance','dg-multimodal-compliance','Support dangerous-goods workflows spanning multiple transport modes while preserving mode-specific regulatory requirements and handoffs.',0 UNION ALL
 SELECT 'dg-documentation-operations','Port, terminal, carrier & handler dangerous-goods workflows','dg-terminal-port-workflows','Support operational dangerous-goods workflows for carriers, ports, terminals or cargo handlers such as acceptance, CTU/load validation, restrictions, manifests or loading preparation.',0 UNION ALL
 SELECT 'dg-documentation-operations','ERP, TMS, WMS, booking, API & EDI integration','dg-enterprise-integration','Integrate dangerous-goods data, validation or documents with ERP, TMS, WMS, booking, cargo-community or other enterprise/logistics platforms through APIs, EDI, web services or supported data interfaces.',0
) x ON x.module_slug=m.slug
WHERE m.category_id=@dg_cat
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('NCB Hazcheck','ncb-hazcheck','https://hazcheck.com/','Dangerous-cargo validation, IMDG compliance, regulatory data and cargo-screening software provider.','active'),
('Labelmaster','labelmaster','https://www.labelmaster.com/','Dangerous-goods compliance products, software, training and regulatory-content provider.','active'),
('DGM-SDG','dgm-sdg','https://dgm-sdg.com/','Dangerous-goods transport, chemical-management, regulatory-data and integration software provider.','active'),
('Lisam','lisam','https://www.lisam.com/','EHS, SDS, chemical product-stewardship and regulatory-compliance software provider.','active'),
('Bureau of Dangerous Goods','bureau-dangerous-goods','https://www.shiphazmat.net/','Dangerous-goods training, consulting and web-based hazmat shipping software provider.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat138_products;
CREATE TEMPORARY TABLE cat138_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO cat138_products VALUES
('ncb-hazcheck','dangerous-goods-hazmat-compliance','Hazcheck Validate','hazcheck-validate','SaaS dangerous-cargo compliance and validation platform centered on IMDG validation with intermodal ADR/49 CFR checks, segregation and packaging checks, dangerous-goods documents, configurable restrictions and edition-dependent API/EDI integration.','https://hazcheck.com/product/hazcheck-validate/'),
('labelmaster','dangerous-goods-hazmat-compliance','Labelmaster DGIS','labelmaster-dgis','Hosted Dangerous Goods Information System for shipment validation and documentation against 49 CFR, IATA DGR and IMDG requirements, with packaging/marking guidance and enterprise logistics integration.','https://www.dgis.com/App/About.aspx'),
('dgm-sdg','dangerous-goods-hazmat-compliance','DGOffice.net','dgoffice-net','Modular online dangerous-goods and chemical-management software covering road, sea, air, rail and inland-waterway regulations, declarations, labels, handler workflows, SDS modules and integration services according to licensed modules.','https://dgm-sdg.com/solutions/software/'),
('lisam','dangerous-goods-hazmat-compliance','Lisam ExESS','lisam-exess','Product-stewardship and SDS authoring platform with transport classification, transport labeling, regulatory content, audit trails and chemical-data integration; it is not modeled as a full shipment segregation or terminal-operations system.','https://www.lisam.com/sds-software/'),
('bureau-dangerous-goods','dangerous-goods-hazmat-compliance','ShipHazmat','shiphazmat','Web-based dangerous-goods shipping compliance tool for air, ground and ocean documentation, regulatory logic, packaging/marking guidance, current regulatory content and shipment recordkeeping.','https://www.shiphazmat.net/');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat138_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS cat138_sources;
CREATE TEMPORARY TABLE cat138_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat138_sources VALUES
('hazcheck-validate','https://hazcheck.com/product/hazcheck-validate/','Hazcheck Validate','NCB Hazcheck'),
('hazcheck-validate','https://hazcheck.com/hazcheck-validate-features/','Hazcheck Validate Feature Comparison','NCB Hazcheck'),
('labelmaster-dgis','https://www.dgis.com/App/About.aspx','DGIS About and Current Version','Labelmaster'),
('labelmaster-dgis','https://www.dgis.com/app/eula.aspx?key=&target=RegStick','DGIS Hosted Service License','Labelmaster'),
('labelmaster-dgis','https://blog.labelmaster.com/prescription-for-dangerous-goods-anxiety-use-dgis-hazmat-software-regularly/','DGIS Dangerous Goods Compliance Capabilities','Labelmaster'),
('dgoffice-net','https://dgm-sdg.com/solutions/software/','DGOffice.net Software Modules','DGM-SDG'),
('dgoffice-net','https://dgm-sdg.com/solutions/databases/','DGOffice Dangerous Goods Databases','DGM-SDG'),
('dgoffice-net','https://dgm-sdg.com/industries/handler/','DGOffice Ground and Terminal Handler Workflows','DGM-SDG'),
('dgoffice-net','https://dgm-sdg.com/solutions/integrated-solutions/','DGOffice Integrated Solutions','DGM-SDG'),
('dgoffice-net','https://dgm-sdg.com/license-plans/','DGOffice License Plans','DGM-SDG'),
('lisam-exess','https://www.lisam.com/sds-software/','Lisam ExESS SDS Software','Lisam'),
('lisam-exess','https://www.lisam.com/document/ghs-compliant-chemical-labels/','ExESS Chemical and Transport Labels','Lisam'),
('lisam-exess','https://www.lisam.com/sds-authoring-distribution/','ExESS SDS Authoring, Deployment and Integration','Lisam'),
('shiphazmat','https://www.shiphazmat.net/','ShipHazmat Dangerous Goods Shipping Software','Bureau of Dangerous Goods'),
('shiphazmat','https://www.shiphazmat.net/Public/Tour/RegulatoryLogic.aspx','ShipHazmat Regulatory Logic','Bureau of Dangerous Goods'),
('shiphazmat','https://www.shiphazmat.net/Public/Tour/FeaturesBenefits.aspx','ShipHazmat Features and Benefits','Bureau of Dangerous Goods'),
('shiphazmat','https://www.shiphazmat.net/Public/Tour/Documentation.aspx','ShipHazmat Documentation','Bureau of Dangerous Goods'),
('shiphazmat','https://www.shiphazmat.net/Public/Plans/Pricing.aspx','ShipHazmat Subscription Plans','Bureau of Dangerous Goods'),
('shiphazmat','https://blog.shiphazmat.net/lithium-batteries-and-servers-why-data-centers-need-hazmat-compliance/','ShipHazmat 49 CFR IATA IMDG Compliance and Recordkeeping','Bureau of Dangerous Goods');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM cat138_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS cat138_facts;
CREATE TEMPORARY TABLE cat138_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat138_facts VALUES
-- Hazcheck Validate: core Validate vs Pro/Enterprise boundaries are kept explicit.
('hazcheck-validate','dg-imdg-validation','supported',0.990,'Hazcheck Validate explicitly validates dangerous-goods shipments against IMDG Code provisions.','https://hazcheck.com/product/hazcheck-validate/'),
('hazcheck-validate','dg-adr-rid-compliance','partially_supported',0.980,'ADR requirements are explicitly supported for intermodal journeys, while current reviewed evidence does not verify RID as an active Hazcheck Validate entitlement.','https://hazcheck.com/product/hazcheck-validate/'),
('hazcheck-validate','dg-un-classification','supported',0.990,'Dangerous Goods Search covers entries in the IMDG Dangerous Goods List, ADR Dangerous Goods List and 49 CFR 172.101 table with linked packing and special-provision details.','https://hazcheck.com/product/hazcheck-validate/'),
('hazcheck-validate','dg-packaging-labeling','partially_supported',0.990,'Validate includes packaging checks, but this catalog does not infer a complete marks/labels/placards workflow from packaging checks alone.','https://hazcheck.com/hazcheck-validate-features/'),
('hazcheck-validate','dg-segregation-stowage','supported',0.990,'The Validate tier explicitly includes stowage and segregation checks plus CTU/load validation reporting.','https://hazcheck.com/hazcheck-validate-features/'),
('hazcheck-validate','dg-documents-manifests','supported',0.990,'Validate generates dangerous-goods notes/transport documentation and manifest reports.','https://hazcheck.com/hazcheck-validate-features/'),
('hazcheck-validate','dg-regulatory-updates','supported',0.990,'Hazcheck documents regularly updated regulations maintained by dangerous-goods experts.','https://hazcheck.com/product/hazcheck-validate/'),
('hazcheck-validate','dg-multimodal-compliance','partially_supported',0.990,'Current evidence supports combined IMDG, 49 CFR and ADR intermodal checks; air IATA/ICAO and RID support are not inferred.','https://hazcheck.com/product/hazcheck-validate/'),
('hazcheck-validate','dg-terminal-port-workflows','partially_supported',0.980,'Hazcheck is designed for port operators and supports CTU/load validation plus company, port and vessel restrictions, but a full terminal operating workflow is not inferred.','https://hazcheck.com/product/hazcheck-validate/'),
('hazcheck-validate','dg-enterprise-integration','partially_supported',0.990,'EDI is available from Validate Pro and API connectivity from Validate Enterprise, so integration is edition-dependent rather than universal entitlement.','https://hazcheck.com/hazcheck-validate-features/'),

-- Labelmaster DGIS.
('labelmaster-dgis','dg-imdg-validation','supported',0.980,'Labelmaster states DGIS validates shipments against the latest IMDG Code requirements.','https://blog.labelmaster.com/prescription-for-dangerous-goods-anxiety-use-dgis-hazmat-software-regularly/'),
('labelmaster-dgis','dg-iata-icao-compliance','supported',0.980,'Labelmaster states DGIS validates shipments against IATA DGR requirements.','https://blog.labelmaster.com/prescription-for-dangerous-goods-anxiety-use-dgis-hazmat-software-regularly/'),
('labelmaster-dgis','dg-packaging-labeling','supported',0.980,'DGIS provides packaging compliance guidance and shows where required labels and marks should be placed.','https://blog.labelmaster.com/prescription-for-dangerous-goods-anxiety-use-dgis-hazmat-software-regularly/'),
('labelmaster-dgis','dg-documents-manifests','supported',0.980,'DGIS stores shipment data and pre-populates dangerous-goods declaration fields for compliant documentation.','https://blog.labelmaster.com/prescription-for-dangerous-goods-anxiety-use-dgis-hazmat-software-regularly/'),
('labelmaster-dgis','dg-regulatory-updates','supported',0.980,'DGIS validation is described against the latest 49 CFR, IATA DGR and IMDG Code regulations.','https://blog.labelmaster.com/prescription-for-dangerous-goods-anxiety-use-dgis-hazmat-software-regularly/'),
('labelmaster-dgis','dg-multimodal-compliance','partially_supported',0.970,'Current reviewed evidence verifies 49 CFR, IATA DGR and IMDG coverage; ADR/RID coverage is not inferred.','https://blog.labelmaster.com/prescription-for-dangerous-goods-anxiety-use-dgis-hazmat-software-regularly/'),
('labelmaster-dgis','dg-enterprise-integration','supported',0.980,'Labelmaster documents DGIS integration with TMS, WMS and ERP platforms.','https://blog.labelmaster.com/prescription-for-dangerous-goods-anxiety-use-dgis-hazmat-software-regularly/'),

-- DGOffice.net: module/plan-dependent capabilities are partial where not universal entitlement.
('dgoffice-net','dg-imdg-validation','partially_supported',0.990,'The Sea module is based on the IMDG Code, but DGOffice licenses are modular and do not universally include every transport mode.','https://dgm-sdg.com/solutions/software/'),
('dgoffice-net','dg-iata-icao-compliance','partially_supported',0.990,'The Air module is based on ICAO/IATA, but transport modes are selected by license/module.','https://dgm-sdg.com/solutions/software/'),
('dgoffice-net','dg-adr-rid-compliance','partially_supported',0.990,'Road supports ADR and Rail supports RID, but the modules are licensed selectively rather than universally included.','https://dgm-sdg.com/solutions/software/'),
('dgoffice-net','dg-un-classification','supported',0.990,'DGOffice maintains dangerous-goods classification data and DGM identifiers linked to UN numbers and classification variants.','https://dgm-sdg.com/solutions/databases/'),
('dgoffice-net','dg-packaging-labeling','partially_supported',0.970,'DGOffice offers shipping-label functionality, but packaging validation depth and label entitlement vary by module/license and are not assumed universally.','https://dgm-sdg.com/license-plans/'),
('dgoffice-net','dg-segregation-stowage','partially_supported',0.970,'Handler workflows include validated and segregated declarations; universal vessel/CTU stowage behavior across all licenses is not inferred.','https://dgm-sdg.com/industries/handler/'),
('dgoffice-net','dg-documents-manifests','partially_supported',0.990,'Mode modules create shipper declarations and handler workflows include manifests/NOTOC, with entitlement dependent on selected modules.','https://dgm-sdg.com/industries/handler/'),
('dgoffice-net','dg-sds-section14','partially_supported',0.990,'SDS Basic and SDS Editor are separate chemical-management modules/add-ons, not universal transport-software entitlement.','https://dgm-sdg.com/solutions/software/'),
('dgoffice-net','dg-regulatory-updates','supported',0.990,'DGOffice provides access to current regulatory information and maintained dangerous-goods datasets with amendments/updates.','https://dgm-sdg.com/solutions/databases/'),
('dgoffice-net','dg-multimodal-compliance','partially_supported',0.990,'DGOffice offers road, sea, air, rail and inland-waterway modules, but plans license a selected number of modes rather than universally including all modes.','https://dgm-sdg.com/license-plans/'),
('dgoffice-net','dg-terminal-port-workflows','partially_supported',0.980,'DGOffice documents ground/terminal handler workflows for pre-arrival data, acceptance, manifests, validated declarations and loading preparation; required modules may vary.','https://dgm-sdg.com/industries/handler/'),
('dgoffice-net','dg-enterprise-integration','partially_supported',0.990,'Web services and integrated solutions are available, but plan tables show web-service/integration entitlement varies by package.','https://dgm-sdg.com/license-plans/'),

-- Lisam ExESS: transport classification is not treated as full shipment-execution software.
('lisam-exess','dg-imdg-validation','partially_supported',0.970,'ExESS supports IMDG transport classification labels and Section 14 transport data, but full IMDG shipment validation is not inferred.','https://www.lisam.com/document/ghs-compliant-chemical-labels/'),
('lisam-exess','dg-iata-icao-compliance','partially_supported',0.970,'ExESS supports IATA transport classification labels, but full air-shipment declaration/acceptance validation is not inferred.','https://www.lisam.com/document/ghs-compliant-chemical-labels/'),
('lisam-exess','dg-adr-rid-compliance','partially_supported',0.960,'ADR transport labeling is explicit; current reviewed evidence does not verify equivalent RID shipment functionality.','https://www.lisam.com/document/ghs-compliant-chemical-labels/'),
('lisam-exess','dg-un-classification','partially_supported',0.950,'ExESS calculates transport classification in SDS Section 14, but a dedicated shipment-level UN lookup/validation workflow is not inferred.','https://www.lisam.com/sds-software/'),
('lisam-exess','dg-packaging-labeling','partially_supported',0.970,'ExESS generates transport labels for ADR, IATA and IMDG; full dangerous-goods packaging validation is not inferred.','https://www.lisam.com/document/ghs-compliant-chemical-labels/'),
('lisam-exess','dg-sds-section14','supported',0.990,'ExESS is an SDS authoring platform with explicit transportation classification in Section 14.','https://www.lisam.com/sds-software/'),
('lisam-exess','dg-regulatory-updates','supported',0.980,'Lisam documents integrated regulatory content with daily updates.','https://www.lisam.com/sds-authoring-distribution/'),
('lisam-exess','dg-multimodal-compliance','partially_supported',0.960,'ExESS supports transport classification/labels across ADR, IATA and IMDG, but is not treated as a multimodal shipment-execution engine.','https://www.lisam.com/document/ghs-compliant-chemical-labels/'),
('lisam-exess','dg-enterprise-integration','supported',0.970,'Lisam documents batch and real-time data integration across company platforms.','https://www.lisam.com/sds-authoring-distribution/'),

-- ShipHazmat.
('shiphazmat','dg-imdg-validation','supported',0.980,'ShipHazmat applies current IMDG requirements to ocean/vessel dangerous-goods shipping documents and compliance logic.','https://blog.shiphazmat.net/lithium-batteries-and-servers-why-data-centers-need-hazmat-compliance/'),
('shiphazmat','dg-iata-icao-compliance','supported',0.990,'ShipHazmat creates IATA dangerous-goods declarations and applies current air-transport regulatory logic.','https://www.shiphazmat.net/Public/Tour/Documentation.aspx'),
('shiphazmat','dg-un-classification','supported',0.970,'Current ShipHazmat guidance describes built-in hazard-class selection using UN numbers, proper shipping names and packing groups.','https://blog.shiphazmat.net/lithium-batteries-and-servers-why-data-centers-need-hazmat-compliance/'),
('shiphazmat','dg-packaging-labeling','supported',0.990,'ShipHazmat provides packaging diagrams, marking/labeling guidance and placarding information based on applicable shipment rules.','https://www.shiphazmat.net/Public/Tour/FeaturesBenefits.aspx'),
('shiphazmat','dg-documents-manifests','supported',0.990,'ShipHazmat creates compliant shipping papers including 49 CFR bills of lading and IATA Shipper declarations; ocean documentation is also supported.','https://www.shiphazmat.net/Public/Tour/Documentation.aspx'),
('shiphazmat','dg-regulatory-updates','supported',0.990,'The web service is maintained with current regulatory guidelines and requires no customer software updates.','https://www.shiphazmat.net/Public/Tour/FeaturesBenefits.aspx'),
('shiphazmat','dg-multimodal-compliance','partially_supported',0.980,'Air, US ground and ocean workflows are explicit; ADR/RID support is not inferred from current reviewed evidence.','https://www.shiphazmat.net/'),
('shiphazmat','dg-sds-section14','not_yet_verified',0.000,'Current reviewed first-party evidence does not establish SDS authoring or Section 14 management as a ShipHazmat capability.','https://www.shiphazmat.net/');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat138_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

-- Every remaining category capability is explicitly unknown rather than unsupported.
INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat138_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party vendor documentation supporting this capability status or scope boundary.'
FROM cat138_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Deployment mappings are conservative. Generic cloud availability is not automatically public SaaS.
INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.990
FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug='hazcheck-validate'
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.980
FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug='labelmaster-dgis'
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.990
FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug='shiphazmat'
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.990
FROM products p JOIN deployment_models d ON d.slug='on-premise'
WHERE p.slug='lisam-exess'
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

-- DGOffice.net is described as online software with optional local synchronization/hybrid setup,
-- and ExESS supports cloud access, but those statements are not collapsed into this catalog's
-- generic public-SaaS label without clearer product-level commercial/deployment evidence.

-- Seed mobile access without overwriting facts that may be curated later.
INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000
FROM products p CROSS JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') x
WHERE p.slug IN('hazcheck-validate','labelmaster-dgis','dgoffice-net','lisam-exess','shiphazmat')
ON DUPLICATE KEY UPDATE product_id=VALUES(product_id);

-- ShipHazmat explicitly documents responsive use from tablets and other smart devices.
UPDATE product_mobile_access pma
JOIN products p ON p.id=pma.product_id
SET pma.support_status='supported',
    pma.scope_status='not_yet_verified',
    pma.scope_notes='Responsive browser use from tablets and other smart devices is explicitly documented; complete mobile feature parity is not separately verified.',
    pma.evidence_url='https://www.shiphazmat.net/Public/Plans/Pricing.aspx',
    pma.evidence_type='vendor_documentation',
    pma.confidence_score=0.980,
    pma.last_verified_at=NOW()
WHERE p.slug='shiphazmat' AND pma.platform='mobile_web';

COMMIT;
