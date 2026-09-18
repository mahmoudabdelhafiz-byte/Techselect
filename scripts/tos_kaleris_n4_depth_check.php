<?php
declare(strict_types=1);

$root=dirname(__DIR__);
$migration=$root.'/db/mysql/140_tos_kaleris_n4_depth_evidence.sql';
$sql=(string)@file_get_contents($migration);
$errors=[];

if($sql===''){fwrite(STDERR,"Missing migration 140\n");exit(1);}

$expected=[
    ['tos-berth-window-scheduling','partially_supported','0.990'],
    ['tos-stowage-bay-planning','partially_supported','0.990'],
    ['tos-quay-crane-split-planning','partially_supported','0.950'],
    ['tos-vessel-plan-collaboration','partially_supported','0.950'],
    ['tos-yard-strategy-rules','partially_supported','0.990'],
    ['tos-auto-decking-grounding','partially_supported','0.990'],
    ['tos-import-export-prestack','partially_supported','0.970'],
    ['tos-rehandle-minimization','partially_supported','0.990'],
    ['tos-yard-density-capacity','partially_supported','0.970'],
    ['tos-ocr-anpr-gate','partially_supported','0.960'],
    ['tos-gate-lane-automation','partially_supported','0.970'],
    ['tos-weighbridge-vgm','partially_supported','0.970'],
    ['tos-rtg-rmg-dispatch','partially_supported','0.990'],
    ['tos-tt-straddle-dispatch','partially_supported','0.980'],
    ['tos-vmt-mobile-work-instructions','partially_supported','0.980'],
    ['tos-equipment-position-tracking','supported','0.980'],
    ['tos-job-pooling-optimization','partially_supported','0.980'],
    ['tos-agv-asc-automation','supported','0.980'],
    ['tos-vgm-weight-control','partially_supported','0.970'],
    ['tos-rest-api-integration','supported','0.990'],
    ['tos-ocr-gate-system-integration','supported','0.980'],
    ['tos-storage-tariff-billing','partially_supported','0.970'],
    ['tos-customer-self-service','partially_supported','0.960'],
    ['tos-shift-dashboard','supported','0.980'],
    ['tos-productivity-kpis','supported','0.970'],
    ['tos-simulation-whatif','partially_supported','0.960'],
    ['tos-forecasting-demand','partially_supported','0.960'],
    ['tos-multi-terminal','supported','0.980'],
    ['tos-cloud-onprem-flexibility','supported','0.980'],
    ['tos-scalability-throughput','supported','0.990'],
    ['tos-special-cargo-controls','partially_supported','0.940']
];
if(count($expected)!==31)$errors[]='Expected exactly 31 reviewed Kaleris depth facts';

foreach($expected as [$capability,$status,$confidence]){
    $needle="'{$capability}','{$status}',{$confidence}";
    if(strpos($sql,$needle)===false)$errors[]="Missing Kaleris depth fact: {$needle}";
}

foreach(['tideworks-mainsail','rbs-tops-expert','cyberlogitec-opus-terminal','total-soft-bank-catos'] as $other){
    if(strpos($sql,"'{$other}'")!==false)$errors[]="Kaleris evidence pass must not modify another TOS product: {$other}";
}
if(substr_count($sql,"'kaleris-n4-tos'")!==1)$errors[]='Kaleris product scope changed unexpectedly';

$allowed=['kaleris.com','www.kaleris.com'];
preg_match_all('#https://[^\s\'\"]+#',$sql,$matches);
foreach(array_unique($matches[0]??[]) as $url){
    $url=rtrim($url,');,');
    $host=strtolower((string)parse_url($url,PHP_URL_HOST));
    if($host===''||!in_array($host,$allowed,true))$errors[]="Unapproved Kaleris evidence host: {$host}";
}

if(preg_match('/INSERT INTO cat140_sources VALUES\s*(.*?);\s*\n\s*INSERT INTO evidence_sources/is',$sql,$sm)){
    preg_match_all("/\\('(https:\/\/(?:''|[^'])+)'/", $sm[1], $sourceMatches);
    $registered=array_fill_keys($sourceMatches[1]??[],true);
    if(preg_match('/INSERT INTO cat140_facts VALUES\s*(.*?);\s*\n\s*INSERT INTO product_capabilities/is',$sql,$fm)){
        preg_match_all("/\\('(?:''|[^'])*','(?:''|[^'])*',[0-9.]+,'(?:''|[^'])*','(https:\/\/(?:''|[^'])+)'\\)/", $fm[1], $factMatches);
        foreach(array_unique($factMatches[1]??[]) as $url){
            if(!isset($registered[$url]))$errors[]="Unregistered Kaleris fact source: {$url}";
        }
    } else $errors[]='Could not parse cat140_facts block';
} else $errors[]='Could not parse cat140_sources block';

foreach([
    'optional/advanced planning module rather than universal base-N4 entitlement',
    'advanced/optional modules rather than assumed base-N4 entitlement',
    'integration, not proof that N4 itself is the native OCR/ANPR engine',
    'project-specific and should not be treated as universal native hardware control',
    'Universal weighbridge hardware/protocol coverage is not inferred',
    'Advanced Optimization continuously evaluates crane, truck and yard tasks',
    'packaging and portal scope are implementation-dependent',
    'does not establish universal storage/tariff configuration depth',
    'broader volume/resource-demand forecasting is not inferred',
    'does not yet establish full dangerous-goods, OOG and reefer-service control'
] as $phrase){
    if(strpos($sql,$phrase)===false)$errors[]="Missing Kaleris scope boundary: {$phrase}";
}

foreach(['g2.com','capterra','consultation_recommendations','recommendation_rank','Scoring::','overall_score','fit_score','popularity_score','sponsored_rank'] as $bad){
    if(stripos($sql,$bad)!==false)$errors[]="Kaleris depth migration contains prohibited source/ranking coupling: {$bad}";
}

if(strpos($sql,'product_capability_evidence')===false)$errors[]='Kaleris depth facts must retain evidence links';
if(strpos($sql,'not_yet_verified')===false)$errors[]='Migration must preserve the Unknown != Unsupported boundary in its scope comments';

if($errors){
    fwrite(STDERR,"Kaleris N4 TOS depth check failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}
echo "Kaleris N4 TOS depth contract passed: 31 first-party-evidenced granular facts, explicit optional-module/integration boundaries and ranking neutrality.\n";
