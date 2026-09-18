-- TechSelectAI TOS Depth Program - Kaleris N4 evidence pass.
-- Promotes only granular TOS criteria supported by current first-party Kaleris evidence reviewed Sep 2026.
-- Optional Advanced Optimization modules and implementation-specific integrations remain partially_supported.
-- Every unlisted TOS criterion remains not_yet_verified. Unknown != Unsupported.
-- No Fit Score, recommendation ranking, review weighting, popularity or commercial placement logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

SET @n4=(SELECT id FROM products WHERE slug='kaleris-n4-tos' LIMIT 1);

DROP TEMPORARY TABLE IF EXISTS cat140_sources;
CREATE TEMPORARY TABLE cat140_sources(url TEXT,title VARCHAR(255));
INSERT INTO cat140_sources VALUES
('https://kaleris.com/solutions/terminal-operating-system/container-terminals/','Kaleris N4 for Container Terminals'),
('https://kaleris.com/solutions/terminal-operating-system/','Kaleris Terminal Operations'),
('https://kaleris.com/what-is-a-terminal-operating-system/','Kaleris: What Is a Terminal Operating System'),
('https://kaleris.com/news/kerry-siam-seaport-optimizes-operations-and-reduces-carbon-emissions/','Kerry Siam Seaport N4 Optimization'),
('https://kaleris.com/news/terminal-darsena-toscana/','Terminal Darsena Toscana Expert Decking'),
('https://kaleris.com/news/kaleris-launches-yard-intelligence-suite-to-overcome-rising-capacity-constraints-unlock-value-from-existing-systems-and-support-workforce-evolution/','Kaleris Yard Intelligence Suite'),
('https://kaleris.com/advanced-optimization/','Kaleris Advanced Optimization'),
('https://kaleris.com/case-study/baltic-container-terminal-case-study/','Baltic Container Terminal N4 Case Study'),
('https://kaleris.com/case-study/transnet-case-study/','Transnet Multi-Terminal N4 Case Study'),
('https://kaleris.com/kaleris-named-top-100-logistics-company/','Kaleris N4 4.0 Resiliency Scalability and Security'),
('https://kaleris.com/case-study/caacupe-mi-port-case-study/','Caacupe-mi N4 Multi-Facility and Billing Case Study');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT @n4,'vendor_documentation',s.url,s.title,'Kaleris',1,'verified','high',NOW()
FROM cat140_sources s
WHERE @n4 IS NOT NULL
  AND NOT EXISTS(
    SELECT 1 FROM evidence_sources e
    WHERE e.product_id=@n4 AND e.source_url=s.url
  );

