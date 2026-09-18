<?php

declare(strict_types=1);

$root=dirname(__DIR__);
$migration=$root.'/db/mysql/132_industrial_energy_sustainability_management_catalog.sql';
$sql=@file_get_contents($migration);
$errors=[];

if($sql===false){
    fwrite(STDERR,"Missing migration: db/mysql/132_industrial_energy_sustainability_management_catalog.sql\n");
    exit(1);
}

$category='industrial-energy-sustainability-management';
$products=[
    'simatic-energy-manager',
    'ecostruxure-resource-advisor',
    'abb-ability-optimax',
    'ibm-envizi',
    'honeywell-forge-sustainability-emissions'
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
    'esm-energy-data-collection','esm-utility-cost-analytics','esm-kpi-benchmarking',
    'esm-forecast-scenario','esm-realtime-optimization','esm-ghg-accounting',
    'esm-target-program-management','esm-iso50001-compliance',
    'esm-enterprise-integration','esm-enterprise-multisite'
] as $needle){
    if(strpos($sql,$needle)===false)$errors[]="Missing energy/sustainability invariant: {$needle}";
}

$allowedHosts=[
    'siemens.com','www.siemens.com','cache.industry.siemens.com',
    'se.com','www.se.com',
    'abb.com','www.abb.com','new.abb.com',
    'ibm.com','www.ibm.com',
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

if(preg_match('/INSERT INTO cat132_sources VALUES\s*(.*?);\s*\n\s*INSERT INTO evidence_sources/is',$sql,$sm)){
    preg_match_all("/\\('(?:''|[^'])*','(https:\/\/(?:''|[^'])+)'/",$sm[1],$sourceMatches);
    $registered=array_fill_keys($sourceMatches[1]??[],true);
    if(preg_match('/INSERT INTO cat132_facts VALUES\s*(.*?);\s*\n\s*INSERT INTO product_capabilities/is',$sql,$fm)){
        preg_match_all("/\\('(?:''|[^'])*','(?:''|[^'])*','(?:''|[^'])*',[0-9.]+,'(?:''|[^'])*','(https:\/\/(?:''|[^'])+)'\\)/",$fm[1],$factMatches);
        foreach(array_unique($factMatches[1]??[]) as $url){
            if(!isset($registered[$url]))$errors[]="Capability source URL is not registered in cat132_sources: {$url}";
        }
    } else {
        $errors[]='Could not parse cat132_facts block for evidence-link validation.';
    }
} else {
    $errors[]='Could not parse cat132_sources block for evidence-link validation.';
}

// Preserve the plant-operations vs enterprise-sustainability boundaries.
foreach([
    "'simatic-energy-manager','esm-utility-cost-analytics','partially_supported',0.970",
    "'simatic-energy-manager','esm-forecast-scenario','partially_supported',0.970",
    "'simatic-energy-manager','esm-realtime-optimization','partially_supported',0.960",
    "'simatic-energy-manager','esm-ghg-accounting','partially_supported',0.980",
    "'simatic-energy-manager','esm-target-program-management','partially_supported',0.980",
    "'ecostruxure-resource-advisor','esm-forecast-scenario','partially_supported',0.970",
    "'ecostruxure-resource-advisor','esm-realtime-optimization','partially_supported',0.950",
    "'ecostruxure-resource-advisor','esm-enterprise-integration','partially_supported',0.970",
    "'abb-ability-optimax','esm-ghg-accounting','partially_supported',0.970",
    "'ibm-envizi','esm-forecast-scenario','partially_supported',0.990",
    "'ibm-envizi','esm-realtime-optimization','partially_supported',0.950",
    "'honeywell-forge-sustainability-emissions','esm-energy-data-collection','partially_supported',0.960",
    "'honeywell-forge-sustainability-emissions','esm-kpi-benchmarking','partially_supported',0.960",
    "'honeywell-forge-sustainability-emissions','esm-target-program-management','partially_supported',0.960",
    "'honeywell-forge-sustainability-emissions','esm-enterprise-multisite','partially_supported',0.950"
] as $required){
    if(strpos($sql,$required)===false)$errors[]="Required energy/sustainability scope boundary missing: {$required}";
}

foreach([
    'enterprise utility-bill validation/procurement workflows are not inferred',
    'broad enterprise sustainability scenario planning is not inferred',
    'autonomous closed-loop dispatch of site energy assets is not inferred',
    'full Scope 1-3 enterprise GHG accounting with maintained factor libraries is not inferred',
    'broad enterprise sustainability-program/project management is not inferred',
    'closed-loop real-time plant energy control belongs to other EcoStruxure offerings',
    'full corporate Scope 1-3 GHG accounting and disclosure workflows are not inferred',
    'add-on module rather than assumed in every Envizi package',
    'not treated as a closed-loop industrial energy-control platform',
    'broad utility/resource metering scope is not inferred',
    'broad energy-efficiency KPI and facility benchmarking parity is not inferred',
    'broad enterprise sustainability-project portfolio management is not inferred'
] as $phrase){
    if(strpos($sql,$phrase)===false)$errors[]="Missing explicit energy/sustainability limitation text: {$phrase}";
}

// Explicit unknowns protect category separation.
$mustRemainUnknown=[
    ['ecostruxure-resource-advisor','esm-iso50001-compliance'],
    ['abb-ability-optimax','esm-target-program-management'],
    ['ibm-envizi','esm-iso50001-compliance'],
    ['honeywell-forge-sustainability-emissions','esm-utility-cost-analytics'],
    ['honeywell-forge-sustainability-emissions','esm-forecast-scenario'],
    ['honeywell-forge-sustainability-emissions','esm-realtime-optimization'],
    ['honeywell-forge-sustainability-emissions','esm-iso50001-compliance']
];
foreach($mustRemainUnknown as [$product,$cap]){
    if(strpos($sql,"'{$product}','{$cap}','supported'")!==false ||
       strpos($sql,"'{$product}','{$cap}','partially_supported'")!==false){
        $errors[]="Unverified capability must remain not_yet_verified: {$product} / {$cap}";
    }
}

// Deployment promotion is explicit and intentionally narrow.
if(strpos($sql,"WHERE p.slug IN('simatic-energy-manager','abb-ability-optimax')")===false){
    $errors[]='Explicit on-premises deployment set is missing or broadened.';
}
if(strpos($sql,"WHERE p.slug IN('ecostruxure-resource-advisor','abb-ability-optimax','ibm-envizi','honeywell-forge-sustainability-emissions')")===false){
    $errors[]='Explicit public-SaaS deployment set is missing or broadened.';
}
if(strpos($sql,'SIMATIC Energy Manager has Industrial Edge and Insights Hub cloud variants, but cloud wording alone is not converted to the catalog\'s public-SaaS label here.')===false){
    $errors[]='SIMATIC cloud/SaaS inference warning must remain explicit.';
}
if(preg_match('/INSERT INTO product_deployments.*?d\.slug=\'public-saas\'.*?WHERE p\.slug IN\(([^)]*)\)/s',$sql,$saasMatch)){
    if(strpos($saasMatch[1],"'simatic-energy-manager'")!==false){
        $errors[]='Do not promote SIMATIC Energy Manager as generic public SaaS in batch 132.';
    }
}

// Platform-specific mobile access remains unknown for all products.
if(strpos($sql,"SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000")===false){
    $errors[]='Energy/sustainability mobile access must default to not_yet_verified.';
}
if(preg_match("/'supported','supported','vendor_documentation'.*WHERE p\.slug IN\([^;]*(simatic-energy-manager|ecostruxure-resource-advisor|abb-ability-optimax|ibm-envizi|honeywell-forge-sustainability-emissions)/s",$sql)){
    $errors[]='Do not infer Android/iOS/mobile-web support from browser/cloud access.';
}

if($errors){
    fwrite(STDERR,"Energy & sustainability catalog check failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}

echo "Energy & sustainability catalog contract passed: 1 canonical category, 5 current products, first-party evidence, plant-vs-enterprise scope boundaries, explicit unknowns, deployment/mobile discipline and ranking neutrality.\n";
