-- TechSelectAI TOS Depth Program - Total Soft Bank CATOS evidence pass.
-- Reviews granular CATOS criteria using current first-party Total Soft Bank material.
-- CATOS Digital Twin remains a separate companion-product boundary for richer 3D/simulation functions.
-- Generic integration references are not converted into unsupported native-protocol claims.
-- Every unlisted TOS criterion remains not_yet_verified. Unknown != Unsupported.
-- No Fit Score, recommendation ranking, review weighting, popularity or commercial placement logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

SET @catos=(SELECT id FROM products WHERE slug='total-soft-bank-catos' LIMIT 1);

DROP TEMPORARY TABLE IF EXISTS cat144_sources;
CREATE TEMPORARY TABLE cat144_sources(url TEXT,title VARCHAR(255));
INSERT INTO cat144_sources VALUES
('https://www.tsb.co.kr/CATOS','Total Soft Bank CATOS'),
('https://www.tsb.co.kr/About','Total Soft Bank About / Terminal Automation'),
('https://www.tsb.co.kr/VR','Total Soft Bank CATOS Digital Twin');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT @catos,'vendor_documentation',s.url,s.title,'Total Soft Bank',1,'verified','high',NOW()
FROM cat144_sources s
WHERE @catos IS NOT NULL
  AND NOT EXISTS(
    SELECT 1 FROM evidence_sources e
    WHERE e.product_id=@catos AND e.source_url=s.url
  );

