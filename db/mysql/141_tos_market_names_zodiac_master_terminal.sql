-- TechSelectAI TOS market-name and coverage correction.
-- Adds current/legacy market-name aliases, restores the Navis brand to N4,
-- and adds CARGOES TOS+ (Zodiac) plus Navis Mixed Cargo TOS (Master Terminal/Jade).
-- Current first-party evidence reviewed Sep 2026.
-- Unknown != Unsupported. Optional suite modules remain partial where entitlement/scope is not universal.
-- No Fit Score, recommendation ranking, review weighting, popularity or commercial placement logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

SET @tos_cat=(SELECT id FROM categories WHERE slug='terminal-operating-systems' LIMIT 1);

CREATE TABLE IF NOT EXISTS product_aliases(
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id BIGINT UNSIGNED NOT NULL,
  alias_name VARCHAR(190) NOT NULL,
  normalized_alias VARCHAR(190) NOT NULL,
  source VARCHAR(40) NOT NULL DEFAULT 'admin',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_product_alias(product_id,normalized_alias),
  KEY idx_product_alias_lookup(normalized_alias),
  FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

UPDATE products
SET name='Navis N4 TOS',
    short_description='Navis N4 terminal operating system from Kaleris for complex container terminals, covering planning, execution, automation integration, optimization, operational visibility and enterprise terminal workflows.',
    last_reviewed_at=NOW()
WHERE slug='kaleris-n4-tos';

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('DP World','dp-world','https://www.dpworld.com/','Global ports, terminals and logistics operator and developer of the CARGOES digital solutions portfolio.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,@tos_cat,'CARGOES TOS+ (Zodiac)','cargoes-tos-plus-zodiac',
       'DP World-developed terminal operations suite, historically known as Zodiac, with OPS and optional suite modules spanning billing, auto gate, yard and equipment optimization, automation, RTLS and operational analytics.',
       'https://www.dpworld.com/en/digital-solutions/cargoes/terminal-operating-system','active',NOW()
FROM vendors v WHERE v.slug='dp-world'
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,@tos_cat,'Navis Mixed Cargo TOS','navis-mixed-cargo-tos',
       'Kaleris Navis mixed-cargo terminal operating system, formerly MTN / Master Terminal, for terminals handling containers, bulk, break-bulk, RoRo, vehicles and other mixed cargo.',
       'https://kaleris.com/what-is-a-terminal-operating-system/','active',NOW()
FROM vendors v WHERE v.slug='kaleris'
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS cat141_aliases;
CREATE TEMPORARY TABLE cat141_aliases(product_slug VARCHAR(190),alias_name VARCHAR(190),source VARCHAR(40));
INSERT INTO cat141_aliases VALUES
('kaleris-n4-tos','N4','short_name'),
('kaleris-n4-tos','N4 TOS','market_name'),
('kaleris-n4-tos','Navis N4','market_name'),
('kaleris-n4-tos','Kaleris N4','current_owner_name'),
('kaleris-n4-tos','Kaleris N4 TOS','former_catalog_name'),
('cargoes-tos-plus-zodiac','Zodiac','legacy_brand'),
('cargoes-tos-plus-zodiac','Zodiac TOS','legacy_brand'),
('cargoes-tos-plus-zodiac','DP World Zodiac','legacy_brand'),
('cargoes-tos-plus-zodiac','CARGOES TOS+','market_name'),
('cargoes-tos-plus-zodiac','Cargoes TOS Plus','search_name'),
('cargoes-tos-plus-zodiac','CARGOES P&T','portfolio_name'),
('navis-mixed-cargo-tos','Jade','legacy_brand'),
('navis-mixed-cargo-tos','Jade Master Terminal','legacy_brand'),
('navis-mixed-cargo-tos','Jade Logistics Master Terminal','legacy_brand'),
('navis-mixed-cargo-tos','Master Terminal','former_name'),
('navis-mixed-cargo-tos','Master Terminal by Navis','former_name'),
('navis-mixed-cargo-tos','MTN','former_name'),
('navis-mixed-cargo-tos','Navis Master Terminal','search_name');

INSERT INTO product_aliases(product_id,alias_name,normalized_alias,source)
SELECT p.id,a.alias_name,LOWER(TRIM(a.alias_name)),a.source
FROM cat141_aliases a JOIN products p ON p.slug=a.product_slug
ON DUPLICATE KEY UPDATE alias_name=VALUES(alias_name),source=VALUES(source);

DROP TEMPORARY TABLE IF EXISTS cat141_sources;
CREATE TEMPORARY TABLE cat141_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190),vendor_owned TINYINT(1));
INSERT INTO cat141_sources VALUES
('cargoes-tos-plus-zodiac','https://www.dpworld.com/en/digital-solutions','DP World Digital Solutions - CARGOES TOS+ (Zodiac)','DP World',1),
('cargoes-tos-plus-zodiac','https://www.dpworld.com/en/digital-solutions/cargoes/terminal-operating-system','DP World CARGOES P&T / CARGOES TOS+','DP World',1),
('cargoes-tos-plus-zodiac','https://www.dpworld.com/en/news/jeddah-port-ushers-in-new-operational-efficiency-with-cargoes-tos','Jeddah Port launches CARGOES TOS+ OPS','DP World',1),
('navis-mixed-cargo-tos','https://kaleris.com/login/','Kaleris Platform Access - Navis Mixed Cargo TOS','Kaleris',1),
('navis-mixed-cargo-tos','https://kaleris.com/what-is-a-terminal-operating-system/','Kaleris Terminal Operating Systems - Master Terminal / Mixed Cargo','Kaleris',1);

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,s.vendor_owned,'verified','high',NOW()
FROM cat141_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(
  SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url
);

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM products p
JOIN modules m ON m.category_id=@tos_cat AND m.is_active=1
JOIN capabilities cap ON cap.module_id=m.id AND cap.is_active=1
WHERE p.slug IN('cargoes-tos-plus-zodiac','navis-mixed-cargo-tos')
  AND NOT EXISTS(
    SELECT 1 FROM product_capabilities pc
    WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL
  );