DROP TEMPORARY TABLE IF EXISTS cat140_facts;
CREATE TEMPORARY TABLE cat140_facts(
  capability_slug VARCHAR(190),
  support_status VARCHAR(40),
  confidence DECIMAL(4,3),
  limitations TEXT,
  source_url TEXT
);
INSERT INTO cat140_facts VALUES
('tos-berth-window-scheduling','partially_supported',0.990,'Kaleris documents Berth Window Manager deployed within the N4 optimization stack. Treat it as an optional/advanced planning module rather than universal base-N4 entitlement.','https://kaleris.com/news/kerry-siam-seaport-optimizes-operations-and-reduces-carbon-emissions/'),
('tos-stowage-bay-planning','partially_supported',0.990,'N4 Vessel Autostow generates vessel stowage plans, but Autostow is an advanced optimization module and is not assumed in every N4 license.','https://kaleris.com/solutions/terminal-operating-system/container-terminals/'),
('tos-quay-crane-split-planning','partially_supported',0.950,'KSSP deployed Quay Commander with N4 and reports optimized vessel and crane workplans; exact crane-split depth and entitlement should be confirmed for the selected package.','https://kaleris.com/news/kerry-siam-seaport-optimizes-operations-and-reduces-carbon-emissions/'),
('tos-vessel-plan-collaboration','partially_supported',0.950,'A Kaleris N4 implementation documents stronger collaboration with shipping-line stowage coordinators around vessel and crane workplans; universal collaboration tooling is not inferred.','https://kaleris.com/news/kerry-siam-seaport-optimizes-operations-and-reduces-carbon-emissions/'),
('tos-yard-strategy-rules','partially_supported',0.990,'Expert Decking uses terminal business rules and Yard Intelligence adds strategy-oriented optimization; these capabilities are advanced/optional modules rather than assumed base-N4 entitlement.','https://kaleris.com/news/terminal-darsena-toscana/'),
('tos-auto-decking-grounding','partially_supported',0.990,'Expert Decking automatically distributes containers according to terminal-specific business rules, but Expert Decking is an optional N4 optimization module.','https://kaleris.com/news/terminal-darsena-toscana/'),
('tos-import-export-prestack','partially_supported',0.970,'Expert Decking explicitly automates decking decisions for import, export, reefer and empty containers; a distinct universal prestack workflow is not inferred.','https://kaleris.com/news/terminal-darsena-toscana/'),
('tos-rehandle-minimization','partially_supported',0.990,'Expert Decking and Yard Intelligence explicitly target rehandle reduction, but the optimization capability depends on optional advanced modules.','https://kaleris.com/news/terminal-darsena-toscana/'),
('tos-yard-density-capacity','partially_supported',0.970,'Yard Intelligence forecasts emerging congestion and yard imbalance and supports capacity-oriented decisions, but it is a separate advanced optimization suite for N4 users.','https://kaleris.com/news/kaleris-launches-yard-intelligence-suite-to-overcome-rising-capacity-constraints-unlock-value-from-existing-systems-and-support-workforce-evolution/'),
('tos-ocr-anpr-gate','partially_supported',0.960,'A documented N4 terminal implementation integrates automated gate OCR and license-plate recognition. This is evidence of integration, not proof that N4 itself is the native OCR/ANPR engine.','https://kaleris.com/case-study/baltic-container-terminal-case-study/'),
('tos-gate-lane-automation','partially_supported',0.970,'N4 is documented orchestrating automated gate traffic in a live implementation, but the exact lane-device stack is project-specific and should not be treated as universal native hardware control.','https://kaleris.com/case-study/baltic-container-terminal-case-study/'),
('tos-weighbridge-vgm','partially_supported',0.970,'A live N4 implementation links container weighing systems to N4 for SOLAS VGM compliance. Universal weighbridge hardware/protocol coverage is not inferred.','https://kaleris.com/case-study/baltic-container-terminal-case-study/'),
('tos-rtg-rmg-dispatch','partially_supported',0.990,'Kaleris RTG Optimization and N4 resource-planning workflows optimize yard-crane work, but RTG Optimization is an advanced add-on rather than assumed in every N4 deployment.','https://kaleris.com/advanced-optimization/'),
('tos-tt-straddle-dispatch','partially_supported',0.980,'Terminal Truck Optimization and PrimeRoute optimize terminal-truck dispatch using N4 data; straddle-carrier-specific dispatch depth is not generalized from truck evidence.','https://kaleris.com/advanced-optimization/'),
('tos-vmt-mobile-work-instructions','partially_supported',0.980,'Kaleris documents an N4 Vehicle Mounted Terminal interface for RTG/RMG drivers, but VMT availability is a specific N4 application/module rather than assumed universal entitlement.','https://kaleris.com/solutions/terminal-operating-system/container-terminals/'),
('tos-equipment-position-tracking','supported',0.980,'N4 Control Room visualizes where containers, cranes and trucks are in the yard, providing equipment/location visibility for operational control.','https://kaleris.com/solutions/terminal-operating-system/container-terminals/'),
('tos-job-pooling-optimization','partially_supported',0.980,'Kaleris Advanced Optimization continuously evaluates crane, truck and yard tasks to determine the next best move; these optimization products complement N4 and are not assumed base entitlement.','https://kaleris.com/advanced-optimization/'),
('tos-agv-asc-automation','supported',0.980,'Kaleris states N4 automation supports automated stacking cranes, AGVs and auto-trucks and coordinates automated yard, transport, quay and gate execution through ECS integration.','https://kaleris.com/what-is-a-terminal-operating-system/'),
('tos-vgm-weight-control','partially_supported',0.970,'N4 has documented SOLAS VGM compliance through integration with container weighing systems in a live terminal; exact VGM workflow depth can vary by implementation.','https://kaleris.com/case-study/baltic-container-terminal-case-study/'),
('tos-rest-api-integration','supported',0.990,'Kaleris explicitly documents robust API integration for N4 with external systems and data streams.','https://kaleris.com/what-is-a-terminal-operating-system/'),
('tos-ocr-gate-system-integration','supported',0.980,'Kaleris documents N4 integration with automated gate OCR/license-plate recognition and traffic-flow systems in production terminal operations.','https://kaleris.com/case-study/baltic-container-terminal-case-study/'),
('tos-storage-tariff-billing','partially_supported',0.970,'N4 captures billable events and invoices and supports granular billable tasks, but the reviewed evidence does not establish universal storage/tariff configuration depth for every deployment.','https://kaleris.com/what-is-a-terminal-operating-system/'),
('tos-customer-self-service','partially_supported',0.960,'A multi-terminal N4 implementation gives customers real-time access to cargo information and online work orders; packaging and portal scope are implementation-dependent.','https://kaleris.com/case-study/transnet-case-study/'),
('tos-shift-dashboard','supported',0.980,'N4 Control Room centralizes operational views and functions used to monitor and maintain terminal operations.','https://kaleris.com/solutions/terminal-operating-system/container-terminals/'),
('tos-productivity-kpis','supported',0.970,'Kaleris documents N4 real-time operational visibility and performance/productivity insights used to improve terminal execution.','https://kaleris.com/solutions/terminal-operating-system/'),
('tos-simulation-whatif','partially_supported',0.960,'Yard Intelligence evaluates alternative scenarios and recommends pre-emptive moves, but it is an advanced optimization suite rather than universal base-N4 functionality.','https://kaleris.com/news/kaleris-launches-yard-intelligence-suite-to-overcome-rising-capacity-constraints-unlock-value-from-existing-systems-and-support-workforce-evolution/'),
('tos-forecasting-demand','partially_supported',0.960,'Yard Intelligence anticipates congestion and yard imbalances hours in advance; broader volume/resource-demand forecasting is not inferred beyond the documented yard scope.','https://kaleris.com/news/kaleris-launches-yard-intelligence-suite-to-overcome-rising-capacity-constraints-unlock-value-from-existing-systems-and-support-workforce-evolution/'),
('tos-multi-terminal','supported',0.980,'Transnet documents operating multiple terminals on a single N4 system while standardizing processes across the terminal network.','https://kaleris.com/case-study/transnet-case-study/'),
('tos-cloud-onprem-flexibility','supported',0.980,'Kaleris explicitly discusses N4 4.0 for existing on-premises customers and cloud adoption, supporting more than one enterprise deployment pattern.','https://kaleris.com/solutions/terminal-operating-system/container-terminals/'),
('tos-scalability-throughput','supported',0.990,'Kaleris states N4 4.0 scales to very large container-terminal volumes, including published capacity up to 16 million TEU.','https://kaleris.com/kaleris-named-top-100-logistics-company/'),
('tos-special-cargo-controls','partially_supported',0.940,'Expert Decking explicitly applies yard-planning logic to reefer containers, but the reviewed N4 evidence does not yet establish full dangerous-goods, OOG and reefer-service control as one universal capability.','https://kaleris.com/news/terminal-darsena-toscana/');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT @n4,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat140_facts f
JOIN capabilities c ON c.slug=f.capability_slug
WHERE @n4 IS NOT NULL
ON DUPLICATE KEY UPDATE
  support_status=VALUES(support_status),
  limitations=VALUES(limitations),
  confidence_score=VALUES(confidence_score),
  last_verified_at=NOW();

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party Kaleris evidence supporting this TOS depth capability status and scope boundary.'
FROM cat140_facts f
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=@n4 AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=@n4 AND e.source_url=f.source_url;

UPDATE products SET last_reviewed_at=NOW() WHERE id=@n4;

COMMIT;
