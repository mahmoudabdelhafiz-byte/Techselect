<?php

declare(strict_types=1);

$root=dirname(__DIR__);
$migration=$root.'/db/mysql/123_terminal_truck_appointment_gate_management_catalog.sql';
$sql=@file_get_contents($migration);
$errors=[];

if($sql===false){
    fwrite(STDERR,"Missing migration: db/mysql/123_terminal_truck_appointment_gate_management_catalog.sql\n");
    exit(1);
}

$category='terminal-truck-appointment-gate-management';
$products=[
    'onestop-vbs',
    'soget-tas',
    'kaleris-smart-access',
    'camco-vehicle-booking-system',
    'tideworks-gatevision'
];

if(strpos($sql,"'{$category}'")===false)$errors[]="Missing category {$category}";
foreach($products as $slug){
    if(substr_count($sql,"'{$slug}'")<3)$errors[]="Product {$slug} is not carried through product/evidence/mobile rows";
}

$migrations=glob($root.'/db/mysql/*.sql')?:[];
foreach(array_merge([$category],$products) as $slug){
    $hits=[];
    foreach($migrations as $file){
        if(realpath($file)===realpath($migration))continue;
        $text=@file_get_contents($file)?:'';
        if(strpos($text,"'{$slug}'")!==false)$hits[]=basename($file);
    }
    if($hits)$errors[]="Potential duplicate catalog shell {$slug} already exists in ".implode(', ',$hits);
}

foreach([
    'not_yet_verified','product_capability_evidence','vendor_documentation','product_mobile_access',
    "'android'","'ios'","'mobile_web'",'last_reviewed_at','Unknown != Unsupported',
    'gate-truck-appointment-booking','gate-capacity-rules','gate-prearrival-validation',
    'gate-driver-self-service','gate-multiterminal-coordination','gate-terminal-integration',
    'gate-automation-devices','gate-identity-access','gate-transaction-exceptions','gate-analytics-turntime'
] as $needle){
    if(strpos($sql,$needle)===false)$errors[]="Missing terminal gate invariant: {$needle}";
}

$allowedHosts=[
    '1-stop.biz','www.1-stop.biz',
    'soget.fr','www.soget.fr',
    'kaleris.com','www.kaleris.com',
    'camco.be','www.camco.be',
    'tideworks.com','www.tideworks.com'
];
preg_match_all('#https://[^\s\'\"]+#',$sql,$matches);
foreach(array_unique($matches[0]??[]) as $url){
    $url=rtrim($url,');,');
    $host=strtolower((string)parse_url($url,PHP_URL_HOST));
    if($host===''||!in_array($host,$allowedHosts,true))$errors[]="Non-first-party or unapproved host: {$host} ({$url})";
}

foreach(['g2.com','capterra','consultation_recommendations','recommendation_rank','Scoring::','overall_score','fit_score'] as $needle){
    if(stripos($sql,$needle)!==false)$errors[]="Catalog migration contains prohibited source/ranking coupling: {$needle}";
}

// Every promoted capability must resolve to a registered first-party source URL.
if(preg_match('/INSERT INTO cat123_sources VALUES\s*(.*?);\s*\n\s*INSERT INTO evidence_sources/is',$sql,$sm)){
    preg_match_all("/\\('(?:''|[^'])*','(https:\/\/(?:''|[^'])+)'/",$sm[1],$sourceMatches);
    $registered=array_fill_keys($sourceMatches[1]??[],true);
    if(preg_match('/INSERT INTO cat123_facts VALUES\s*(.*?);\s*\n\s*INSERT INTO product_capabilities/is',$sql,$fm)){
        preg_match_all("/\\('(?:''|[^'])*','(?:''|[^'])*','(?:''|[^'])*',[0-9.]+,'(?:''|[^'])*','(https:\/\/(?:''|[^'])+)'\\)/",$fm[1],$factMatches);
        foreach(array_unique($factMatches[1]??[]) as $url){
            if(!isset($registered[$url]))$errors[]="Capability source URL is not registered in cat123_sources: {$url}";
        }
    } else {
        $errors[]='Could not parse cat123_facts block for evidence-link validation.';
    }
} else {
    $errors[]='Could not parse cat123_sources block for evidence-link validation.';
}

