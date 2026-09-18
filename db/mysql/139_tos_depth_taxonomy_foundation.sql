-- TechSelectAI TOS Depth Program - taxonomy foundation.
-- Expands Terminal Operating Systems from 10 broad criteria to 85 buyer-selectable criteria.
-- Existing 10 capability slugs are preserved for backward compatibility and moved into clearer operational modules.
-- The 75 new granular capabilities are intentionally seeded as not_yet_verified for all five TOS products.
-- Evidence will be promoted vendor-by-vendor in later migrations. Unknown != Unsupported.
-- No Fit Score weights, recommendation ranking, review weighting, popularity or commercial placement logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

SET @tos_cat=(SELECT id FROM categories WHERE slug='terminal-operating-systems' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@tos_cat,'Vessel & Berth Planning','tos-vessel-berth','Vessel calls, berth windows, stowage, quay planning and ship-side execution.',1),
(@tos_cat,'Yard Strategy & Inventory','tos-yard-stack','Yard strategy, stack allocation, inventory control, housekeeping and rehandle optimization.',1),
(@tos_cat,'Gate, Truck & Landside Operations','tos-gate-landside','Pre-advice, appointments, automated gate lanes, interchange, truck validation and landside flow.',1),
(@tos_cat,'Rail & Intermodal Operations','tos-rail-intermodal','Train, wagon, rail-yard, crane and intermodal interchange planning and execution.',1),
(@tos_cat,'Equipment Dispatch & Automation','tos-equipment-automation','CHE work queues, dispatch, positioning, VMT workflows, job optimization and automated-equipment integration.',1),
(@tos_cat,'Reefer, DG & Special Cargo','tos-cargo-compliance','Reefer, dangerous goods, OOG, inspection, customs and weight-control workflows.',1),
(@tos_cat,'Integration, Data & Ecosystem','tos-integration-data','Carrier EDI, APIs, event integration, PCS/customs, OCR, reefer, finance and external-system connectivity.',1),
(@tos_cat,'Billing, Analytics & Operational Control','tos-business-analytics','Billing, customer services, shift visibility, productivity, simulation, forecasting and operational history.',1),
(@tos_cat,'Platform Architecture, Resilience & Security','tos-platform-resilience','High availability, disaster recovery, BCP, deployment flexibility, access control, auditability and scale.',1)
ON DUPLICATE KEY UPDATE name=VALUES(name),description=VALUES(description),is_active=1;

-- Re-home the original broad criteria into the specialist operational taxonomy.
UPDATE capabilities c JOIN modules m ON m.category_id=@tos_cat AND m.slug='tos-vessel-berth'
SET c.module_id=m.id WHERE c.slug='tos-vessel-berth-planning';
UPDATE capabilities c JOIN modules m ON m.category_id=@tos_cat AND m.slug='tos-yard-stack'
SET c.module_id=m.id WHERE c.slug='tos-yard-planning-inventory';
UPDATE capabilities c JOIN modules m ON m.category_id=@tos_cat AND m.slug='tos-gate-landside'
SET c.module_id=m.id WHERE c.slug='tos-gate-truck-operations';
UPDATE capabilities c JOIN modules m ON m.category_id=@tos_cat AND m.slug='tos-rail-intermodal'
SET c.module_id=m.id WHERE c.slug='tos-rail-operations';
UPDATE capabilities c JOIN modules m ON m.category_id=@tos_cat AND m.slug='tos-equipment-automation'
SET c.module_id=m.id WHERE c.slug IN('tos-equipment-dispatch-control','tos-automation-ecs');
UPDATE capabilities c JOIN modules m ON m.category_id=@tos_cat AND m.slug='tos-cargo-compliance'
SET c.module_id=m.id WHERE c.slug='tos-special-cargo-controls';
UPDATE capabilities c JOIN modules m ON m.category_id=@tos_cat AND m.slug='tos-integration-data'
SET c.module_id=m.id WHERE c.slug='tos-edi-api-integrations';
UPDATE capabilities c JOIN modules m ON m.category_id=@tos_cat AND m.slug='tos-business-analytics'
SET c.module_id=m.id WHERE c.slug IN('tos-kpi-visibility','tos-billing-financial');

