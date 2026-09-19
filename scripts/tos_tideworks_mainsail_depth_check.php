<?php
declare(strict_types=1);

$root=dirname(__DIR__);
$sql=(string)@file_get_contents($root.'/db/mysql/145_tos_tideworks_mainsail_depth_evidence.sql');
$errors=[];
if($sql===''){fwrite(STDERR,"Missing migration 145\n");exit(1);}

$expected=[
    ['tos-vessel-call-management','supported','0.980'],
    ['tos-berth-window-scheduling','partially_supported','0.980'],
    ['tos-stowage-bay-planning','partially_supported','0.990'],
    ['tos-discharge-load-sequencing','partially_supported','0.990'],
    ['tos-quay-work-queues','partially_supported','0.960'],
    ['tos-yard-strategy-rules','partially_supported','0.980'],
    ['tos-block-allocation','partially_supported','0.980'],
    ['tos-auto-decking-grounding','partially_supported','0.980'],
    ['tos-rehandle-minimization','partially_supported','0.980'],
    ['tos-yard-inventory-reconciliation','supported','0.980'],
    ['tos-gate-lane-automation','partially_supported','0.990'],
    ['tos-truck-turntime-queues','partially_supported','0.960'],
    ['tos-train-schedule-management','partially_supported','0.970'],
    ['tos-rail-load-discharge-planning','partially_supported','0.980'],
    ['tos-rtg-rmg-dispatch','partially_supported','0.970'],
    ['tos-tt-straddle-dispatch','partially_supported','0.970'],
    ['tos-vmt-mobile-work-instructions','partially_supported','0.980'],
    ['tos-equipment-position-tracking','partially_supported','0.970'],
    ['tos-job-pooling-optimization','partially_supported','0.990'],
    ['tos-rest-api-integration','supported','0.990'],
    ['tos-pcs-customs-integration','partially_supported','0.980'],
    ['tos-ocr-gate-system-integration','supported','0.990'],
    ['tos-erp-finance-integration','partially_supported','0.960'],
    ['tos-billing-financial','supported','0.990'],
    ['tos-storage-tariff-billing','supported','0.990'],
    ['tos-customer-self-service','partially_supported','0.990'],
    ['tos-shift-dashboard','partially_supported','0.950'],
    ['tos-productivity-kpis','supported','0.980'],
    ['tos-rbac-sso','partially_supported','0.980'],
    ['tos-scalability-throughput','partially_supported','0.970']
];
if(count($expected)!==30)$errors[]='Expected exactly 30 reviewed Tideworks Mainsail depth facts';
foreach($expected as [$capability,$status,$confidence]){
    $needle="'{$capability}','{$status}',{$confidence}";
    if(strpos($sql,$needle)===false)$errors[]="Missing Mainsail depth fact: {$needle}";
}

foreach(['kaleris-n4-tos','rbs-tops-expert','cyberlogitec-opus-terminal','total-soft-bank-catos','cargoes-tos-plus-zodiac','navis-mixed-cargo-tos'] as $other){
    if(strpos($sql,"'{$other}'")!==false)$errors[]="Mainsail evidence pass must not modify another TOS product: {$other}";
}
if(substr_count($sql,"'tideworks-mainsail'")!==2)$errors[]='Mainsail product scope changed unexpectedly';

$allowed=['tideworks.com','www.tideworks.com'];
preg_match_all('#https://[^\s\'\"]+#',$sql,$matches);
foreach(array_unique($matches[0]??[]) as $url){
    $url=rtrim($url,');,');
    $host=strtolower((string)parse_url($url,PHP_URL_HOST));
    if($host===''||!in_array($host,$allowed,true))$errors[]="Unapproved Tideworks evidence host: {$host}";
}

foreach([
    'companion-product capability',
    'companion planning system',
    'separate companion gate-operations system',
    'separate equipment-control companion product',
    'Forecast is a separate companion customer-service portal',
    'managed EDI',
    'customs integration is not separately established',
    'SSO and specific enterprise identity-provider standards are not established',
    'does not publish a universal Mainsail TEU ceiling',
    'Native Android and iOS applications are not inferred'
] as $phrase){
    if(strpos($sql,$phrase)===false)$errors[]="Missing Mainsail scope boundary: {$phrase}";
}

if(strpos($sql,"pma.platform='mobile_web'")===false)$errors[]='Mainsail responsive browser evidence must promote mobile_web specifically';
if(strpos($sql,"pma.scope_status='limited'")===false)$errors[]='Mainsail mobile web scope must remain limited unless feature parity is verified';
if(strpos($sql,"pma.evidence_type='vendor_documentation'")===false)$errors[]='Mainsail mobile web must retain vendor-documentation evidence';
foreach(["pma.platform='android'","pma.platform='ios'","'official_app_store'"] as $native){
    if(strpos($sql,$native)!==false)$errors[]="Mainsail depth pass must not infer native mobile support: {$native}";
}

foreach(['g2.com','capterra','consultation_recommendations','recommendation_rank','Scoring::','overall_score','fit_score','popularity_score','sponsored_rank'] as $bad){
    if(stripos($sql,$bad)!==false)$errors[]="Mainsail depth migration contains prohibited source/ranking coupling: {$bad}";
}
foreach(["'tos-codeco-coarri'","'tos-coparn-coprar'","'tos-movins-baplie-messaging'","'tos-vgm-weight-control'","'tos-dg-segregation'"] as $unsupportedPromotion){
    if(strpos($sql,$unsupportedPromotion)!==false)$errors[]="Mainsail depth pass must not infer unsupported protocol/compliance capability: {$unsupportedPromotion}";
}

if(strpos($sql,'product_capability_evidence')===false)$errors[]='Mainsail depth facts must retain evidence links';
if(strpos($sql,'not_yet_verified')===false)$errors[]='Migration must preserve the Unknown != Unsupported boundary';

if($errors){
    fwrite(STDERR,"Tideworks Mainsail depth check failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}
echo "Tideworks Mainsail depth contract passed: 30 first-party-evidenced facts, explicit companion-product boundaries, responsive mobile-web evidence and ranking neutrality.\n";
