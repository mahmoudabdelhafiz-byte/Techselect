<?php

declare(strict_types=1);

$root=dirname(__DIR__);
$migration=$root.'/db/mysql/114_field_service_management_catalog.sql';
$sql=@file_get_contents($migration);
$errors=[];

if($sql===false){
    fwrite(STDERR,"Missing migration: db/mysql/114_field_service_management_catalog.sql\n");
    exit(1);
}

$category='field-service-management';
$products=[
    'salesforce-field-service',
    'dynamics-365-field-service',
    'oracle-fusion-field-service',
    'ifs-cloud-field-service-management',
    'servicemax-core'
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
    'not_yet_verified','product_capability_evidence','vendor_documentation',
    'product_mobile_access',"'android'","'ios'","'mobile_web'",'last_reviewed_at','Unknown != Unsupported',
    'fsm-work-orders','fsm-scheduling-dispatch','fsm-routing-optimization','fsm-customer-appointments',
    'fsm-mobile-technician','fsm-offline-execution','fsm-parts-inventory','fsm-analytics-kpis','fsm-enterprise-integrations'
] as $needle){
    if(strpos($sql,$needle)===false)$errors[]="Missing FSM invariant: {$needle}";
}

$allowedHosts=[
    'salesforce.com','www.salesforce.com','help.salesforce.com',
    'microsoft.com','www.microsoft.com','learn.microsoft.com',
    'oracle.com','www.oracle.com','docs.oracle.com',
    'ifs.com','www.ifs.com',
    'ptc.com','www.ptc.com','support.ptc.com'
];
preg_match_all('#https://[^\s\'\"]+#',$sql,$matches);
foreach(array_unique($matches[0]??[]) as $url){
    $url=rtrim($url,');,');
    $host=strtolower((string)parse_url($url,PHP_URL_HOST));
    if($host===''||!in_array($host,$allowedHosts,true))$errors[]="Non-first-party or unapproved host: {$host} ({$url})";
}

foreach(['consultation_recommendations','recommendation_rank','Scoring::','overall_score','fit_score'] as $needle){
    if(stripos($sql,$needle)!==false)$errors[]="Catalog migration must not affect ranking/scoring: {$needle}";
}

if(strpos($sql,"'salesforce-field-service','fsm-customer-appointments','partially_supported',0.950")===false){
    $errors[]='Salesforce customer-appointment support must preserve managed-package/licensing boundary.';
}
if(strpos($sql,'requires the relevant managed package and permission-set licensing')===false){
    $errors[]='Salesforce appointment assistant package boundary must remain explicit.';
}
if(strpos($sql,"'dynamics-365-field-service','fsm-offline-execution','partially_supported',0.950")===false){
    $errors[]='Dynamics offline support must preserve refreshed-mobile limitation.';
}
if(strpos($sql,'refreshed mobile experience currently does not support offline operation')===false){
    $errors[]='Dynamics refreshed-mobile offline limitation must remain explicit.';
}
if(strpos($sql,'it is an extension of ServiceMax Core')===false){
    $errors[]='ServiceMax Engage extension boundary must remain explicit.';
}

foreach([
    "'salesforce-field-service','android','supported'",
    "'salesforce-field-service','ios','supported'",
    "'oracle-fusion-field-service','android','supported'",
    "'oracle-fusion-field-service','ios','supported'",
    "'ifs-cloud-field-service-management','android','supported'",
    "'ifs-cloud-field-service-management','ios','supported'"
] as $forbidden){
    if(strpos($sql,$forbidden)!==false)$errors[]="Platform-specific mobile support must remain unverified unless directly evidenced in 114: {$forbidden}";
}

if($errors){
    fwrite(STDERR,"FSM catalog check failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}

echo "FSM catalog contract passed: 1 canonical category, 5 current products, first-party evidence, package/mobile boundaries, duplicate protection and ranking neutrality.\n";
