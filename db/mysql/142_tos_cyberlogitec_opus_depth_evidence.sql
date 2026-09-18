-- TechSelectAI TOS Depth Program - CyberLogitec OPUS Terminal evidence pass.
-- Reviews granular OPUS Terminal criteria using current first-party CyberLogitec material.
-- TLC and implementation-specific automation integrations remain partial where entitlement/scope is not universal.
-- OPUS DigiPort digital-twin, AI prediction and richer KPI functions remain a separate-product boundary.
-- OPUS Terminal M cloud/multi-purpose claims are not promoted onto OPUS Terminal.
-- Every unlisted TOS criterion remains not_yet_verified. Unknown != Unsupported.
-- No Fit Score, recommendation ranking, review weighting, popularity or commercial placement logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

SET @opus=(SELECT id FROM products WHERE slug='cyberlogitec-opus-terminal' LIMIT 1);

DROP TEMPORARY TABLE IF EXISTS cat142_sources;
CREATE TEMPORARY TABLE cat142_sources(url TEXT,title VARCHAR(255));
INSERT INTO cat142_sources VALUES
('https://www.cyberlogitec.com/en/sub/solution/port/opus_terminal.php','CyberLogitec OPUS Terminal'),
('https://www.cyberlogitec.com/en/sub/insight/press_view.php?idx=182','CyberLogitec Incheon Fully Automated Terminal Contract'),
('https://www.cyberlogitec.com/en/sub/insight/press_view.php?idx=162','CyberLogitec Dongwon Global Terminal Automation'),
('https://www.cyberlogitec.com/en/sub/insight/press_view.php?idx=150','Tecon Santos Goes Live with OPUS Terminal'),
('https://www.cyberlogitec.com/en/sub/insight/press_view.php?idx=178','CyberLogitec TTIA Smart Terminal Project'),
('https://www.cyberlogitec.com/en/sub/solution/port/opus_digiport.php','CyberLogitec OPUS DigiPort');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT @opus,'vendor_documentation',s.url,s.title,'CyberLogitec',1,'verified','high',NOW()
FROM cat142_sources s
WHERE @opus IS NOT NULL
  AND NOT EXISTS(
    SELECT 1 FROM evidence_sources e
    WHERE e.product_id=@opus AND e.source_url=s.url
  );