DROP TEMPORARY TABLE IF EXISTS cat144_facts;
CREATE TEMPORARY TABLE cat144_facts(
  capability_slug VARCHAR(190),
  support_status VARCHAR(40),
  confidence DECIMAL(4,3),
  limitations TEXT,
  source_url TEXT
);
INSERT INTO cat144_facts VALUES
('tos-berth-window-scheduling','partially_supported',0.960,'CATOS explicitly includes Berth Planning, but the reviewed public material does not separately establish berth-window conflict handling, arrival/departure window rules or dedicated slot-management depth.','https://www.tsb.co.kr/CATOS'),
('tos-stowage-bay-planning','partially_supported',0.980,'CATOS Auto Ship Planning generates loading, discharging and re-stow plans using configurable planning patterns and constraints, but the public material does not separately enumerate all bay/deck/hatch stowage controls.','https://www.tsb.co.kr/CATOS'),
('tos-discharge-load-sequencing','supported',0.990,'CATOS Auto Ship Planning explicitly generates ship loading, discharging and re-stow planning and is designed to reduce unnecessary crane movement.','https://www.tsb.co.kr/CATOS'),
('tos-vessel-restow-rehandle','supported',0.990,'CATOS Auto Ship Planning explicitly includes re-stow planning and aims to minimize restow and unnecessary crane movement.','https://www.tsb.co.kr/CATOS'),
('tos-quay-work-queues','partially_supported',0.950,'CATOS provides Quay Supervisor SRT estimation and terminal-wide work supervision, but explicit quay-crane work-queue semantics and prioritization are not separately documented.','https://www.tsb.co.kr/CATOS'),
('tos-yard-strategy-rules','supported',0.990,'CATOS container-position optimization supports grouping, boundary, pile-quality, scattering and inter-terminal movement controls, providing configurable yard strategy logic.','https://www.tsb.co.kr/CATOS'),
('tos-block-allocation','supported',0.980,'CATOS container-position optimization controls grouping, boundaries, pile quality and container placement, directly supporting yard allocation decisions.','https://www.tsb.co.kr/CATOS'),
('tos-auto-decking-grounding','partially_supported',0.970,'CATOS provides Auto Positioning and automated shifting/remarshalling, but the reviewed material does not use explicit decking/grounding terminology for all workflows.','https://www.tsb.co.kr/CATOS'),
('tos-housekeeping-remarshalling','supported',0.990,'CATOS explicitly includes Remarshalling Planning plus Auto Shifting and Auto Remarshalling for yard preparation and reorganization.','https://www.tsb.co.kr/CATOS'),
('tos-rehandle-minimization','supported',0.990,'CATOS optimization explicitly targets container positioning, shifting/rehandling efficiency, and Auto Ship Planning minimizes re-stow and unnecessary crane movement.','https://www.tsb.co.kr/CATOS'),
('tos-empty-container-management','partially_supported',0.940,'CATOS auto-swapping covers unexpected empty-container pickup changes, but the reviewed public material does not establish full empty-container inventory, release and stock-control depth.','https://www.tsb.co.kr/CATOS'),
('tos-yard-inventory-reconciliation','supported',0.990,'CATOS explicitly provides an automated reconciliation system for data accuracy, consistency, integrity, reliability and process-wide validation.','https://www.tsb.co.kr/CATOS'),
('tos-yard-density-capacity','partially_supported',0.960,'CATOS positions its optimization around maximizing yard utilization and container-position efficiency, but explicit occupancy thresholds and congestion-control functions are not separately documented.','https://www.tsb.co.kr/CATOS'),
('tos-ocr-anpr-gate','partially_supported',0.970,'CATOS documents integration references with GOS, QC OCR and rail OCR, but ANPR is not separately stated and recognition may be provided by external subsystems.','https://www.tsb.co.kr/CATOS'),
('tos-gate-lane-automation','partially_supported',0.960,'CATOS includes Gate Planning and has integration experience with GOS and autonomous infrastructure, but kiosk/barrier/scale lane orchestration is not enumerated as universal native functionality.','https://www.tsb.co.kr/CATOS'),
('tos-train-schedule-management','partially_supported',0.960,'CATOS explicitly includes Rail Planning, but train-service schedules, cutoffs and consist-management depth are not separately documented.','https://www.tsb.co.kr/CATOS'),
('tos-rail-load-discharge-planning','partially_supported',0.970,'CATOS Rail Planning and Rail Supervisor functions support rail operation planning, but detailed wagon-level load/discharge sequencing is not separately established.','https://www.tsb.co.kr/CATOS'),
('tos-rail-crane-work-queues','partially_supported',0.950,'CATOS documents Rail Supervisor SRT estimation and rail planning, but explicit rail-crane work-queue generation and execution are not separately described.','https://www.tsb.co.kr/CATOS'),
('tos-rtg-rmg-dispatch','supported',0.990,'RTGSS explicitly monitors and supervises manned RTG/RMG transfer cranes for optimal job scheduling and work instructions using scheduling simulation.','https://www.tsb.co.kr/CATOS'),
('tos-tt-straddle-dispatch','supported',0.990,'CHESS explicitly monitors and supervises yard trucks and straddle carriers, calculating routing and shortest paths for optimal job scheduling and work instructions.','https://www.tsb.co.kr/CATOS'),
('tos-agv-asc-automation','supported',0.990,'ATCSS supervises unmanned transfer cranes and CATOS documents integration with ASC/ARMG, autonomous trucks, STS and ATC infrastructure; exact project equipment mix remains implementation-specific.','https://www.tsb.co.kr/CATOS'),
('tos-equipment-position-tracking','partially_supported',0.970,'CATOS documents GPS and autonomous-infrastructure integrations and equipment supervisor functions, but exact positioning technology and entitlement depend on the implementation.','https://www.tsb.co.kr/CATOS'),
('tos-job-pooling-optimization','supported',0.990,'ATCSS, RTGSS and CHESS explicitly perform optimal job scheduling, routing or work-instruction optimization across cranes and horizontal transport.','https://www.tsb.co.kr/CATOS'),
('tos-reefer-temperature-alarms','partially_supported',0.960,'CATOS documents successful reefer-monitoring-system integrations, but the reviewed material does not establish that CATOS itself provides native temperature sensing or every alarm workflow.','https://www.tsb.co.kr/CATOS'),
('tos-pcs-customs-integration','supported',0.990,'CATOS explicitly documents integration references with customs and Port Community Systems across multiple countries.','https://www.tsb.co.kr/CATOS'),
('tos-ocr-gate-system-integration','supported',0.990,'CATOS explicitly documents integration references with GOS, QC OCR and rail OCR systems, establishing operational subsystem integration without assuming CATOS is the recognition engine.','https://www.tsb.co.kr/CATOS'),
('tos-reefer-system-integration','supported',0.990,'CATOS explicitly lists reefer monitoring systems among its established IoT and infrastructure integration references.','https://www.tsb.co.kr/CATOS'),
('tos-customer-self-service','partially_supported',0.930,'CATOS supports ordering through CATOS Web-IP and integrated platforms, but the reviewed public material does not establish the full breadth of customer self-service status, document, invoice or service-request functions.','https://www.tsb.co.kr/CATOS'),
('tos-shift-dashboard','partially_supported',0.970,'CATOS provides an automated real-time analytic dashboard for facility performance, but a dedicated shift/control-room workflow is not separately established in the reviewed material.','https://www.tsb.co.kr/CATOS'),
('tos-productivity-kpis','supported',0.990,'CATOS explicitly provides an automated real-time analytic dashboard for performance evaluation and key performance metrics.','https://www.tsb.co.kr/CATOS'),
('tos-simulation-whatif','partially_supported',0.960,'RTGSS uses scheduling simulation, while richer terminal-wide 3D simulation and digital-twin capabilities are separately presented as CATOS Digital Twin; those CATOS DT functions are not assumed as universal base CATOS entitlement.','https://www.tsb.co.kr/VR'),
('tos-multi-terminal','partially_supported',0.940,'CATOS container-position optimization includes inter-terminal movement control, but the reviewed public material does not establish centralized multi-terminal administration or shared-instance operating scope.','https://www.tsb.co.kr/CATOS'),
('tos-rbac-sso','partially_supported',0.990,'CATOS explicitly supports single sign-on across multiple applications, but the reviewed public material does not separately establish the full RBAC model or identity-provider standards.','https://www.tsb.co.kr/CATOS'),
('tos-scalability-throughput','supported',0.990,'TSB states CATOS serves terminals from below 100,000 TEU to over 5,000,000 TEU and is used by more than 100 terminals across more than 20 countries.','https://www.tsb.co.kr/CATOS');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT @catos,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat144_facts f
JOIN capabilities c ON c.slug=f.capability_slug
WHERE @catos IS NOT NULL
ON DUPLICATE KEY UPDATE
  support_status=VALUES(support_status),
  limitations=VALUES(limitations),
  confidence_score=VALUES(confidence_score),
  last_verified_at=NOW();

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party Total Soft Bank evidence supporting this CATOS depth status and scope boundary.'
FROM cat144_facts f
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=@catos AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=@catos AND e.source_url=f.source_url;

UPDATE products SET last_reviewed_at=NOW() WHERE id=@catos;

COMMIT;
