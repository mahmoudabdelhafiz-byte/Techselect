-- TechSelectAI TOS Depth Program - Tideworks Mainsail evidence pass.
-- Reviews granular Mainsail criteria using current first-party Tideworks material.
-- Spinnaker, Traffic Control, GateVision, Forecast and EDI Porter remain explicit companion-product boundaries.
-- Responsive browser access is verified as mobile web; native Android/iOS applications are not inferred.
-- Every unlisted TOS criterion remains not_yet_verified. Unknown != Unsupported.
-- No Fit Score, recommendation ranking, review weighting, popularity or commercial placement logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

SET @mainsail=(SELECT id FROM products WHERE slug='tideworks-mainsail' LIMIT 1);

DROP TEMPORARY TABLE IF EXISTS cat145_sources;
CREATE TEMPORARY TABLE cat145_sources(url TEXT,title VARCHAR(255));
INSERT INTO cat145_sources VALUES
('https://tideworks.com/mainsail/','Tideworks Mainsail'),
('https://tideworks.com/mainsail-10-advanced-reporting-capabilities/','Mainsail 10 Advanced Reporting'),
('https://tideworks.com/industry-integration-third-party-systems-in-mainsail-10/','Mainsail 10 Third-Party Integrations'),
('https://tideworks.com/tideworks-technology-introduces-mainsail-10-and-announces-go-live-at-mit/','Mainsail 10 Launch and MIT Go-Live'),
('https://tideworks.com/customized-user-experience-in-mainsail-10/','Mainsail 10 Responsive Design'),
('https://tideworks.com/spinnaker/','Tideworks Spinnaker Planning Management System'),
('https://tideworks.com/traffic-control/','Tideworks Traffic Control'),
('https://tideworks.com/gate-vision/','Tideworks GateVision'),
('https://tideworks.com/forecast/','Forecast by Tideworks'),
('https://tideworks.com/pomtoc-modernizes-terminal-operations-with-cloud-based-tos-mainsail-10/','POMTOC Cloud-Based Mainsail 10'),
('https://tideworks.com/oregons-only-international-container-terminal-relaunches-with-tideworks-technology/','Oregon Container Terminal Tideworks SaaS Suite'),
('https://tideworks.com/video-library/','Tideworks Video Library - Mainsail Billing and Product Features');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT @mainsail,'vendor_documentation',s.url,s.title,'Tideworks Technology',1,'verified','high',NOW()
FROM cat145_sources s
WHERE @mainsail IS NOT NULL
  AND NOT EXISTS(
    SELECT 1 FROM evidence_sources e
    WHERE e.product_id=@mainsail AND e.source_url=s.url
  );

