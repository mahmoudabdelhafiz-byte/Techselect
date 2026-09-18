<?php

declare(strict_types=1);

$root=dirname(__DIR__);
$migration=$root.'/db/mysql/119_commercial_shipping_voyage_management_catalog.sql';
$sql=@file_get_contents($migration);
$errors=[];

if($sql===false){
    fwrite(STDERR,"Missing migration: db/mysql/119_commercial_shipping_voyage_management_catalog.sql\n");
    exit(1);
}

$category='commercial-shipping-voyage-management';
$products=[
    'veson-imos',
    'sedna-voyage-management-system',
    'shipnet-commercial',
    'openocean-studio',
    'nextvoyage'
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
    'vms-chartering-estimation','vms-voyage-operations','vms-laytime-demurrage','vms-bunker-management',
    'vms-voyage-pnl-accounting','vms-emissions-compliance','vms-port-cost-disbursement',
    'vms-vessel-reporting','vms-api-integrations','vms-voyage-optimization'
] as $needle){
    if(strpos($sql,$needle)===false)$errors[]="Missing commercial-shipping invariant: {$needle}";
}

$allowedHosts=[
    'veson.com','www.veson.com','help.veson.com',
    'sedna.com','www.sedna.com',
    'shipnet.no','www.shipnet.no','blog.shipnet.no',
    '90poe.io','www.90poe.io',
    'nextvoyage.app','www.nextvoyage.app'
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

// Every promoted capability must point to a registered first-party source URL.
if(preg_match('/INSERT INTO cat119_sources VALUES\s*(.*?);\s*\n\s*INSERT INTO evidence_sources/is',$sql,$sm)){
    preg_match_all("/\\('(?:''|[^'])*','(https:\/\/(?:''|[^'])+)'/",$sm[1],$sourceMatches);
    $registered=array_fill_keys($sourceMatches[1]??[],true);
    if(preg_match('/INSERT INTO cat119_facts VALUES\s*(.*?);\s*\n\s*INSERT INTO product_capabilities/is',$sql,$fm)){
        preg_match_all("/\\('(?:''|[^'])*','(?:''|[^'])*','(?:''|[^'])*',[0-9.]+,'(?:''|[^'])*','(https:\/\/(?:''|[^'])+)'\\)/",$fm[1],$factMatches);
        foreach(array_unique($factMatches[1]??[]) as $url){
            if(!isset($registered[$url]))$errors[]="Capability source URL is not registered in cat119_sources: {$url}";
        }
    } else {
        $errors[]='Could not parse cat119_facts block for evidence-link validation.';
    }
} else {
    $errors[]='Could not parse cat119_sources block for evidence-link validation.';
}

// Preserve companion/scope boundaries rather than overstating platform packages.
foreach([
    "'veson-imos','vms-vessel-reporting','partially_supported',0.960",
    "'veson-imos','vms-voyage-optimization','partially_supported',0.950",
    "'shipnet-commercial','vms-bunker-management','partially_supported',0.950"
] as $required){
    if(strpos($sql,$required)===false)$errors[]="Required scope boundary missing: {$required}";
}
if(strpos($sql,'connected IMOS/Veson workflow rather than assumed core entitlement')===false){
    $errors[]='Veson vessel-reporting companion/workflow boundary must remain explicit.';
}
if(strpos($sql,'dedicated weather-routing or speed-optimization engines should not be inferred')===false){
    $errors[]='Veson optimization boundary must remain explicit.';
}
if(strpos($sql,'standalone bunker-procurement suite is not inferred')===false){
    $errors[]='Shipnet bunker-management boundary must remain explicit.';
}

// Explicit unknowns for unverified areas.
foreach([
    ['sedna-voyage-management-system','vms-vessel-reporting'],
    ['sedna-voyage-management-system','vms-voyage-optimization'],
    ['openocean-studio','vms-laytime-demurrage'],
    ['nextvoyage','vms-emissions-compliance'],
    ['nextvoyage','vms-voyage-optimization']
] as [$product,$cap]){
    if(strpos($sql,"'{$product}','{$cap}','supported'")!==false ||
       strpos($sql,"'{$product}','{$cap}','partially_supported'")!==false){
        $errors[]="Unverified capability must remain not_yet_verified: {$product} / {$cap}";
    }
}

// SaaS is promoted only where current product-specific evidence is explicit.
if(strpos($sql,"WHERE p.slug IN('veson-imos','shipnet-commercial','openocean-studio','nextvoyage')")===false){
    $errors[]='Explicit SaaS deployment set must remain Veson IMOS, Shipnet Commercial, OpenOcean STUDIO and Nextvoyage.';
}
if(preg_match('/-- Promote deployment only where current product-specific evidence is explicit\.(.*?)-- Do not infer Android\/iOS\/mobile-web/s',$sql,$dm)){
    if(strpos($dm[1],"'sedna-voyage-management-system'")!==false){
        $errors[]='Sedna VMS deployment must remain unverified unless product-specific deployment evidence is added.';
    }
} else {
    $errors[]='Could not isolate commercial-shipping deployment block.';
}

// Generic mobile claims must not be promoted to Android/iOS/mobile-web support.
if(strpos($sql,"SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000")===false){
    $errors[]='Commercial-shipping mobile access must be inserted as not_yet_verified.';
}
if(preg_match("/'supported','supported','vendor_documentation'.*WHERE p\.slug IN\([^;]*(veson-imos|sedna-voyage-management-system|shipnet-commercial|openocean-studio|nextvoyage)/s",$sql)){
    $errors[]='Do not infer platform-specific mobile support from generic mobile/onboard claims.';
}

if($errors){
    fwrite(STDERR,"Commercial shipping VMS catalog check failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}

echo "Commercial shipping VMS catalog contract passed: 1 canonical category, 5 current products, first-party evidence, exact evidence links, conservative scope/deployment/mobile handling and ranking neutrality.\n";
