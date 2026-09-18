<?php

declare(strict_types=1);

$root=dirname(__DIR__);
$migration=$root.'/db/mysql/124_yard_management_dock_scheduling_catalog.sql';
$sql=@file_get_contents($migration);
$errors=[];

if($sql===false){
    fwrite(STDERR,"Missing migration: db/mysql/124_yard_management_dock_scheduling_catalog.sql\n");
    exit(1);
}

$category='yard-management-dock-scheduling';
$products=[
    'kaleris-yms',
    'manhattan-yard-management',
    'blue-yonder-yard-management',
    'c3-yard',
    'goramp-yard-management'
];

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
    'product_deployments',"'public-saas'",'last_reviewed_at','Unknown != Unsupported',
    'yms-gate-checkin','yms-asset-visibility','yms-yard-move-tasking','yms-dock-scheduling',
    'yms-driver-carrier-selfservice','yms-dwell-detention','yms-host-integration',
    'yms-rtls-automation','yms-analytics-kpis','yms-multisite-enterprise'
] as $needle){
    if(strpos($sql,$needle)===false)$errors[]="Missing YMS invariant: {$needle}";
}

$allowedHosts=[
    'kaleris.com','www.kaleris.com',
    'manh.com','www.manh.com',
    'blueyonder.com','www.blueyonder.com',
    'c3solutions.com','www.c3solutions.com',
    'goramp.com','www.goramp.com'
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
if(preg_match('/INSERT INTO cat124_sources VALUES\s*(.*?);\s*\n\s*INSERT INTO evidence_sources/is',$sql,$sm)){
    preg_match_all("/\\('(?:''|[^'])*','(https:\/\/(?:''|[^'])+)'/",$sm[1],$sourceMatches);
    $registered=array_fill_keys($sourceMatches[1]??[],true);
    if(preg_match('/INSERT INTO cat124_facts VALUES\s*(.*?);\s*\n\s*INSERT INTO product_capabilities/is',$sql,$fm)){
        preg_match_all("/\\('(?:''|[^'])*','(?:''|[^'])*','(?:''|[^'])*',[0-9.]+,'(?:''|[^'])*','(https:\/\/(?:''|[^'])+)'\\)/",$fm[1],$factMatches);
        foreach(array_unique($factMatches[1]??[]) as $url){
            if(!isset($registered[$url]))$errors[]="Capability source URL is not registered in cat124_sources: {$url}";
        }
    } else {
        $errors[]='Could not parse cat124_facts block for evidence-link validation.';
    }
} else {
    $errors[]='Could not parse cat124_sources block for evidence-link validation.';
}

// Preserve companion-product/package boundaries.
foreach([
    "'manhattan-yard-management','yms-driver-carrier-selfservice','partially_supported',0.950",
    "'manhattan-yard-management','yms-dwell-detention','partially_supported',0.960",
    "'manhattan-yard-management','yms-analytics-kpis','partially_supported',0.960",
    "'blue-yonder-yard-management','yms-host-integration','partially_supported',0.960",
    "'blue-yonder-yard-management','yms-analytics-kpis','partially_supported',0.960",
    "'c3-yard','yms-dock-scheduling','partially_supported',0.990",
    "'c3-yard','yms-driver-carrier-selfservice','partially_supported',0.980",
    "'c3-yard','yms-rtls-automation','partially_supported',0.950",
    "'goramp-yard-management','yms-dock-scheduling','partially_supported',0.980"
] as $required){
    if(strpos($sql,$required)===false)$errors[]="Required YMS scope boundary missing: {$required}";
}

foreach([
    'broad external carrier self-service portal is not inferred',
    'dedicated detention/accessorial fee-management module is not inferred',
    'standalone yard-analytics package is not inferred',
    'universal external WMS/TMS/ERP interface catalogue is not inferred',
    'separate yard-KPI analytics package is not inferred',
    'companion C3 Reservations product',
    'connected C3 Hive/C3 Reservations experience',
    'universal native RTLS/camera package is not inferred',
    'dedicated Dock Scheduling/Time Slot Management solution'
] as $phrase){
    if(strpos($sql,$phrase)===false)$errors[]="Missing explicit YMS limitation text: {$phrase}";
}

// Do not infer capabilities that current reviewed evidence does not establish.
$mustRemainUnknown=[
    ['manhattan-yard-management','yms-rtls-automation'],
    ['manhattan-yard-management','yms-multisite-enterprise'],
    ['blue-yonder-yard-management','yms-yard-move-tasking'],
    ['blue-yonder-yard-management','yms-multisite-enterprise'],
    ['goramp-yard-management','yms-rtls-automation'],
    ['goramp-yard-management','yms-multisite-enterprise']
];
foreach($mustRemainUnknown as [$product,$cap]){
    if(strpos($sql,"'{$product}','{$cap}','supported'")!==false ||
       strpos($sql,"'{$product}','{$cap}','partially_supported'")!==false){
        $errors[]="Unverified capability must remain not_yet_verified: {$product} / {$cap}";
    }
}

// Deployment promotion is intentionally narrow.
if(strpos($sql,"WHERE p.slug='c3-yard'")===false){
    $errors[]='C3 Yard explicit SaaS deployment evidence must remain present.';
}
if(preg_match('/-- Promote deployment only where current product-specific evidence is explicit\.(.*?)-- Default platform-specific mobile evidence/s',$sql,$dm)){
    foreach(['kaleris-yms','manhattan-yard-management','blue-yonder-yard-management','goramp-yard-management'] as $slug){
        if(strpos($dm[1],"'{$slug}'")!==false)$errors[]="Deployment must remain unverified for {$slug} in batch 124.";
    }
} else {
    $errors[]='Could not isolate YMS deployment block.';
}

// Mobile remains unknown except C3's explicitly documented PWA.
if(strpos($sql,"SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000")===false){
    $errors[]='YMS mobile access must default to not_yet_verified.';
}
if(strpos($sql,"SELECT p.id,'mobile_web','supported','supported','vendor_documentation',0.990")===false ||
   strpos($sql,"WHERE p.slug='c3-yard'")===false){
    $errors[]='C3 Yard mobile-web PWA evidence must remain explicit.';
}
foreach(['kaleris-yms','manhattan-yard-management','blue-yonder-yard-management','goramp-yard-management'] as $slug){
    if(preg_match("/SELECT p\.id,'(?:android|ios|mobile_web)','supported'.*WHERE p\.slug='{$slug}'/s",$sql)){
        $errors[]="Do not infer platform-specific mobile support for {$slug}.";
    }
}

if($errors){
    fwrite(STDERR,"YMS/dock catalog check failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}

echo "YMS/dock catalog contract passed: 1 canonical category, 5 current products, first-party evidence, package boundaries, explicit unknowns, narrow deployment/mobile promotion and ranking neutrality.\n";
