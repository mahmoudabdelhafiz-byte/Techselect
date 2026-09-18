<?php
declare(strict_types=1);

$root=dirname(__DIR__);
$sql=(string)@file_get_contents($root.'/db/mysql/142_tos_cyberlogitec_opus_depth_evidence.sql');
$errors=[];

if($sql===''){fwrite(STDERR,"Missing migration 142\n");exit(1);}

$expected=[
    ['tos-berth-window-scheduling','partially_supported','0.970'],
    ['tos-stowage-bay-planning','partially_supported','0.960'],
    ['tos-quay-work-queues','partially_supported','0.960'],
    ['tos-yard-strategy-rules','partially_supported','0.970'],
    ['tos-block-allocation','partially_supported','0.950'],
    ['tos-yard-density-capacity','partially_supported','0.950'],
    ['tos-ocr-anpr-gate','partially_supported','0.960'],
    ['tos-gate-lane-automation','partially_supported','0.960'],
    ['tos-rail-load-discharge-planning','partially_supported','0.970'],
    ['tos-qc-work-queues','partially_supported','0.960'],
    ['tos-rtg-rmg-dispatch','partially_supported','0.970'],
    ['tos-tt-straddle-dispatch','partially_supported','0.950'],
    ['tos-agv-asc-automation','supported','0.990'],
    ['tos-equipment-position-tracking','partially_supported','0.960'],
    ['tos-job-pooling-optimization','partially_supported','0.980'],
    ['tos-pcs-customs-integration','partially_supported','0.940'],
    ['tos-carrier-booking-integration','partially_supported','0.940'],
    ['tos-ocr-gate-system-integration','supported','0.970'],
    ['tos-productivity-kpis','partially_supported','0.960'],
    ['tos-simulation-whatif','supported','0.990'],
    ['tos-forecasting-demand','partially_supported','0.950'],
    ['tos-scalability-throughput','supported','0.990']
];
if(count($expected)!==22)$errors[]='Expected exactly 22 reviewed OPUS Terminal depth facts';

foreach($expected as [$capability,$status,$confidence]){
    $needle="'{$capability}','{$status}',{$confidence}";
    if(strpos($sql,$needle)===false)$errors[]="Missing OPUS depth fact: {$needle}";
}

foreach(['kaleris-n4-tos','tideworks-mainsail','rbs-tops-expert','total-soft-bank-catos','cargoes-tos-plus-zodiac','navis-mixed-cargo-tos'] as $other){
    if(strpos($sql,"'{$other}'")!==false)$errors[]="OPUS evidence pass must not modify another TOS product: {$other}";
}
if(substr_count($sql,"'cyberlogitec-opus-terminal'")!==1)$errors[]='OPUS product scope changed unexpectedly';

$allowed=['cyberlogitec.com','www.cyberlogitec.com'];
preg_match_all('#https://[^\s\'\"]+#',$sql,$matches);
foreach(array_unique($matches[0]??[]) as $url){
    $url=rtrim($url,');,');
    $host=strtolower((string)parse_url($url,PHP_URL_HOST));
    if($host===''||!in_array($host,$allowed,true))$errors[]="Unapproved CyberLogitec evidence host: {$host}";
}

foreach([
    'does not establish a dedicated berth-window scheduling workflow',
    'exact bay-position and stowage-rule depth is not separately established',
    'TLC module entitlement is not assumed as universal base OPUS Terminal entitlement',
    'straddle-carrier-specific dispatch is not established',
    'separate OPUS DigiPort product',
    'OPUS Terminal M cloud/multi-purpose claims are not promoted onto OPUS Terminal',
    'booking, release and carrier-message transaction depth is not enumerated',
    'ANPR scope and the distinction between native recognition and integrated subsystems are not established',
    'broader container-volume, labor or resource-demand forecasting is not established'
] as $phrase){
    if(strpos($sql,$phrase)===false)$errors[]="Missing OPUS scope boundary: {$phrase}";
}

foreach(['g2.com','capterra','consultation_recommendations','recommendation_rank','Scoring::','overall_score','fit_score','popularity_score','sponsored_rank'] as $bad){
    if(stripos($sql,$bad)!==false)$errors[]="OPUS depth migration contains prohibited source/ranking coupling: {$bad}";
}
foreach(["'public-saas'","'cloud-only'","'mobile_web'","'android'","'ios'"] as $unsupportedPromotion){
    if(strpos($sql,$unsupportedPromotion)!==false)$errors[]="OPUS depth pass must not infer deployment/mobile status: {$unsupportedPromotion}";
}
if(strpos($sql,'product_capability_evidence')===false)$errors[]='OPUS depth facts must retain evidence links';
if(strpos($sql,'not_yet_verified')===false)$errors[]='Migration must preserve the Unknown != Unsupported boundary';

if($errors){
    fwrite(STDERR,"CyberLogitec OPUS Terminal depth check failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}
echo "CyberLogitec OPUS Terminal depth contract passed: 22 first-party-evidenced granular facts, explicit TLC/DigiPort/Terminal M boundaries and ranking neutrality.\n";