// Preserve the distinction between appointment/VBS and gate-automation/GOS capabilities.
foreach([
    "'onestop-vbs','gate-prearrival-validation','partially_supported',0.950",
    "'onestop-vbs','gate-transaction-exceptions','partially_supported',0.950",
    "'kaleris-smart-access','gate-prearrival-validation','partially_supported',0.970",
    "'kaleris-smart-access','gate-terminal-integration','partially_supported',0.960",
    "'kaleris-smart-access','gate-analytics-turntime','partially_supported',0.950",
    "'camco-vehicle-booking-system','gate-automation-devices','partially_supported',0.980",
    "'camco-vehicle-booking-system','gate-identity-access','partially_supported',0.960",
    "'camco-vehicle-booking-system','gate-transaction-exceptions','partially_supported',0.970",
    "'tideworks-gatevision','gate-analytics-turntime','partially_supported',0.950"
] as $required){
    if(strpos($sql,$required)===false)$errors[]="Required scope boundary missing: {$required}";
}

foreach([
    'universal customs/readiness validation engine is not inferred',
    'dedicated real-time gate exception engine is not inferred',
    'universal rules-based readiness validator',
    'universal interface catalogue is not inferred',
    'dedicated gate-performance analytics belong to broader Kaleris analytics tooling',
    'belong to the broader Camco gate-automation/GOS layer',
    'connected gate-layer capabilities rather than universally native VBS entitlement',
    'companion gate-layer capability to VBS',
    'dedicated GateVision analytics/KPI package is not established'
] as $phrase){
    if(strpos($sql,$phrase)===false)$errors[]="Missing explicit limitation text: {$phrase}";
}

// Unverified capabilities must stay unknown rather than being inferred from adjacent suite features.
$mustRemainUnknown=[
    ['onestop-vbs','gate-automation-devices'],
    ['onestop-vbs','gate-identity-access'],
    ['onestop-vbs','gate-analytics-turntime'],
    ['soget-tas','gate-automation-devices'],
    ['soget-tas','gate-transaction-exceptions'],
    ['soget-tas','gate-analytics-turntime'],
    ['kaleris-smart-access','gate-capacity-rules'],
    ['kaleris-smart-access','gate-multiterminal-coordination'],
    ['kaleris-smart-access','gate-automation-devices'],
    ['kaleris-smart-access','gate-identity-access'],
    ['kaleris-smart-access','gate-transaction-exceptions'],
    ['camco-vehicle-booking-system','gate-multiterminal-coordination'],
    ['camco-vehicle-booking-system','gate-analytics-turntime'],
    ['tideworks-gatevision','gate-truck-appointment-booking'],
    ['tideworks-gatevision','gate-capacity-rules'],
    ['tideworks-gatevision','gate-prearrival-validation'],
    ['tideworks-gatevision','gate-multiterminal-coordination'],
    ['tideworks-gatevision','gate-identity-access']
];
foreach($mustRemainUnknown as [$product,$cap]){
    if(strpos($sql,"'{$product}','{$cap}','supported'")!==false ||
       strpos($sql,"'{$product}','{$cap}','partially_supported'")!==false){
        $errors[]="Unverified capability must remain not_yet_verified: {$product} / {$cap}";
    }
}

// Deployment remains unknown: web/cloud/Azure evidence is not automatically a commercial SaaS classification.
if(strpos($sql,'INSERT INTO product_deployments')!==false){
    $errors[]='Do not promote deployment models in batch 123.';
}
if(strpos($sql,'Web-based, cloud-hosted or Azure-hosted does not automatically define the commercial deployment model.')===false){
    $errors[]='Deployment inference warning must remain explicit.';
}

// Platform-specific mobile access remains unknown even where mobile access is advertised.
if(strpos($sql,"SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000")===false){
    $errors[]='Terminal gate mobile access must be inserted as not_yet_verified.';
}
if(preg_match("/'supported','supported','vendor_documentation'.*WHERE p\.slug IN\([^;]*(onestop-vbs|soget-tas|kaleris-smart-access|camco-vehicle-booking-system|tideworks-gatevision)/s",$sql)){
    $errors[]='Do not infer Android/iOS/mobile-web support from generic mobile/web/kiosk claims.';
}

if($errors){
    fwrite(STDERR,"Terminal truck/gate catalog check failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}

echo "Terminal truck/gate catalog contract passed: 1 canonical category, 5 current products, first-party evidence, VBS/GOS scope discipline, explicit unknowns, conservative deployment/mobile handling and ranking neutrality.\n";
