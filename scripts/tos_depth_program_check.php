<?php
declare(strict_types=1);

$root=dirname(__DIR__);
$foundation=(string)@file_get_contents($root.'/db/mysql/117_terminal_operating_system_catalog.sql');
$depth=(string)@file_get_contents($root.'/db/mysql/139_tos_depth_taxonomy_foundation.sql');
$program=(string)@file_get_contents($root.'/docs/TOS_DEPTH_PROGRAM.md');
$errors=[];

if($foundation==='')$errors[]='Missing TOS foundation migration 117';
if($depth==='')$errors[]='Missing TOS depth migration 139';
if($program==='')$errors[]='Missing TOS Depth Program documentation';

$modules=['tos-vessel-berth','tos-yard-stack','tos-gate-landside','tos-rail-intermodal','tos-equipment-automation','tos-cargo-compliance','tos-integration-data','tos-business-analytics','tos-platform-resilience'];
$granular=['tos-berth-window-scheduling','tos-vessel-call-management','tos-baplie-import-export','tos-stowage-bay-planning','tos-discharge-load-sequencing','tos-quay-crane-split-planning','tos-quay-work-queues','tos-vessel-restow-rehandle','tos-twin-tandem-lift-planning','tos-vessel-plan-collaboration','tos-yard-strategy-rules','tos-block-allocation','tos-auto-decking-grounding','tos-import-export-prestack','tos-housekeeping-remarshalling','tos-rehandle-minimization','tos-empty-container-management','tos-yard-inventory-reconciliation','tos-yard-density-capacity','tos-yard-holds-exceptions','tos-truck-appointment-integration','tos-pre-advice-booking','tos-ocr-anpr-gate','tos-driver-id-authentication','tos-gate-lane-automation','tos-eir-interchange','tos-weighbridge-vgm','tos-gate-customs-holds','tos-pre-gate-outgate-validation','tos-truck-turntime-queues','tos-train-schedule-management','tos-wagon-consist-planning','tos-rail-yard-inventory','tos-rail-load-discharge-planning','tos-rail-crane-work-queues','tos-rail-interchange-events','tos-qc-work-queues','tos-rtg-rmg-dispatch','tos-tt-straddle-dispatch','tos-agv-asc-automation','tos-vmt-mobile-work-instructions','tos-equipment-position-tracking','tos-equipment-status-downtime','tos-job-pooling-optimization','tos-reefer-plug-monitoring','tos-reefer-temperature-alarms','tos-dg-segregation','tos-oog-special-equipment','tos-damage-inspection','tos-vgm-weight-control','tos-codeco-coarri','tos-coparn-coprar','tos-movins-baplie-messaging','tos-rest-api-integration','tos-event-webhook-streaming','tos-pcs-customs-integration','tos-carrier-booking-integration','tos-ocr-gate-system-integration','tos-reefer-system-integration','tos-erp-finance-integration','tos-storage-tariff-billing','tos-customer-self-service','tos-shift-dashboard','tos-productivity-kpis','tos-simulation-whatif','tos-forecasting-demand','tos-audit-operational-history','tos-high-availability','tos-disaster-recovery','tos-bcp-offline-mode','tos-multi-terminal','tos-cloud-onprem-flexibility','tos-rbac-sso','tos-security-audit-logging','tos-scalability-throughput'];
$umbrella=['tos-vessel-berth-planning','tos-yard-planning-inventory','tos-gate-truck-operations','tos-rail-operations','tos-equipment-dispatch-control','tos-automation-ecs','tos-edi-api-integrations','tos-kpi-visibility','tos-billing-financial','tos-special-cargo-controls'];
$products=['kaleris-n4-tos','tideworks-mainsail','rbs-tops-expert','cyberlogitec-opus-terminal','total-soft-bank-catos'];

if(count($granular)!==75)$errors[]='TOS depth contract must define exactly 75 new granular criteria';
if(count(array_unique(array_merge($granular,$umbrella)))!==85)$errors[]='TOS depth taxonomy must total 85 unique criteria';

foreach($modules as $slug){
    if(strpos($depth,"'{$slug}'")===false)$errors[]="Missing TOS depth module {$slug}";
}
foreach($granular as $slug){
    if(strpos($depth,"'{$slug}'")===false)$errors[]="Missing granular TOS criterion {$slug}";
}
foreach($umbrella as $slug){
    if(strpos($foundation,"'{$slug}'")===false)$errors[]="Original TOS criterion missing from migration 117: {$slug}";
}
foreach($products as $slug){
    if(strpos($depth,"'{$slug}'")===false)$errors[]="TOS product is not included in unknown seeding: {$slug}";
}

foreach([
    "SET is_active=0",
    "'tos-planning-execution','tos-automation-integration'",
    "INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)",
    "'not_yet_verified',0",
    'Unknown != Unsupported'
] as $needle){
    if(strpos($depth,$needle)===false)$errors[]="Missing TOS depth invariant: {$needle}";
}

foreach(['evidence_sources','product_capability_evidence','vendor_documentation'] as $needle){
    if(strpos($depth,$needle)!==false)$errors[]="Taxonomy foundation must not fabricate vendor evidence: {$needle}";
}
foreach(["'supported'","'partially_supported'","'unsupported'"] as $status){
    if(strpos($depth,$status)!==false)$errors[]="Taxonomy foundation must not promote product support status: {$status}";
}
foreach(['g2.com','capterra','consultation_recommendations','recommendation_rank','Scoring::','overall_score','fit_score','popularity_score','sponsored_rank'] as $bad){
    if(stripos($depth,$bad)!==false)$errors[]="TOS depth migration contains prohibited ranking/source coupling: {$bad}";
}

if(strpos($program,'10 broad criteria to 85 buyer-selectable criteria')===false)$errors[]='Program document must state the 10-to-85 depth objective';
if(strpos($program,'Taxonomy depth is not evidence depth')===false)$errors[]='Program document must preserve taxonomy/evidence separation';
if(strpos($program,'Domain expertise defines the requirement taxonomy; evidence determines product capability status.')===false)$errors[]='Program document must preserve the domain-expertise/evidence boundary';

if($errors){
    fwrite(STDERR,"TOS Depth Program check failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}
echo "TOS Depth Program contract passed: 85 buyer criteria, 9 operational modules, explicit unknown seeding, no fabricated evidence and ranking neutrality.\n";