-- The old two broad presentation modules become empty after the re-home.
UPDATE modules
SET is_active=0
WHERE category_id=@tos_cat AND slug IN('tos-planning-execution','tos-automation-integration');

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.sec,1
FROM modules m JOIN (
 SELECT  'tos-vessel-berth' module_slug,'Berth window & berth allocation scheduling' name,'tos-berth-window-scheduling' slug,'Plan berth windows, berth positions, arrival/departure timing and berth conflicts for vessel calls.' description,0 sec UNION ALL
 SELECT  'tos-vessel-berth','Vessel call lifecycle management','tos-vessel-call-management','Maintain vessel-call operational data from pre-arrival through working, completion and departure.',0 UNION ALL
 SELECT  'tos-vessel-berth','BAPLIE import / export','tos-baplie-import-export','Import, validate, update or export BAPLIE bay-plan messages used for vessel planning and exchange.',0 UNION ALL
 SELECT  'tos-vessel-berth','Stowage & bay planning','tos-stowage-bay-planning','Plan container positions, bays, decks, holds and stowage constraints for vessel load and discharge operations.',0 UNION ALL
 SELECT  'tos-vessel-berth','Discharge / load sequencing','tos-discharge-load-sequencing','Sequence discharge and load work to coordinate quay operations, yard readiness and vessel constraints.',0 UNION ALL
 SELECT  'tos-vessel-berth','Quay crane split planning','tos-quay-crane-split-planning','Assign vessel work across quay cranes, crane ranges, bays or work areas and manage crane split plans.',0 UNION ALL
 SELECT  'tos-vessel-berth','Quay crane work queues','tos-quay-work-queues','Generate, prioritize and execute quay-crane work queues and move instructions.',0 UNION ALL
 SELECT  'tos-vessel-berth','Restow & vessel rehandle planning','tos-vessel-restow-rehandle','Plan and track restows, hatch-related moves and vessel rehandles required by the working sequence.',0 UNION ALL
 SELECT  'tos-vessel-berth','Twin / tandem lift planning','tos-twin-tandem-lift-planning','Plan or validate twin, tandem or multi-lift quay operations where equipment and stowage rules allow.',0 UNION ALL
 SELECT  'tos-vessel-berth','Carrier vessel-plan collaboration','tos-vessel-plan-collaboration','Exchange vessel plans, updates, approvals or planning data with shipping lines and external planners.',0 UNION ALL
 SELECT  'tos-yard-stack','Configurable yard strategy rules','tos-yard-strategy-rules','Configure yard rules for allocation, segregation, dwell, service priority, equipment type or operational strategy.',0 UNION ALL
 SELECT  'tos-yard-stack','Block / stack allocation planning','tos-block-allocation','Allocate containers to yard blocks, rows, bays, stacks or zones using operational and cargo constraints.',0 UNION ALL
 SELECT  'tos-yard-stack','Automated decking / grounding decisions','tos-auto-decking-grounding','Recommend or automate container grounding and decking positions based on configurable yard logic.',0 UNION ALL
 SELECT  'tos-yard-stack','Import / export / prestack segregation','tos-import-export-prestack','Separate and plan import, export, transshipment, prestack or service-specific yard inventories.',0 UNION ALL
 SELECT  'tos-yard-stack','Housekeeping & remarshalling planning','tos-housekeeping-remarshalling','Plan proactive yard housekeeping, remarshalling and reshuffles to prepare future work.',0 UNION ALL
 SELECT  'tos-yard-stack','Rehandle minimization','tos-rehandle-minimization','Optimize stack choices and move sequences to reduce unproductive container rehandles.',0 UNION ALL
 SELECT  'tos-yard-stack','Empty container inventory management','tos-empty-container-management','Manage empty-container inventory, locations, types, lines, releases and operational movement.',0 UNION ALL
 SELECT  'tos-yard-stack','Yard inventory reconciliation','tos-yard-inventory-reconciliation','Reconcile system inventory with physical yard locations, corrections, scans or operational confirmations.',0 UNION ALL
 SELECT  'tos-yard-stack','Yard density & capacity visibility','tos-yard-density-capacity','Monitor yard capacity, occupancy, density, block utilization and congestion by operational area.',0 UNION ALL
 SELECT  'tos-yard-stack','Yard holds & exception management','tos-yard-holds-exceptions','Apply and manage yard-level holds, exceptions, restrictions and operational release conditions.',0 UNION ALL
 SELECT  'tos-gate-landside','Truck appointment integration','tos-truck-appointment-integration','Integrate or coordinate truck appointment and time-slot information with terminal gate execution.',0 UNION ALL
 SELECT  'tos-gate-landside','Truck pre-advice & booking validation','tos-pre-advice-booking','Validate truck pre-advice, booking, release, container, visit and transaction data before gate processing.',0 UNION ALL
 SELECT  'tos-gate-landside','Gate OCR / ANPR integration','tos-ocr-anpr-gate','Use or integrate OCR, container recognition and ANPR data for automated or assisted gate processing.',0 UNION ALL
 SELECT  'tos-gate-landside','Driver identification & authorization','tos-driver-id-authentication','Identify and authorize drivers using configured identity, credential or access-control methods.',0 UNION ALL
 SELECT  'tos-gate-landside','Automated gate lane orchestration','tos-gate-lane-automation','Coordinate lane devices, kiosks, barriers, OCR, scales and transaction steps for automated gate lanes.',0 UNION ALL
 SELECT  'tos-gate-landside','Interchange / EIR processing','tos-eir-interchange','Create and manage equipment interchange, EIR or equivalent receipt/delivery transaction records.',0 UNION ALL
 SELECT  'tos-gate-landside','Weighbridge & VGM workflows','tos-weighbridge-vgm','Integrate weighing, gross-mass capture or VGM-related checks into applicable terminal transactions.',0 UNION ALL
 SELECT  'tos-gate-landside','Gate customs / line / terminal holds','tos-gate-customs-holds','Enforce customs, shipping-line, terminal or regulatory holds during receipt and delivery decisions.',0 UNION ALL
 SELECT  'tos-gate-landside','Pre-gate & out-gate validation','tos-pre-gate-outgate-validation','Validate transaction eligibility before gate entry and before final out-gate completion.',0 UNION ALL
 SELECT  'tos-gate-landside','Truck turn-time & queue monitoring','tos-truck-turntime-queues','Measure truck cycle time, lane queues, wait times and gate throughput for landside operations.',0 UNION ALL
 SELECT  'tos-rail-intermodal','Train schedule & service management','tos-train-schedule-management','Maintain train services, schedules, cutoffs, arrivals, departures and operational rail windows.',0 UNION ALL
 SELECT  'tos-rail-intermodal','Wagon / consist planning','tos-wagon-consist-planning','Plan wagon consists, slots, railcars and container assignments for rail loading and discharge.',0 UNION ALL
 SELECT  'tos-rail-intermodal','Rail-yard inventory visibility','tos-rail-yard-inventory','Track rail containers, wagons and rail-area inventory with operational location visibility.',0 UNION ALL
 SELECT  'tos-rail-intermodal','Rail load / discharge planning','tos-rail-load-discharge-planning','Plan rail discharge, loading and transfer sequences using train, yard and equipment constraints.',0 UNION ALL
 SELECT  'tos-rail-intermodal','Rail crane work queues','tos-rail-crane-work-queues','Generate and execute work queues for rail-mounted or rail-service handling equipment.',0 UNION ALL
 SELECT  'tos-rail-intermodal','Rail interchange events','tos-rail-interchange-events','Capture rail interchange, handoff, arrival, departure and related intermodal operational events.',0 UNION ALL
 SELECT  'tos-equipment-automation','Quay crane job execution','tos-qc-work-queues','Dispatch and execute quay-crane jobs and related move instructions from vessel plans.',0 UNION ALL
 SELECT  'tos-equipment-automation','RTG / RMG dispatch & work queues','tos-rtg-rmg-dispatch','Dispatch and sequence RTG/RMG work using yard priorities, equipment availability and move demand.',0 UNION ALL
 SELECT  'tos-equipment-automation','Terminal tractor / straddle dispatch','tos-tt-straddle-dispatch','Dispatch terminal tractors, straddle carriers or horizontal transport to operational jobs.',0 UNION ALL
 SELECT  'tos-equipment-automation','AGV / ASC automated-equipment integration','tos-agv-asc-automation','Coordinate jobs and status with automated guided vehicles, automated stacking cranes or comparable automated equipment.',0 UNION ALL
 SELECT  'tos-equipment-automation','VMT mobile work instructions','tos-vmt-mobile-work-instructions','Deliver work instructions, confirmations and exceptions to vehicle-mounted or operator mobile terminals.',0 UNION ALL
 SELECT  'tos-equipment-automation','Equipment position tracking','tos-equipment-position-tracking','Use equipment-position or location data to support dispatch, execution, confirmation or optimization.',0 UNION ALL
 SELECT  'tos-equipment-automation','Equipment status & downtime awareness','tos-equipment-status-downtime','Use equipment availability, status, downtime or maintenance-state information in operational execution.',0 UNION ALL
 SELECT  'tos-equipment-automation','Job pooling & dispatch optimization','tos-job-pooling-optimization','Pool, prioritize and optimize equipment jobs to reduce travel, delay and unproductive moves.',0 UNION ALL
 SELECT  'tos-cargo-compliance','Reefer plug / unplug workflow','tos-reefer-plug-monitoring','Track reefer plug, unplug, connection location, service status or related terminal reefer actions.',0 UNION ALL
 SELECT  'tos-cargo-compliance','Reefer temperature & alarm integration','tos-reefer-temperature-alarms','Receive, display or act on reefer temperature, sensor or alarm information from supported systems.',0 UNION ALL
 SELECT  'tos-cargo-compliance','Dangerous-goods segregation controls','tos-dg-segregation','Apply dangerous-goods class, segregation, location or handling restrictions in terminal planning and execution.',0 UNION ALL
 SELECT  'tos-cargo-compliance','OOG & special-equipment handling','tos-oog-special-equipment','Manage out-of-gauge, special-equipment or exceptional-dimension cargo requirements in terminal workflows.',0 UNION ALL
 SELECT  'tos-cargo-compliance','Damage & inspection workflow','tos-damage-inspection','Record inspections, damage condition, exceptions, photos or related operational cargo/equipment findings.',0 UNION ALL
 SELECT  'tos-cargo-compliance','Container weight / VGM control','tos-vgm-weight-control','Store, validate or use container gross weight and VGM data in operational planning and shipment handling.',0 UNION ALL
 SELECT  'tos-integration-data','CODECO / COARRI EDI messaging','tos-codeco-coarri','Exchange CODECO gate and COARRI vessel-operation messages or equivalent standardized carrier EDI.',0 UNION ALL
 SELECT  'tos-integration-data','COPARN / COPRAR EDI messaging','tos-coparn-coprar','Exchange COPARN booking/order and COPRAR load/discharge instruction messages or equivalent carrier EDI.',0 UNION ALL
 SELECT  'tos-integration-data','MOVINS / BAPLIE vessel messaging','tos-movins-baplie-messaging','Exchange MOVINS work instructions and BAPLIE vessel-plan messages in supported carrier workflows.',0 UNION ALL
 SELECT  'tos-integration-data','REST / web-service API integration','tos-rest-api-integration','Expose or consume documented APIs or web services for supported terminal business and operational integrations.',0 UNION ALL
 SELECT  'tos-integration-data','Event / webhook / streaming integration','tos-event-webhook-streaming','Publish or consume operational events through webhooks, messaging, event streams or comparable integration patterns.',0 UNION ALL
 SELECT  'tos-integration-data','PCS / customs / authority integration','tos-pcs-customs-integration','Integrate terminal transactions with port community systems, customs, port authorities or government platforms.',0 UNION ALL
 SELECT  'tos-integration-data','Carrier booking & release integration','tos-carrier-booking-integration','Integrate carrier bookings, releases, vessel data, container status or related shipping-line messages.',0 UNION ALL
 SELECT  'tos-integration-data','Gate / OCR subsystem integration','tos-ocr-gate-system-integration','Integrate external gate automation, OCR, ANPR, kiosk or access-control subsystems with TOS transactions.',0 UNION ALL
 SELECT  'tos-integration-data','Reefer monitoring system integration','tos-reefer-system-integration','Integrate external reefer-monitoring platforms, sensors or alarm systems with terminal operational records.',0 UNION ALL
 SELECT  'tos-integration-data','ERP / finance integration','tos-erp-finance-integration','Exchange customers, services, billable events, invoices or accounting data with ERP and finance systems.',0 UNION ALL
 SELECT  'tos-business-analytics','Storage, tariff & service billing','tos-storage-tariff-billing','Calculate or support storage, handling, service, tariff and event-based terminal charges.',0 UNION ALL
 SELECT  'tos-business-analytics','Customer self-service portal','tos-customer-self-service','Provide customers with approved self-service access to status, bookings, orders, documents, invoices or service requests.',0 UNION ALL
 SELECT  'tos-business-analytics','Shift / control-room dashboard','tos-shift-dashboard','Provide real-time operational dashboards for shift managers, planners or control-room teams.',0 UNION ALL
 SELECT  'tos-business-analytics','Productivity & equipment KPIs','tos-productivity-kpis','Measure vessel, crane, yard, gate, rail, equipment and labor productivity using terminal-operational data.',0 UNION ALL
 SELECT  'tos-business-analytics','Simulation / what-if analysis','tos-simulation-whatif','Model operational scenarios or test planning alternatives before execution.',0 UNION ALL
 SELECT  'tos-business-analytics','Volume / workload forecasting','tos-forecasting-demand','Forecast container volume, workload, resource demand, congestion or operational pressure from available planning data.',0 UNION ALL
 SELECT  'tos-business-analytics','Operational audit history','tos-audit-operational-history','Preserve traceable history of operational transactions, changes, user actions and execution events.',0 UNION ALL
 SELECT  'tos-platform-resilience','High availability architecture','tos-high-availability','Support redundant or clustered application/database architecture designed to reduce service interruption.',0 UNION ALL
 SELECT  'tos-platform-resilience','Disaster recovery & RPO/RTO controls','tos-disaster-recovery','Support documented disaster-recovery patterns, recovery procedures or RPO/RTO targets for terminal operations.',0 UNION ALL
 SELECT  'tos-platform-resilience','BCP / degraded or offline operations','tos-bcp-offline-mode','Provide documented continuity, degraded-mode, offline or fallback operating patterns for critical terminal workflows.',0 UNION ALL
 SELECT  'tos-platform-resilience','Multi-terminal / multi-site operation','tos-multi-terminal','Operate or centrally manage more than one terminal, facility or site while preserving operational separation.',0 UNION ALL
 SELECT  'tos-platform-resilience','Cloud / on-prem deployment flexibility','tos-cloud-onprem-flexibility','Offer documented deployment choices appropriate to enterprise terminal environments, such as cloud, on-premises or hybrid patterns.',0 UNION ALL
 SELECT  'tos-platform-resilience','RBAC / SSO / enterprise identity','tos-rbac-sso','Provide role-based access controls and enterprise authentication or SSO integration for operational and administrative users.',1 UNION ALL
 SELECT  'tos-platform-resilience','Security & administrative audit logging','tos-security-audit-logging','Record security-relevant, administrative or privileged-user activity for operational governance and investigation.',1 UNION ALL
 SELECT  'tos-platform-resilience','Throughput & scale for large terminals','tos-scalability-throughput','Support documented scaling patterns for high transaction, equipment, user, vessel or container volumes.',0
) x ON x.module_slug=m.slug
WHERE m.category_id=@tos_cat
ON DUPLICATE KEY UPDATE
  module_id=VALUES(module_id),
  name=VALUES(name),
  description=VALUES(description),
  is_security_related=VALUES(is_security_related),
  is_active=1;

-- Preserve the evidence-first model: every new granular criterion starts unknown
-- for each current TOS product until first-party vendor evidence is researched.
INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM products p
JOIN categories cat ON cat.id=p.category_id
JOIN modules m ON m.category_id=cat.id
JOIN capabilities cap ON cap.module_id=m.id
WHERE cat.id=@tos_cat
  AND p.slug IN('kaleris-n4-tos','tideworks-mainsail','rbs-tops-expert','cyberlogitec-opus-terminal','total-soft-bank-catos')
  AND m.slug IN('tos-vessel-berth','tos-yard-stack','tos-gate-landside','tos-rail-intermodal','tos-equipment-automation','tos-cargo-compliance','tos-integration-data','tos-business-analytics','tos-platform-resilience')
  AND NOT EXISTS(
    SELECT 1 FROM product_capabilities pc
    WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL
  );

COMMIT;
