<?php

declare(strict_types=1);

$root=dirname(__DIR__);
$migration=$root.'/db/mysql/129_industrial_data_historians_ot_data_platforms_catalog.sql';
$sql=@file_get_contents($migration);
$errors=[];

if($sql===false){
    fwrite(STDERR,"Missing migration: db/mysql/129_industrial_data_historians_ot_data_platforms_catalog.sql\n");
    exit(1);
}

$category='industrial-data-historians-ot-data-platforms';
$products=[
    'aveva-pi-system',
    'canary-historian',
    'proficy-historian',
    'aspen-infoplus21',
    'honeywell-uniformance-phd'
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
    'product_deployments',"'public-saas'","'on-premise'",'last_reviewed_at','Unknown != Unsupported',
    'hist-timeseries-ingestion','hist-compression-storage','hist-industrial-connectivity',
    'hist-events-alarms','hist-store-forward','hist-contextualization',
    'hist-visualization-trending','hist-calculations-analytics',
    'hist-api-enterprise-integration','hist-enterprise-scale-ha'
] as $needle){
    if(strpos($sql,$needle)===false)$errors[]="Missing historian invariant: {$needle}";
}

$allowedHosts=[
    'aveva.com','www.aveva.com',
    'canarylabs.com','www.canarylabs.com',
    'gevernova.com','www.gevernova.com',
    'aspentech.com','www.aspentech.com',
    'honeywell.com','www.honeywell.com','process.honeywell.com'
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
if(preg_match('/INSERT INTO cat129_sources VALUES\s*(.*?);\s*\n\s*INSERT INTO evidence_sources/is',$sql,$sm)){
    preg_match_all("/\\('(?:''|[^'])*','(https:\/\/(?:''|[^'])+)'/",$sm[1],$sourceMatches);
    $registered=array_fill_keys($sourceMatches[1]??[],true);
    if(preg_match('/INSERT INTO cat129_facts VALUES\s*(.*?);\s*\n\s*INSERT INTO product_capabilities/is',$sql,$fm)){
        preg_match_all("/\\('(?:''|[^'])*','(?:''|[^'])*','(?:''|[^'])*',[0-9.]+,'(?:''|[^'])*','(https:\/\/(?:''|[^'])+)'\\)/",$fm[1],$factMatches);
        foreach(array_unique($factMatches[1]??[]) as $url){
            if(!isset($registered[$url]))$errors[]="Capability source URL is not registered in cat129_sources: {$url}";
        }
    } else {
        $errors[]='Could not parse cat129_facts block for evidence-link validation.';
    }
} else {
    $errors[]='Could not parse cat129_sources block for evidence-link validation.';
}

// Preserve modular/companion-product and evidence-scope boundaries.
foreach([
    "'aveva-pi-system','hist-enterprise-scale-ha','partially_supported',0.980",
    "'proficy-historian','hist-visualization-trending','partially_supported',0.960",
    "'proficy-historian','hist-calculations-analytics','partially_supported',0.970",
    "'aspen-infoplus21','hist-industrial-connectivity','partially_supported',0.960",
    "'aspen-infoplus21','hist-visualization-trending','partially_supported',0.980",
    "'aspen-infoplus21','hist-api-enterprise-integration','partially_supported',0.960",
    "'aspen-infoplus21','hist-enterprise-scale-ha','partially_supported',0.980",
    "'honeywell-uniformance-phd','hist-visualization-trending','partially_supported',0.980",
    "'honeywell-uniformance-phd','hist-calculations-analytics','partially_supported',0.970"
] as $required){
    if(strpos($sql,$required)===false)$errors[]="Required historian scope boundary missing: {$required}";
}

foreach([
    'exact redundancy architecture depends on deployed components',
    'richer web visualization is delivered through connected Proficy products',
    'advanced analytics/AI are provided through adjacent Proficy analytics products',
    'current public collector/protocol matrix is not inferred',
    'related product rather than assumed universally bundled in IP.21',
    'current public API/connector catalogue is not inferred',
    'explicit historian redundancy/failover is not inferred',
    'companion components rather than assumed PHD core entitlement',
    'broader KPI/analytics capabilities are delivered through additional Uniformance products'
] as $phrase){
    if(strpos($sql,$phrase)===false)$errors[]="Missing explicit historian limitation text: {$phrase}";
}

// Keep currently unverified capabilities unknown.
$mustRemainUnknown=[
    ['aveva-pi-system','hist-events-alarms'],
    ['aveva-pi-system','hist-store-forward'],
    ['canary-historian','hist-enterprise-scale-ha'],
    ['proficy-historian','hist-store-forward'],
    ['proficy-historian','hist-contextualization'],
    ['aspen-infoplus21','hist-events-alarms'],
    ['aspen-infoplus21','hist-store-forward'],
    ['honeywell-uniformance-phd','hist-contextualization']
];
foreach($mustRemainUnknown as [$product,$cap]){
    if(strpos($sql,"'{$product}','{$cap}','supported'")!==false ||
       strpos($sql,"'{$product}','{$cap}','partially_supported'")!==false){
        $errors[]="Unverified capability must remain not_yet_verified: {$product} / {$cap}";
    }
}

// Deployment is intentionally promoted only for Proficy Historian.
if(substr_count($sql,"WHERE p.slug='proficy-historian'")<2){
    $errors[]='Proficy Historian must retain explicit public-SaaS and on-premises deployment rows.';
}
if(preg_match('/-- Promote deployment only where the current product-specific evidence is explicit\.(.*?)-- Do not infer mobile platforms/s',$sql,$dm)){
    foreach(['aveva-pi-system','canary-historian','aspen-infoplus21','honeywell-uniformance-phd'] as $slug){
        if(strpos($dm[1],"'{$slug}'")!==false)$errors[]="Deployment must remain unverified for {$slug} in batch 129.";
    }
    if(substr_count($dm[1],"d.slug='public-saas'")!==1 || substr_count($dm[1],"d.slug='on-premise'")!==1){
        $errors[]='Historian deployment block must contain exactly one explicit SaaS and one explicit on-premises promotion.';
    }
} else {
    $errors[]='Could not isolate historian deployment block.';
}

// Platform-specific mobile access remains unknown for all five products.
if(strpos($sql,"SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000")===false){
    $errors[]='Historian mobile access must default to not_yet_verified.';
}
if(preg_match("/'supported','supported','vendor_documentation'.*WHERE p\.slug IN\([^;]*(aveva-pi-system|canary-historian|proficy-historian|aspen-infoplus21|honeywell-uniformance-phd)/s",$sql)){
    $errors[]='Do not infer Android/iOS/mobile-web support from browser or dashboard access.';
}

if($errors){
    fwrite(STDERR,"Industrial historian catalog check failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}

echo "Industrial historian catalog contract passed: 1 canonical category, 5 current products, first-party evidence, modular boundaries, explicit unknowns, narrow deployment handling and ranking neutrality.\n";