DROP TEMPORARY TABLE IF EXISTS cat142_facts;
CREATE TEMPORARY TABLE cat142_facts(
  capability_slug VARCHAR(190),
  support_status VARCHAR(40),
  confidence DECIMAL(4,3),
  limitations TEXT,
  source_url TEXT
);
INSERT INTO cat142_facts VALUES
('tos-berth-window-scheduling','partially_supported',0.970,'OPUS Terminal documents automated berth planning, but the reviewed public evidence does not establish a dedicated berth-window scheduling workflow or conflict-management depth.','https://www.cyberlogitec.com/en/sub/solution/port/opus_terminal.php'),
('tos-stowage-bay-planning','partially_supported',0.960,'OPUS Terminal documents automated vessel planning using historical analysis and configurable patterns; exact bay-position and stowage-rule depth is not separately established in the reviewed public material.','https://www.cyberlogitec.com/en/sub/solution/port/opus_terminal.php'),
('tos-quay-work-queues','partially_supported',0.960,'The TLC module executes optimized work orders across vessel, rail and gate operations, but quay-crane work-queue depth is not described as a standalone universal base capability.','https://www.cyberlogitec.com/en/sub/solution/port/opus_terminal.php'),
('tos-yard-strategy-rules','partially_supported',0.970,'Automated yard planning uses historical analysis and configurable customer patterns; the reviewed public material does not enumerate the full yard-strategy rule model.','https://www.cyberlogitec.com/en/sub/solution/port/opus_terminal.php'),
('tos-block-allocation','partially_supported',0.950,'CyberLogitec documents automated yard planning and yard-location simulation, but explicit block, row, bay and stack allocation controls are not fully enumerated publicly.','https://www.cyberlogitec.com/en/sub/solution/port/opus_terminal.php'),
('tos-yard-density-capacity','partially_supported',0.950,'Operation Simulation estimates workload by time, block and equipment and evaluates yard locations, but explicit capacity-threshold and congestion-management controls are not fully described.','https://www.cyberlogitec.com/en/sub/solution/port/opus_terminal.php'),
('tos-ocr-anpr-gate','partially_supported',0.960,'A production OPUS Terminal deployment at Tecon Santos supports OCR-enabled terminal equipment and digital technologies; ANPR scope and the distinction between native recognition and integrated subsystems are not established.','https://www.cyberlogitec.com/en/sub/insight/press_view.php?idx=150'),
('tos-gate-lane-automation','partially_supported',0.960,'CyberLogitec documents OPUS Terminal managing gate operations in automated-terminal projects, but public evidence does not enumerate kiosk, barrier, scale and lane-device orchestration as universal base functionality.','https://www.cyberlogitec.com/en/sub/insight/press_view.php?idx=182'),
('tos-rail-load-discharge-planning','partially_supported',0.970,'The TLC module explicitly optimizes entry-exit container work involving rail, but detailed train, wagon and rail-crane planning scope is not established.','https://www.cyberlogitec.com/en/sub/solution/port/opus_terminal.php'),
('tos-qc-work-queues','partially_supported',0.960,'Automated-terminal implementations prepare work plans, assign equipment and manage real-time allocation including double-trolley quay cranes; exact QC work-queue entitlement depends on the implemented OPUS/TLC stack.','https://www.cyberlogitec.com/en/sub/insight/press_view.php?idx=162'),
('tos-rtg-rmg-dispatch','partially_supported',0.970,'CyberLogitec documents ARMGC operations with OPUS Terminal, TLC and the automation stack; RTG/RMG dispatch is therefore evidenced at implementation/module level rather than assumed as identical universal base-product scope.','https://www.cyberlogitec.com/en/sub/insight/press_view.php?idx=162'),
('tos-tt-straddle-dispatch','partially_supported',0.950,'OPUS Terminal/TLC optimizes terminal equipment workload and DGT uses real-time vehicle location and job allocation, but straddle-carrier-specific dispatch is not established by the reviewed evidence.','https://www.cyberlogitec.com/en/sub/insight/press_view.php?idx=162'),
('tos-agv-asc-automation','supported',0.990,'CyberLogitec documents OPUS Terminal interfacing automated equipment control systems in projects using AGVs and automated rail-mounted gantry cranes, supporting operational planning and field execution.','https://www.cyberlogitec.com/en/sub/insight/press_view.php?idx=182'),
('tos-equipment-position-tracking','partially_supported',0.960,'Real-time container and vehicle location tracking is documented in the DGT implementation, but that deployment also uses TLC and the separate OPUS DigiPort IoT/data platform; native OPUS Terminal-only scope is not assumed.','https://www.cyberlogitec.com/en/sub/insight/press_view.php?idx=162'),
('tos-job-pooling-optimization','partially_supported',0.980,'CyberLogitec states the TLC module optimizes overall terminal workload and equipment/yard work orders; TLC module entitlement is not assumed as universal base OPUS Terminal entitlement.','https://www.cyberlogitec.com/en/sub/solution/port/opus_terminal.php'),
('tos-pcs-customs-integration','partially_supported',0.940,'OPUS Terminal explicitly supports integration with port authorities, but the reviewed material does not establish universal Port Community System or customs-interface coverage.','https://www.cyberlogitec.com/en/sub/solution/port/opus_terminal.php'),
('tos-carrier-booking-integration','partially_supported',0.940,'CyberLogitec explicitly documents shipping-carrier integration, but booking, release and carrier-message transaction depth is not enumerated in the reviewed public material.','https://www.cyberlogitec.com/en/sub/solution/port/opus_terminal.php'),
('tos-ocr-gate-system-integration','supported',0.970,'Tecon Santos documents OPUS Terminal integration with OCR-enabled operational technology; exact OCR vendor adapters and project topology remain implementation-specific.','https://www.cyberlogitec.com/en/sub/insight/press_view.php?idx=150'),
('tos-productivity-kpis','partially_supported',0.960,'OPUS Terminal includes operation analysis, configurable reports and productivity-oriented decision support, while richer real-time KPI dashboards and digital-twin analytics are documented under the separate OPUS DigiPort product.','https://www.cyberlogitec.com/en/sub/solution/port/opus_terminal.php'),
('tos-simulation-whatif','supported',0.990,'OPUS Terminal explicitly provides operation simulation for task workload and yard location using automated planning information, including workload estimation by time, block and equipment.','https://www.cyberlogitec.com/en/sub/solution/port/opus_terminal.php'),
('tos-forecasting-demand','partially_supported',0.950,'OPUS Terminal simulation estimates future workload by time, block and equipment, but broader container-volume, labor or resource-demand forecasting is not established; AI prediction functions are documented separately in OPUS DigiPort.','https://www.cyberlogitec.com/en/sub/solution/port/opus_digiport.php'),
('tos-scalability-throughput','supported',0.990,'CyberLogitec states OPUS Terminal has verified operational performance in a mega-size fully automated terminal of approximately 10 million TEU annual volume.','https://www.cyberlogitec.com/en/sub/solution/port/opus_terminal.php');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT @opus,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat142_facts f
JOIN capabilities c ON c.slug=f.capability_slug
WHERE @opus IS NOT NULL
ON DUPLICATE KEY UPDATE
  support_status=VALUES(support_status),
  limitations=VALUES(limitations),
  confidence_score=VALUES(confidence_score),
  last_verified_at=NOW();

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party CyberLogitec evidence supporting this OPUS Terminal depth status and scope boundary.'
FROM cat142_facts f
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=@opus AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=@opus AND e.source_url=f.source_url;

UPDATE products SET last_reviewed_at=NOW() WHERE id=@opus;

COMMIT;
