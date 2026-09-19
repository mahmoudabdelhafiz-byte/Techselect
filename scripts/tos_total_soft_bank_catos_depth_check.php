<?php
declare(strict_types=1);

$root=dirname(__DIR__);
$sql=(string)@file_get_contents($root.'/db/mysql/144_tos_total_soft_bank_catos_depth_evidence.sql');
$errors=[];
if($sql===''){fwrite(STDERR,"Missing migration 144\n");exit(1);}

$expected=[
    ['tos-berth-window-scheduling','partially_supported','0.960'],
    ['tos-stowage-bay-planning','partially_supported','0.980'],
    ['tos-discharge-load-sequencing','supported','0.990'],
    ['tos-vessel-restow-rehandle','supported','0.990'],
    ['tos-quay-work-queues','partially_supported','0.950'],
    ['tos-yard-strategy-rules','supported','0.990'],
    ['tos-block-allocation','supported','0.980'],
    ['tos-auto-decking-grounding','partially_supported','0.970'],
    ['tos-housekeeping-remarshalling','supported','0.990'],
    ['tos-rehandle-minimization','supported','0.990'],
    ['tos-empty-container-management','partially_supported','0.940'],
    ['tos-yard-inventory-reconciliation','supported','0.990'],
    ['tos-yard-density-capacity','partially_supported','0.960'],
    ['tos-ocr-anpr-gate','partially_supported','0.970'],
    ['tos-gate-lane-automation','partially_supported','0.960'],
    ['tos-train-schedule-management','partially_supported','0.960'],
    ['tos-rail-load-discharge-planning','partially_supported','0.970'],
    ['tos-rail-crane-work-queues','partially_supported','0.950'],
    ['tos-rtg-rmg-dispatch','supported','0.990'],
    ['tos-tt-straddle-dispatch','supported','0.990'],
    ['tos-agv-asc-automation','supported','0.990'],
    ['tos-equipment-position-tracking','partially_supported','0.970'],
    ['tos-job-pooling-optimization','supported','0.990'],
    ['tos-reefer-temperature-alarms','partially_supported','0.960'],
    ['tos-pcs-customs-integration','supported','0.990'],
    ['tos-ocr-gate-system-integration','supported','0.990'],
    ['tos-reefer-system-integration','supported','0.990'],
    ['tos-customer-self-service','partially_supported','0.930'],
    ['tos-shift-dashboard','partially_supported','0.970'],
    ['tos-productivity-kpis','supported','0.990'],
    ['tos-simulation-whatif','partially_supported','0.960'],
    ['tos-multi-terminal','partially_supported','0.940'],
    ['tos-rbac-sso','partially_supported','0.990'],
    ['tos-scalability-throughput','supported','0.990']
];
if(count($expected)!==34)$errors[]='Expected exactly 34 reviewed Total Soft Bank CATOS depth facts';
foreach($expected as [$capability,$status,$confidence]){
    $needle="'{$capability}','{$status}',{$confidence}";
    if(strpos($sql,$needle)===false)$errors[]="Missing CATOS depth fact: {$needle}";
}

foreach(['kaleris-n4-tos','tideworks-mainsail','rbs-tops-expert','cyberlogitec-opus-terminal','cargoes-tos-plus-zodiac','navis-mixed-cargo-tos'] as $other){
    if(strpos($sql,"'{$other}'")!==false)$errors[]="CATOS evidence pass must not modify another TOS product: {$other}";
}
if(substr_count($sql,"'total-soft-bank-catos'")!==1)$errors[]='CATOS product scope changed unexpectedly';

$allowed=['tsb.co.kr','www.tsb.co.kr'];
preg_match_all('#https://[^\s\'\"]+#',$sql,$matches);
foreach(array_unique($matches[0]??[]) as $url){
    $url=rtrim($url,');,');
    $host=strtolower((string)parse_url($url,PHP_URL_HOST));
    if($host===''||!in_array($host,$allowed,true))$errors[]="Unapproved Total Soft Bank evidence host: {$host}";
}

foreach([
    'does not separately establish berth-window conflict handling',
    'does not separately enumerate all bay/deck/hatch stowage controls',
    'does not use explicit decking/grounding terminology',
    'does not establish full empty-container inventory',
    'ANPR is not separately stated',
    'kiosk/barrier/scale lane orchestration is not enumerated',
    'detailed wagon-level load/discharge sequencing is not separately established',
    'exact positioning technology and entitlement depend on the implementation',
    'does not establish that CATOS itself provides native temperature sensing',
    'CATOS DT functions are not assumed as universal base CATOS entitlement',
    'does not establish centralized multi-terminal administration',
    'does not separately establish the full RBAC model',
    'Generic integration references are not converted into unsupported native-protocol claims'
] as $phrase){
    if(strpos($sql,$phrase)===false)$errors[]="Missing CATOS scope boundary: {$phrase}";
}

foreach(['g2.com','capterra','consultation_recommendations','recommendation_rank','Scoring::','overall_score','fit_score','popularity_score','sponsored_rank'] as $bad){
    if(stripos($sql,$bad)!==false)$errors[]="CATOS depth migration contains prohibited source/ranking coupling: {$bad}";
}
foreach(["'public-saas'","'cloud-only'","'mobile_web'","'android'","'ios'","'tos-codeco-coarri'","'tos-coparn-coprar'","'tos-movins-baplie-messaging'","'tos-vgm-weight-control'","'tos-dg-segregation'","'tos-rest-api-integration'"] as $unsupportedPromotion){
    if(strpos($sql,$unsupportedPromotion)!==false)$errors[]="CATOS depth pass must not infer unsupported deployment/mobile/protocol capability: {$unsupportedPromotion}";
}

if(strpos($sql,'product_capability_evidence')===false)$errors[]='CATOS depth facts must retain evidence links';
if(strpos($sql,'not_yet_verified')===false)$errors[]='Migration must preserve the Unknown != Unsupported boundary';

if($errors){
    fwrite(STDERR,"Total Soft Bank CATOS depth check failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}
echo "Total Soft Bank CATOS depth contract passed: 34 first-party-evidenced granular facts, explicit integration/Digital Twin boundaries and ranking neutrality.\n";