DROP TEMPORARY TABLE IF EXISTS cat145_facts;
CREATE TEMPORARY TABLE cat145_facts(
  capability_slug VARCHAR(190),
  support_status VARCHAR(40),
  confidence DECIMAL(4,3),
  limitations TEXT,
  source_url TEXT
);
INSERT INTO cat145_facts VALUES
('tos-vessel-call-management','supported',0.980,'Mainsail explicitly manages vessel activity as part of its core marine terminal operating system; detailed graphical vessel and berth planning remains a Spinnaker companion-product boundary.','https://tideworks.com/mainsail/'),
('tos-berth-window-scheduling','partially_supported',0.980,'Graphical berth planning is explicitly delivered through Spinnaker, a companion planning system integrated with Mainsail; it is not assumed as universal core-Mainsail entitlement.','https://tideworks.com/spinnaker/'),
('tos-stowage-bay-planning','partially_supported',0.990,'Spinnaker provides graphical vessel planning and stowage tools, including automated stowage functions; these are companion-product capabilities rather than universal core Mainsail functionality.','https://tideworks.com/spinnaker/'),
('tos-discharge-load-sequencing','partially_supported',0.990,'Spinnaker automatically sequences discharge containers and calculates efficient load-back sequences; this capability is attributed to the companion planning system, not base Mainsail.','https://tideworks.com/spinnaker/'),
('tos-quay-work-queues','partially_supported',0.960,'Spinnaker can create bay-by-bay worklists and electronic work orders for real-time dispatch, but work-order execution depends on the integrated planning/dispatch stack rather than base Mainsail alone.','https://tideworks.com/spinnaker/'),
('tos-yard-strategy-rules','partially_supported',0.980,'Spinnaker provides yard planning tools and supports terminal-specific decking strategies; advanced graphical yard-strategy planning is a companion-product capability.','https://tideworks.com/spinnaker/'),
('tos-block-allocation','partially_supported',0.980,'Spinnaker automates container location assignments for grounded or wheeled operations and optimizes container positions, but this is a companion planning capability rather than universal core Mainsail entitlement.','https://tideworks.com/spinnaker/'),
('tos-auto-decking-grounding','partially_supported',0.980,'Spinnaker automates container location assignments for grounded or wheeled operations; this is not promoted as native base-Mainsail decking functionality.','https://tideworks.com/spinnaker/'),
('tos-rehandle-minimization','partially_supported',0.980,'Spinnaker explicitly helps avoid costly rehandles and set-asides through optimized yard positioning; it remains a companion-product capability.','https://tideworks.com/spinnaker/'),
('tos-yard-inventory-reconciliation','supported',0.980,'Mainsail manages cargo and inventory with real-time operational visibility; Tideworks describes active inventory control as tightly coupled with Mainsail, while advanced graphical yard planning remains in Spinnaker.','https://tideworks.com/mainsail/'),
('tos-gate-lane-automation','partially_supported',0.990,'GateVision integrates gate video, voice communication and the TOS and centralizes lane processing, but GateVision is a separate companion gate-operations system rather than base Mainsail functionality.','https://tideworks.com/gate-vision/'),
('tos-truck-turntime-queues','partially_supported',0.960,'GateVision is designed to process trucks faster and distributes lane calls efficiently, but detailed turn-time measurement and queue analytics are not established as universal Mainsail-native functions.','https://tideworks.com/gate-vision/'),
('tos-train-schedule-management','partially_supported',0.970,'Spinnaker includes graphical rail planning and schedule visibility, but rail planning belongs to the companion Spinnaker product rather than universal base Mainsail entitlement.','https://tideworks.com/spinnaker/'),
('tos-rail-load-discharge-planning','partially_supported',0.980,'Spinnaker rail planning supports incoming/outgoing train planning, railcar movement and automated railcar stowage; this remains a companion-product boundary.','https://tideworks.com/spinnaker/'),
('tos-rtg-rmg-dispatch','partially_supported',0.970,'Traffic Control provides electronic equipment dispatch, move prioritization and crane optimization; equipment-dispatch functions are attributed to the companion Traffic Control system, not base Mainsail.','https://tideworks.com/traffic-control/'),
('tos-tt-straddle-dispatch','partially_supported',0.970,'Traffic Control dispatches work instructions to handling equipment and pools equipment by operational zones; exact truck/straddle configuration depends on the companion execution system deployment.','https://tideworks.com/traffic-control/'),
('tos-vmt-mobile-work-instructions','partially_supported',0.980,'Traffic Control provides web-deployable mobile clients and touch-screen handling-equipment interfaces for electronic work instructions; this is a Traffic Control companion capability, not native Mainsail mobile execution.','https://tideworks.com/traffic-control/'),
('tos-equipment-position-tracking','partially_supported',0.970,'Traffic Control supports optional DGPS and standardized position-detection integrations, but equipment-position tracking belongs to the companion execution stack and may require external positioning technology.','https://tideworks.com/traffic-control/'),
('tos-job-pooling-optimization','partially_supported',0.990,'Traffic Control explicitly prioritizes moves and pools equipment against yard, rail, vessel and gate operations; it remains a separate equipment-control companion product.','https://tideworks.com/traffic-control/'),
('tos-rest-api-integration','supported',0.990,'Mainsail 10 explicitly uses RESTful API calls and real-time messaging for third-party integrations, and current cloud deployments document standardized APIs for data exchange.','https://tideworks.com/industry-integration-third-party-systems-in-mainsail-10/'),
('tos-pcs-customs-integration','partially_supported',0.980,'Mainsail 10 explicitly supports Port Community System integrations, but customs integration is not separately established by the reviewed current public material.','https://tideworks.com/tideworks-technology-introduces-mainsail-10-and-announces-go-live-at-mit/'),
('tos-ocr-gate-system-integration','supported',0.990,'Mainsail 10 explicitly supports OCR and LPR third-party integrations; exact OCR/LPR vendors and project topology remain implementation-specific.','https://tideworks.com/tideworks-technology-introduces-mainsail-10-and-announces-go-live-at-mit/'),
('tos-erp-finance-integration','partially_supported',0.960,'Tideworks documents Mainsail integration with third-party ERP systems, but universal finance/ERP connector coverage is not established.','https://tideworks.com/industry-integration-third-party-systems-in-mainsail-10/'),
('tos-billing-financial','supported',0.960,'Tideworks currently publishes Mainsail 10 product material specifically covering Billing, establishing native billing functionality while detailed tariff/rating depth remains separately bounded.','https://tideworks.com/video-library/'),
('tos-storage-tariff-billing','partially_supported',0.940,'Mainsail 10 has documented billing functionality, but the reviewed public material does not enumerate universal storage, tariff, demurrage and service-rating rules.','https://tideworks.com/video-library/'),
('tos-customer-self-service','partially_supported',0.990,'Forecast provides terminal customers with container information, clearance/demurrage status, notifications and online payments, but Forecast is a separate companion customer-service portal rather than base Mainsail functionality.','https://tideworks.com/forecast/'),
('tos-shift-dashboard','partially_supported',0.950,'Mainsail 10 provides real-time visibility and highly configurable reporting, but a dedicated shift/control-room dashboard workflow is not separately established.','https://tideworks.com/mainsail-10-advanced-reporting-capabilities/'),
('tos-productivity-kpis','supported',0.980,'Mainsail 10 supports historical reporting, real-time visibility, trending analysis, custom ad-hoc reports and dynamic recap for terminal operational data.','https://tideworks.com/mainsail-10-advanced-reporting-capabilities/'),
('tos-rbac-sso','partially_supported',0.980,'Mainsail 10 explicitly supports granular role-based permissions, but SSO and specific enterprise identity-provider standards are not established in the reviewed Mainsail evidence.','https://tideworks.com/mainsail-10-interactive-search-tools/'),
('tos-scalability-throughput','partially_supported',0.970,'Tideworks positions Mainsail as scalable as terminal requirements and throughput grow and as suitable across terminal sizes, but the reviewed public material does not publish a universal Mainsail TEU ceiling.','https://tideworks.com/mainsail/');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT @mainsail,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat145_facts f
JOIN capabilities c ON c.slug=f.capability_slug
WHERE @mainsail IS NOT NULL
ON DUPLICATE KEY UPDATE
  support_status=VALUES(support_status),
  limitations=VALUES(limitations),
  confidence_score=VALUES(confidence_score),
  last_verified_at=NOW();

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party Tideworks evidence supporting this Mainsail depth status and companion-product boundary.'
FROM cat145_facts f
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=@mainsail AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=@mainsail AND e.source_url=f.source_url;

-- Mainsail 10 is explicitly browser-based/responsive and scales to a variety of devices.
-- This supports mobile web only; it does not establish native Android or iOS applications.
UPDATE product_mobile_access pma
JOIN products p ON p.id=pma.product_id
SET pma.support_status='supported',
    pma.scope_status='limited',
    pma.scope_notes='Responsive browser access is verified for Mainsail 10 across a variety of devices; exact small-screen feature parity is not separately documented. Native Android and iOS applications are not inferred.',
    pma.evidence_url='https://tideworks.com/customized-user-experience-in-mainsail-10/',
    pma.evidence_type='vendor_documentation',
    pma.confidence_score=0.980,
    pma.last_verified_at=NOW()
WHERE p.slug='tideworks-mainsail' AND pma.platform='mobile_web';

UPDATE products SET last_reviewed_at=NOW() WHERE id=@mainsail;

COMMIT;
