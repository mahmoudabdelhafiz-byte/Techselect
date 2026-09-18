<?php
declare(strict_types=1);

$root=dirname(__DIR__);
$sql=(string)@file_get_contents($root.'/db/mysql/143_tos_rbs_tops_expert_depth_evidence.sql');
$errors=[];
if($sql===''){fwrite(STDERR,"Missing migration 143\n");exit(1);}

$expected=[
    ['tos-berth-window-scheduling','partially_supported','0.980'],
    ['tos-vessel-call-management','supported','0.980'],
    ['tos-stowage-bay-planning','partially_supported','0.970'],
    ['tos-discharge-load-sequencing','partially_supported','0.950'],
    ['tos-quay-crane-split-planning','partially_supported','0.960'],
    ['tos-quay-work-queues','partially_supported','0.950'],
    ['tos-yard-strategy-rules','supported','0.990'],
    ['tos-block-allocation','partially_supported','0.960'],
    ['tos-auto-decking-grounding','partially_supported','0.960'],
    ['tos-housekeeping-remarshalling','partially_supported','0.950'],
    ['tos-rehandle-minimization','supported','0.990'],
    ['tos-truck-appointment-integration','partially_supported','0.990'],
    ['tos-pre-advice-booking','partially_supported','0.960'],
    ['tos-ocr-anpr-gate','partially_supported','0.970'],
    ['tos-driver-id-authentication','partially_supported','0.940'],
    ['tos-gate-lane-automation','partially_supported','0.980'],
    ['tos-train-schedule-management','supported','0.980'],
    ['tos-rail-yard-inventory','partially_supported','0.950'],
    ['tos-rail-load-discharge-planning','supported','0.980'],
    ['tos-rail-crane-work-queues','partially_supported','0.940'],
    ['tos-qc-work-queues','partially_supported','0.950'],
    ['tos-rtg-rmg-dispatch','partially_supported','0.970'],
    ['tos-tt-straddle-dispatch','partially_supported','0.960'],
    ['tos-agv-asc-automation','supported','0.990'],
    ['tos-equipment-position-tracking','partially_supported','0.980'],
    ['tos-job-pooling-optimization','supported','0.990'],
    ['tos-reefer-temperature-alarms','partially_supported','0.970'],
    ['tos-rest-api-integration','partially_supported','0.990'],
    ['tos-ocr-gate-system-integration','partially_supported','0.980'],
    ['tos-reefer-system-integration','partially_supported','0.980'],
    ['tos-erp-finance-integration','partially_supported','0.970'],
    ['tos-storage-tariff-billing','partially_supported','0.970'],
    ['tos-shift-dashboard','partially_supported','0.960'],
    ['tos-productivity-kpis','partially_supported','0.980'],
    ['tos-forecasting-demand','partially_supported','0.980'],
    ['tos-cloud-onprem-flexibility','supported','0.990'],
    ['tos-rbac-sso','partially_supported','0.940'],
    ['tos-scalability-throughput','supported','0.980']
];
if(count($expected)!==38)$errors[]='Expected exactly 38 reviewed RBS TOPS Expert depth facts';
foreach($expected as [$capability,$status,$confidence]){
    $needle="'{$capability}','{$status}',{$confidence}";
    if(strpos($sql,$needle)===false)$errors[]="Missing RBS TOPS Expert depth fact: {$needle}";
}

foreach(['kaleris-n4-tos','tideworks-mainsail','cyberlogitec-opus-terminal','total-soft-bank-catos','cargoes-tos-plus-zodiac','navis-mixed-cargo-tos'] as $other){
    if(strpos($sql,"'{$other}'")!==false)$errors[]="RBS evidence pass must not modify another TOS product: {$other}";
}
if(substr_count($sql,"'rbs-tops-expert'")!==1)$errors[]='RBS TOPS Expert product scope changed unexpectedly';

$allowed=['rbs-tops.com','www.rbs-tops.com','rbs-emea.com','www.rbs-emea.com'];
preg_match_all('#https://[^\s\'\"]+#',$sql,$matches);
foreach(array_unique($matches[0]??[]) as $url){
    $url=rtrim($url,');,');
    $host=strtolower((string)parse_url($url,PHP_URL_HOST));
    if($host===''||!in_array($host,$allowed,true))$errors[]="Unapproved RBS evidence host: {$host}";
}

foreach([
    'does not separately establish berth-window conflict rules',
    'detailed bay-position, hatch, deck and stowage-constraint functions are not separately enumerated',
    'Truck Appointment is a named TOPS Expert additional module',
    'ANPR is not separately stated',
    'GOS and external gate components remain module/integration boundaries',
    'straddle-carrier-specific dispatch is not explicitly established',
    'DGPS and related tracking components are named modules',
    'REST specifically is not claimed',
    'does not establish universal ERP connectors',
    'Billing is a named TOPS/TOPO special module',
    'KPI dashboard entitlement remains a package/component boundary',
    'does not establish SSO',
    'no universal TEU ceiling is published'
] as $phrase){
    if(strpos($sql,$phrase)===false)$errors[]="Missing RBS scope boundary: {$phrase}";
}

foreach(['g2.com','capterra','consultation_recommendations','recommendation_rank','Scoring::','overall_score','fit_score','popularity_score','sponsored_rank'] as $bad){
    if(stripos($sql,$bad)!==false)$errors[]="RBS depth migration contains prohibited source/ranking coupling: {$bad}";
}
foreach(["'mobile_web'","'android'","'ios'"] as $unsupportedPromotion){
    if(strpos($sql,$unsupportedPromotion)!==false)$errors[]="RBS depth pass must not infer mobile platform status: {$unsupportedPromotion}";
}

if(strpos($sql,'product_capability_evidence')===false)$errors[]='RBS depth facts must retain evidence links';
if(strpos($sql,'not_yet_verified')===false)$errors[]='Migration must preserve the Unknown != Unsupported boundary';

if($errors){
    fwrite(STDERR,"RBS TOPS Expert depth check failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}
echo "RBS TOPS Expert depth contract passed: 38 first-party-evidenced granular facts, explicit component/module boundaries and ranking neutrality.\n";