DROP TEMPORARY TABLE IF EXISTS cat141_facts;
CREATE TEMPORARY TABLE cat141_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat141_facts VALUES
('cargoes-tos-plus-zodiac','tos-yard-planning-inventory','partially_supported',0.980,'DP World documents Smart Housekeeping and Smart Yard Crane Scheduler within the broader CARGOES TOS+ suite; these named components are not assumed in every OPS configuration.','https://www.dpworld.com/en/digital-solutions/cargoes/terminal-operating-system'),
('cargoes-tos-plus-zodiac','tos-gate-truck-operations','partially_supported',0.970,'DP World lists AGS Auto Gate System within the CARGOES TOS+ suite; exact gate functions and lane-device scope depend on the selected suite configuration.','https://www.dpworld.com/en/digital-solutions/cargoes/terminal-operating-system'),
('cargoes-tos-plus-zodiac','tos-equipment-dispatch-control','partially_supported',0.980,'Smart Dispatcher and Smart Yard Crane Scheduler provide dispatch and equipment-planning functions as named CARGOES TOS+ suite components rather than universal core-OPS entitlement.','https://www.dpworld.com/en/digital-solutions/cargoes/terminal-operating-system'),
('cargoes-tos-plus-zodiac','tos-automation-ecs','supported',0.990,'DP World explicitly documents integration with real-time systems and terminal automation, including RTLS, ARMG/ASC automation and STS automation integrations.','https://www.dpworld.com/en/digital-solutions/cargoes/terminal-operating-system'),
('cargoes-tos-plus-zodiac','tos-edi-api-integrations','partially_supported',0.940,'DP World documents a robust integration environment for equipment automation and RTLS, but the reviewed public evidence does not enumerate a universal EDI/API catalogue.','https://www.dpworld.com/en/news/jeddah-port-ushers-in-new-operational-efficiency-with-cargoes-tos'),
('cargoes-tos-plus-zodiac','tos-kpi-visibility','partially_supported',0.970,'RTLS and FMS modules are documented with BI data analytics and OEE model support; module entitlement is not assumed in every TOS+ deployment.','https://www.dpworld.com/en/digital-solutions/cargoes/terminal-operating-system'),
('cargoes-tos-plus-zodiac','tos-billing-financial','partially_supported',0.960,'The CARGOES TOS+ PLUS portfolio lists Billing with user-defined quick invoicing; detailed tariff and finance integration scope is not inferred.','https://www.dpworld.com/en/digital-solutions/cargoes/terminal-operating-system'),
('cargoes-tos-plus-zodiac','tos-housekeeping-remarshalling','partially_supported',0.970,'Smart Housekeeping is a named CARGOES TOS+ component for efficient yard-container management; it is not assumed as universal base OPS functionality.','https://www.dpworld.com/en/digital-solutions/cargoes/terminal-operating-system'),
('cargoes-tos-plus-zodiac','tos-gate-lane-automation','partially_supported',0.970,'AGS is explicitly described as an Auto Gate System in the CARGOES TOS+ suite; selected hardware and lane orchestration scope are implementation-dependent.','https://www.dpworld.com/en/digital-solutions/cargoes/terminal-operating-system'),
('cargoes-tos-plus-zodiac','tos-rtg-rmg-dispatch','partially_supported',0.960,'Smart Yard Crane Scheduler provides auto yard planning and dynamic CHE zoning, but the public material does not establish identical RTG/RMG dispatch depth for every implementation.','https://www.dpworld.com/en/digital-solutions/cargoes/terminal-operating-system'),
('cargoes-tos-plus-zodiac','tos-tt-straddle-dispatch','partially_supported',0.960,'Smart Dispatcher explicitly includes tractor pooling and travel-distance setup; straddle-carrier support is not inferred from tractor evidence.','https://www.dpworld.com/en/digital-solutions/cargoes/terminal-operating-system'),
('cargoes-tos-plus-zodiac','tos-agv-asc-automation','partially_supported',0.970,'Yard Crane Automation explicitly integrates ARMG and ASC automation systems; AGV support is not inferred where it is not stated.','https://www.dpworld.com/en/digital-solutions/cargoes/terminal-operating-system'),
('cargoes-tos-plus-zodiac','tos-equipment-position-tracking','partially_supported',0.970,'RTLS is a named TOS+ component integrated with the TOS; exact positioning technologies and entitlement depend on implementation.','https://www.dpworld.com/en/digital-solutions/cargoes/terminal-operating-system'),
('cargoes-tos-plus-zodiac','tos-storage-tariff-billing','partially_supported',0.950,'Billing and quick invoicing are explicit, but public evidence does not establish full storage, tariff and event-rating depth.','https://www.dpworld.com/en/digital-solutions/cargoes/terminal-operating-system'),
('cargoes-tos-plus-zodiac','tos-productivity-kpis','partially_supported',0.960,'CARGOES TOS+ RTLS/FMS modules document BI data analytics and OEE model support; broader KPI coverage is not generalized.','https://www.dpworld.com/en/digital-solutions/cargoes/terminal-operating-system'),
('cargoes-tos-plus-zodiac','tos-cloud-onprem-flexibility','supported',0.990,'DP World explicitly states Cargoes P&T can be hosted on-site premises or in the cloud. This does not by itself classify the cloud option as public SaaS.','https://www.dpworld.com/en/digital-solutions/cargoes/terminal-operating-system'),
('cargoes-tos-plus-zodiac','tos-scalability-throughput','supported',0.990,'DP World states the OPS planning and operations module is proven at marine terminals exceeding 10 million TEU per year.','https://www.dpworld.com/en/digital-solutions/cargoes/terminal-operating-system'),
('navis-mixed-cargo-tos','tos-yard-planning-inventory','supported',0.980,'Kaleris documents real-time cargo movements, inventory visibility and improved yard utilization for Master Terminal / Navis Mixed Cargo TOS.','https://kaleris.com/what-is-a-terminal-operating-system/'),
('navis-mixed-cargo-tos','tos-edi-api-integrations','supported',0.980,'Kaleris documents robust EDI integration for all major container-cargo EDI plus definable file formats for mixed cargo; API support is not separately inferred.','https://kaleris.com/what-is-a-terminal-operating-system/'),
('navis-mixed-cargo-tos','tos-kpi-visibility','supported',0.970,'Kaleris documents real-time cargo visibility and a digital interface for inventory and yard-utilization visibility.','https://kaleris.com/what-is-a-terminal-operating-system/'),
('navis-mixed-cargo-tos','tos-billing-financial','supported',0.990,'Kaleris documents capture of billable events, contracts and invoices with built-in billing options for Master Terminal.','https://kaleris.com/what-is-a-terminal-operating-system/'),
('navis-mixed-cargo-tos','tos-storage-tariff-billing','supported',0.980,'Kaleris documents granular billable events and built-in billing/invoice handling, including value-added tasks; exact local tariff models remain implementation-dependent.','https://kaleris.com/what-is-a-terminal-operating-system/'),
('navis-mixed-cargo-tos','tos-customer-self-service','partially_supported',0.950,'Kaleris documents an integrated web portal, but the reviewed source does not enumerate every customer self-service transaction available in all deployments.','https://kaleris.com/what-is-a-terminal-operating-system/'),
('navis-mixed-cargo-tos','tos-special-cargo-controls','partially_supported',0.940,'Kaleris positions Master Terminal for containers, break-bulk, bulk, general cargo, RoRo, vehicles and logs; full reefer, dangerous-goods and OOG control is not inferred from cargo-type coverage alone.','https://kaleris.com/what-is-a-terminal-operating-system/');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat141_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE
  support_status=VALUES(support_status),
  limitations=VALUES(limitations),
  confidence_score=VALUES(confidence_score),
  last_verified_at=NOW();

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party source supporting this TOS market-coverage capability status and scope boundary.'
FROM cat141_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.990
FROM products p JOIN deployment_models d ON d.slug='on-premise'
WHERE p.slug='cargoes-tos-plus-zodiac'
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000
FROM products p CROSS JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') x
WHERE p.slug IN('cargoes-tos-plus-zodiac','navis-mixed-cargo-tos')
ON DUPLICATE KEY UPDATE product_id=VALUES(product_id);

COMMIT;
