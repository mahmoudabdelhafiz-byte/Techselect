-- TechSelectAI TOS Depth Program - RBS TOPS Expert evidence pass.
-- Reviews granular TOPS Expert criteria using current first-party RBS material.
-- TOPX and TOPO are package components; KPI, Billing, GOS, Reefer Monitoring, Truck Appointment,
-- VBS, DGPS and Web Service Interface remain named component/module boundaries where applicable.
-- Enterprise and Cloud evidence is used only at the TOPS Expert family scope already represented by this product shell.
-- Every unlisted TOS criterion remains not_yet_verified. Unknown != Unsupported.
-- No Fit Score, recommendation ranking, review weighting, popularity or commercial placement logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

SET @rbs=(SELECT id FROM products WHERE slug='rbs-tops-expert' LIMIT 1);

DROP TEMPORARY TABLE IF EXISTS cat143_sources;
CREATE TEMPORARY TABLE cat143_sources(url TEXT,title VARCHAR(255));
INSERT INTO cat143_sources VALUES
('https://rbs-tops.com/terminal-operating-system/tops-terminal-solution/tops-expert-enterprise/','RBS TOPS Expert Enterprise'),
('https://rbs-tops.com/terminal-operating-system/topx-expert/','RBS TOPX Expert'),
('https://rbs-tops.com/terminal-operating-system/topo-expert-2/','RBS TOPO Expert'),
('https://rbs-tops.com/terminal-operating-system/topx-expert/automation/','RBS TOPS Expert Automation'),
('https://rbs-tops.com/terminal-operating-system/topx-expert/optimization/','RBS TOPS Expert Optimization'),
('https://rbs-tops.com/rail-terminal/','RBS Rail Terminal Solution'),
('https://rbs-tops.com/terminal-operating-system/','RBS TOPS Terminal Solution'),
('https://www.rbs-emea.com/products/tops-expert-cloud','RBS TOPS Expert Cloud');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT @rbs,'vendor_documentation',s.url,s.title,'Realtime Business Solutions',1,'verified','high',NOW()
FROM cat143_sources s
WHERE @rbs IS NOT NULL
  AND NOT EXISTS(
    SELECT 1 FROM evidence_sources e
    WHERE e.product_id=@rbs AND e.source_url=s.url
  );

