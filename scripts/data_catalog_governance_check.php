<?php

declare(strict_types=1);

$root=dirname(__DIR__);
$migration=$root.'/db/mysql/108_data_catalog_governance_catalog.sql';
$sql=@file_get_contents($migration);
$errors=[];
if($sql===false){fwrite(STDERR,"Missing migration: db/mysql/108_data_catalog_governance_catalog.sql\n");exit(1);}

$category='data-catalog-governance';
$products=[
 'collibra-platform','alation-data-intelligence-platform','microsoft-purview-unified-catalog',
 'atlan-data-catalog-governance','informatica-cloud-data-governance-catalog'
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
 'product_mobile_access',"'android'","'ios'","'mobile_web'",
 'last_reviewed_at','Unknown != Unsupported',
 'dcg-metadata-inventory','dcg-search-discovery','dcg-business-glossary',
 'dcg-lineage-impact','dcg-governance-workflows','dcg-quality-trust','dcg-data-products-marketplace'
] as $needle){
    if(strpos($sql,$needle)===false)$errors[]="Missing evidence/catalog invariant: {$needle}";
}

$allowedHosts=[
 'collibra.com','www.collibra.com','productresources.collibra.com',
 'alation.com','www.alation.com',
 'learn.microsoft.com',
 'atlan.com','www.atlan.com','docs.atlan.com',
 'informatica.com','www.informatica.com',
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

if(strpos($sql,"'collibra-platform','dcg-quality-trust','supported',0.950")===false)$errors[]='Collibra quality capability must preserve module limitation.';
if(strpos($sql,'exact quality functionality can depend on licensed product modules')===false)$errors[]='Collibra quality licensing boundary must remain explicit.';
if(strpos($sql,"'informatica-cloud-data-governance-catalog','dcg-quality-trust','supported',0.950")===false)$errors[]='Informatica quality capability must preserve companion-service limitation.';
if(strpos($sql,'deeper quality functions may use companion Data Quality & Observability services')===false)$errors[]='Informatica quality service boundary must remain explicit.';

foreach([
 "'microsoft-purview-unified-catalog','dcg-quality-trust','supported'",
 "'microsoft-purview-unified-catalog','dcg-data-products-marketplace','partially_supported'",
 "'atlan-data-catalog-governance','dcg-quality-trust','supported'"
] as $forbidden){
    if(strpos($sql,$forbidden)!==false)$errors[]="Capability must remain unknown or use the exact evidence-backed status: {$forbidden}";
}

foreach(["'public-saas'","'on-premise'","'private-cloud'"] as $deployment){
    if(strpos($sql,$deployment)!==false)$errors[]="108 must not infer deployment support without product-specific selected-SKU evidence: {$deployment}";
}
if(strpos($sql,'Mobile administrative scope is not inferred from general mobile/browser access.')===false)$errors[]='Mobile administration inference guard must remain documented.';

if($errors){
    fwrite(STDERR,"Data catalog/governance catalog check failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}
echo "Data catalog/governance contract passed: 1 canonical category, 5 new products, first-party evidence, explicit unknowns, package boundaries, duplicate protection and ranking neutrality.\n";
