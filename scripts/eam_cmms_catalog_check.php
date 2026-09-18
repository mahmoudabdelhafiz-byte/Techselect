<?php

declare(strict_types=1);

$root=dirname(__DIR__);
$migration=$root.'/db/mysql/113_eam_cmms_catalog.sql';
$sql=@file_get_contents($migration);
$errors=[];

if($sql===false){
    fwrite(STDERR,"Missing migration: db/mysql/113_eam_cmms_catalog.sql\n");
    exit(1);
}

$category='enterprise-asset-management-cmms';
$products=['ibm-maximo-application-suite','maintainx-cmms','upkeep-cmms','fiix-cmms','emaint-cmms'];

if(strpos($sql,"'{$category}'")===false)$errors[]="Missing category {$category}";
foreach($products as $slug){
    if(substr_count($sql,"'{$slug}'")<3)$errors[]="Product {$slug} is not carried through product/evidence/mobile or deployment rows";
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
    'product_mobile_access',"'android'","'ios'","'mobile_web'",
    'product_deployments',"'public-saas'","'on-premise'",'last_reviewed_at','Unknown != Unsupported',
    'eam-asset-registry-history','eam-work-orders','eam-preventive-maintenance','eam-condition-predictive',
    'eam-parts-inventory','eam-mobile-technician','eam-reporting-kpis','eam-enterprise-integrations'
] as $needle){
    if(strpos($sql,$needle)===false)$errors[]="Missing EAM/CMMS invariant: {$needle}";
}

$allowedHosts=[
    'ibm.com','www.ibm.com',
    'getmaintainx.com','www.getmaintainx.com','help.getmaintainx.com',
    'upkeep.com','www.upkeep.com',
    'fiixsoftware.com','www.fiixsoftware.com','lp.fiixsoftware.com',
    'rockwellautomation.com','www.rockwellautomation.com',
    'fluke.com','www.fluke.com',
    'emaint.com','www.emaint.com',
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

if(strpos($sql,"'emaint-cmms','eam-condition-predictive','partially_supported',0.950")===false){
    $errors[]='eMaint predictive/condition capability must preserve its partial-support boundary.';
}
if(strpos($sql,'deeper predictive monitoring may depend on Fluke sensors/services or additional reliability products')===false){
    $errors[]='eMaint predictive companion-product limitation must remain explicit.';
}
if(strpos($sql,'predictive capabilities beyond those triggers may depend on companion analytics products')===false){
    $errors[]='Fiix predictive/condition boundary must remain explicit.';
}

if(strpos($sql,"WHERE p.slug='ibm-maximo-application-suite'")===false){
    $errors[]='Maximo on-premises deployment evidence must remain explicit.';
}
if(strpos($sql,"WHERE p.slug='upkeep-cmms'")===false){
    $errors[]='UpKeep platform-specific mobile evidence block must remain explicit.';
}

foreach([
    "'maintainx-cmms','android','supported'",
    "'maintainx-cmms','ios','supported'",
    "'fiix-cmms','android','supported'",
    "'fiix-cmms','ios','supported'",
    "'emaint-cmms','android','supported'",
    "'emaint-cmms','ios','supported'"
] as $forbidden){
    if(strpos($sql,$forbidden)!==false)$errors[]="Platform-specific mobile support must remain unverified unless directly evidenced: {$forbidden}";
}

if($errors){
    fwrite(STDERR,"EAM/CMMS catalog check failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}

echo "EAM/CMMS catalog contract passed: 1 canonical category, 5 current products, first-party evidence, scope boundaries, duplicate protection, mobile/deployment discipline and ranking neutrality.\n";