DROP TEMPORARY TABLE IF EXISTS cat143_facts;
CREATE TEMPORARY TABLE cat143_facts(
  capability_slug VARCHAR(190),
  support_status VARCHAR(40),
  confidence DECIMAL(4,3),
  limitations TEXT,
  source_url TEXT
);
INSERT INTO cat143_facts VALUES
('tos-berth-window-scheduling','partially_supported',0.980,'TOPX Expert explicitly provides integrated smart automated berth planning and optimization, but public material does not separately establish berth-window conflict rules and arrival/departure window management depth.','https://rbs-tops.com/terminal-operating-system/topx-expert/'),
('tos-vessel-call-management','supported',0.980,'TOPX Expert manages vessel and berth operations from berthing through operational completion within its real-time planning and control scope.','https://rbs-tops.com/terminal-operating-system/topx-expert/'),
('tos-stowage-bay-planning','partially_supported',0.970,'TOPX Expert documents advanced automated vessel planning and crane scheduling, but detailed bay-position, hatch, deck and stowage-constraint functions are not separately enumerated in the reviewed public material.','https://rbs-tops.com/terminal-operating-system/topx-expert/'),
('tos-discharge-load-sequencing','partially_supported',0.950,'Automated vessel planning and crane scheduling support ship-work sequencing, but explicit discharge/load sequence controls are not separately documented publicly.','https://rbs-tops.com/terminal-operating-system/topx-expert/'),
('tos-quay-crane-split-planning','partially_supported',0.960,'RBS documents automatic crane scheduling and vessel planning, but explicit quay-crane split/range planning is not separately established.','https://rbs-tops.com/terminal-operating-system/topx-expert/'),
('tos-quay-work-queues','partially_supported',0.950,'TOPX combines vessel operations, equipment control and real-time operational resource allocation, but explicit quay-crane work-queue semantics are not separately documented.','https://rbs-tops.com/terminal-operating-system/topx-expert/'),
('tos-yard-strategy-rules','supported',0.990,'TOPX Expert explicitly uses reverse engineering to manage yard strategy and includes Expert Yard Management within the operational system.','https://rbs-tops.com/terminal-operating-system/topx-expert/'),
('tos-block-allocation','partially_supported',0.960,'TOPX automatically manages container storage toward final positions and provides Expert Yard Management, but public material does not enumerate every block/row/bay/stack allocation rule.','https://rbs-tops.com/terminal-operating-system/topx-expert/'),
('tos-auto-decking-grounding','partially_supported',0.960,'TOPX automatically manages container storage positions to support retrieval and reduce rehandles, but the reviewed public material does not use explicit decking/grounding terminology.','https://rbs-tops.com/terminal-operating-system/topx-expert/'),
('tos-housekeeping-remarshalling','partially_supported',0.950,'Expert Yard Management and automated storage optimization support yard strategy, but proactive housekeeping/remarshalling planning is not separately described publicly.','https://rbs-tops.com/terminal-operating-system/topx-expert/'),
('tos-rehandle-minimization','supported',0.990,'RBS explicitly states TOPX automatically manages container storage while minimizing re-handling moves.','https://rbs-tops.com/terminal-operating-system/topx-expert/'),
('tos-truck-appointment-integration','partially_supported',0.990,'Truck Appointment is a named TOPS Expert additional module; it is not assumed as universal base TOPX/TOPO entitlement.','https://rbs-tops.com/terminal-operating-system/'),
('tos-pre-advice-booking','partially_supported',0.960,'Vehicle Booking System is a named TOPS optional module, but the reviewed public material does not establish all booking/release/pre-advice validation functions as universal base entitlement.','https://rbs-tops.com/terminal-operating-system/'),
('tos-ocr-anpr-gate','partially_supported',0.970,'TOPS Expert automation explicitly includes OCR and automated gate access/position detection, but ANPR is not separately stated and external gate technology may participate in the solution.','https://rbs-tops.com/terminal-operating-system/topx-expert/automation/'),
('tos-driver-id-authentication','partially_supported',0.940,'RBS documents gate automation with access control and traffic identification, but driver-identity credential methods are not enumerated.','https://rbs-tops.com/terminal-operating-system/topx-expert/automation/'),
('tos-gate-lane-automation','partially_supported',0.980,'TOPS Expert supports gate automation for truck, train and vessel traffic with access control, yard interchange and position detection; GOS and external gate components remain module/integration boundaries.','https://rbs-tops.com/terminal-operating-system/topx-expert/automation/'),
('tos-train-schedule-management','supported',0.980,'The RBS rail-terminal solution explicitly includes Rail Planning & Scheduling within TOPS Expert.','https://rbs-tops.com/rail-terminal/'),
('tos-rail-yard-inventory','partially_supported',0.950,'The rail solution combines rail operations with yard management and container data management, but a distinct rail-inventory reconciliation workflow is not separately documented.','https://rbs-tops.com/rail-terminal/'),
('tos-rail-load-discharge-planning','supported',0.980,'RBS explicitly lists Rail Planning & Scheduling and Rail Operation & Management in its TOPS Expert rail-terminal scope.','https://rbs-tops.com/rail-terminal/'),
('tos-rail-crane-work-queues','partially_supported',0.940,'Rail operations are combined with equipment control and CHE optimization, but explicit rail-crane work-queue semantics are not separately documented.','https://rbs-tops.com/rail-terminal/'),
('tos-qc-work-queues','partially_supported',0.950,'TOPX Expert integrates crane scheduling, equipment control and resource allocation; explicit quay-crane job-queue detail is not separately established.','https://rbs-tops.com/terminal-operating-system/topx-expert/'),
('tos-rtg-rmg-dispatch','partially_supported',0.970,'TOPS Expert automation explicitly supports automated yard CHE including ASC, ARMG and ARTG, but exact RTG/RMG dispatch algorithms and entitlement depend on the automation configuration.','https://rbs-tops.com/terminal-operating-system/topx-expert/automation/'),
('tos-tt-straddle-dispatch','partially_supported',0.960,'TOPX provides truck operational management, Expert CHE Strategy and equipment optimization, but straddle-carrier-specific dispatch is not explicitly established in the reviewed public material.','https://rbs-tops.com/terminal-operating-system/topx-expert/'),
('tos-agv-asc-automation','supported',0.990,'TOPS Expert automation explicitly supports automated CHE including ASC, ARMG, ARTG and automated transport equipment and can communicate directly with equipment for container moves without human intervention.','https://rbs-tops.com/terminal-operating-system/topx-expert/automation/'),
('tos-equipment-position-tracking','partially_supported',0.980,'TOPS Expert documents SmartTrack, DGPS and gate position detection; DGPS and related tracking components are named modules and should not be assumed in every base deployment.','https://rbs-tops.com/terminal-operating-system/'),
('tos-job-pooling-optimization','supported',0.990,'TOPS Expert documents holistic optimization of equipment usage, real-time resource allocation, CHE strategy optimization and resource/process optimization.','https://rbs-tops.com/terminal-operating-system/topx-expert/optimization/'),
('tos-reefer-temperature-alarms','partially_supported',0.970,'Reefer Monitoring System/Integration is a named TOPS Expert additional module, so reefer monitoring is evidenced without assuming universal base entitlement.','https://rbs-tops.com/terminal-operating-system/'),
('tos-rest-api-integration','partially_supported',0.990,'TOPO Expert explicitly provides open interfaces via web services, and Web Service Interface with Third Party Software is a named TOPS module; REST specifically is not claimed.','https://rbs-tops.com/terminal-operating-system/topo-expert-2/'),
('tos-ocr-gate-system-integration','partially_supported',0.980,'TOPS Expert automation integrates OCR and GOS/gate automation, but exact vendor adapters and whether recognition is native or external remain implementation-specific.','https://rbs-tops.com/terminal-operating-system/topx-expert/automation/'),
('tos-reefer-system-integration','partially_supported',0.980,'RBS explicitly lists Reefer Monitoring Integration/System as an additional TOPS module; deployment depends on the selected package and external monitoring environment.','https://rbs-tops.com/terminal-operating-system/'),
('tos-erp-finance-integration','partially_supported',0.970,'TOPS Expert Cloud explicitly supports interfaces to financial systems, but the reviewed public material does not establish universal ERP connectors or accounting-system coverage across all editions.','https://www.rbs-emea.com/products/tops-expert-cloud'),
('tos-storage-tariff-billing','partially_supported',0.970,'Billing is a named TOPS/TOPO special module, so billing capability is evidenced without inferring every storage/tariff/rating rule as universal base functionality.','https://rbs-tops.com/terminal-operating-system/'),
('tos-shift-dashboard','partially_supported',0.960,'TOPS KPI provides remote real-time and historical terminal performance analysis, but it is a named dashboard component rather than assumed universal base TOPX entitlement.','https://rbs-tops.com/terminal-operating-system/'),
('tos-productivity-kpis','partially_supported',0.980,'TOPS KPI provides real-time and historical performance analysis while TOPS Expert also documents operational monitoring; KPI dashboard entitlement remains a package/component boundary.','https://rbs-tops.com/terminal-operating-system/'),
('tos-forecasting-demand','partially_supported',0.980,'TOPS Expert documents forecasting abilities, a dispatching and operation forecast planner, and resource-use forecasting, but explicit container-volume and labor-demand forecasting are not established.','https://rbs-tops.com/terminal-operating-system/topx-expert/optimization/'),
('tos-cloud-onprem-flexibility','supported',0.990,'RBS offers distinct TOPS Expert Enterprise and TOPS Expert Cloud packages, establishing deployment flexibility across enterprise-installed and cloud variants at the TOPS Expert family level.','https://rbs-tops.com/terminal-operating-system/'),
('tos-rbac-sso','partially_supported',0.940,'TOPX Expert explicitly includes Security & Administration, but the reviewed public material does not establish SSO or the full role/identity model.','https://rbs-tops.com/terminal-operating-system/topx-expert/'),
('tos-scalability-throughput','supported',0.980,'RBS describes TOPX as high-performance and scalable and TOPS automation/optimization as scalable for terminals of varying sizes, although no universal TEU ceiling is published in the reviewed material.','https://rbs-tops.com/terminal-operating-system/tops-terminal-solution/tops-expert-enterprise/');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT @rbs,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat143_facts f
JOIN capabilities c ON c.slug=f.capability_slug
WHERE @rbs IS NOT NULL
ON DUPLICATE KEY UPDATE
  support_status=VALUES(support_status),
  limitations=VALUES(limitations),
  confidence_score=VALUES(confidence_score),
  last_verified_at=NOW();

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party RBS evidence supporting this TOPS Expert depth status and scope boundary.'
FROM cat143_facts f
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=@rbs AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=@rbs AND e.source_url=f.source_url;

UPDATE products SET last_reviewed_at=NOW() WHERE id=@rbs;

COMMIT;
