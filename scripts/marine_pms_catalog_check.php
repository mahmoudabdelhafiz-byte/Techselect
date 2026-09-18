<?php

declare(strict_types=1);

$root=dirname(__DIR__);
$migration=$root.'/db/mysql/120_marine_planned_maintenance_technical_management_catalog.sql';
$sql=@file_get_contents($migration);
$errors=[];

if($sql===false){
    fwrite(STDERR,"Missing migration: db/mysql/120_marine_planned_maintenance_technical_management_catalog.sql\n");
    exit(1);
}

$category='marine-planned-maintenance-technical-management';
$products=[
    'dnv-shipmanager-technical',
    'bassnet-neo-maintenance',
    'smartpal-maintenance',
    'sertica-maintenance',
    'cloud-fleet-manager-maintenance'
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
    'marine-pms-scheduling-execution','marine-pms-equipment-hierarchy','marine-pms-defect-corrective',
    'marine-pms-condition-predictive','marine-pms-spares-inventory','marine-pms-procurement-integration',
    'marine-pms-drydock-projects','marine-pms-class-compliance','marine-pms-analytics-kpis',
    'marine-pms-shipshore-integration'
] as $needle){
    if(strpos($sql,$needle)===false)$errors[]="Missing marine PMS invariant: {$needle}";
}

$allowedHosts=[
    'dnv.com','www.dnv.com',
    'bassnet.no','www.bassnet.no',
    'mariapps.com','www.mariapps.com',
    'sertica.com','www.sertica.com',
    'hanseaticsoft.com','www.hanseaticsoft.com'
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
if(preg_match('/INSERT INTO cat120_sources VALUES\s*(.*?);\s*\n\s*INSERT INTO evidence_sources/is',$sql,$sm)){
    preg_match_all("/\\('(?:''|[^'])*','(https:\/\/(?:''|[^'])+)'/",$sm[1],$sourceMatches);
    $registered=array_fill_keys($sourceMatches[1]??[],true);
    if(preg_match('/INSERT INTO cat120_facts VALUES\s*(.*?);\s*\n\s*INSERT INTO product_capabilities/is',$sql,$fm)){
        preg_match_all("/\\('(?:''|[^'])*','(?:''|[^'])*','(?:''|[^'])*',[0-9.]+,'(?:''|[^'])*','(https:\/\/(?:''|[^'])+)'\\)/",$fm[1],$factMatches);
        foreach(array_unique($factMatches[1]??[]) as $url){
            if(!isset($registered[$url]))$errors[]="Capability source URL is not registered in cat120_sources: {$url}";
        }
    } else {
        $errors[]='Could not parse cat120_facts block for evidence-link validation.';
    }
} else {
    $errors[]='Could not parse cat120_sources block for evidence-link validation.';
}

// Preserve companion-product/module boundaries.
foreach([
    "'dnv-shipmanager-technical','marine-pms-procurement-integration','partially_supported',0.970",
    "'dnv-shipmanager-technical','marine-pms-drydock-projects','partially_supported',0.960",
    "'dnv-shipmanager-technical','marine-pms-analytics-kpis','partially_supported',0.970",
    "'cloud-fleet-manager-maintenance','marine-pms-condition-predictive','partially_supported',0.950"
] as $required){
    if(strpos($sql,$required)===false)$errors[]="Required scope boundary missing: {$required}";
}
if(strpos($sql,'procurement is not treated as universally included')===false){
    $errors[]='DNV procurement companion-module boundary must remain explicit.';
}
if(strpos($sql,'dry-dock management is not treated as universally included')===false){
    $errors[]='DNV dry-dock companion-product boundary must remain explicit.';
}
if(strpos($sql,'rather than assumed as core Technical entitlement')===false){
    $errors[]='DNV Analyzer companion-product boundary must remain explicit.';
}
if(strpos($sql,'full predictive-maintenance/AI capability is not inferred')===false){
    $errors[]='CFM predictive-maintenance boundary must remain explicit.';
}

// Dry-dock support remains unknown where the reviewed evidence does not establish a product capability.
foreach(['sertica-maintenance','cloud-fleet-manager-maintenance'] as $slug){
    if(strpos($sql,"'{$slug}','marine-pms-drydock-projects','supported'")!==false ||
       strpos($sql,"'{$slug}','marine-pms-drydock-projects','partially_supported'")!==false){
        $errors[]="Dry-dock/project support must remain not_yet_verified for {$slug} in batch 120.";
    }
}

// SaaS is promoted only for products with explicit product/platform evidence.
if(strpos($sql,"WHERE p.slug IN('bassnet-neo-maintenance','cloud-fleet-manager-maintenance')")===false){
    $errors[]='Explicit SaaS deployment set must remain BASSnet Neo Maintenance and Cloud Fleet Manager Maintenance.';
}
if(preg_match('/-- Promote deployment only where current product-specific evidence is explicit\.(.*?)-- Do not infer Android\/iOS\/mobile-web/s',$sql,$dm)){
    foreach(['dnv-shipmanager-technical','smartpal-maintenance','sertica-maintenance'] as $slug){
        if(strpos($dm[1],"'{$slug}'")!==false)$errors[]="Deployment must remain unverified for {$slug} unless product-specific deployment evidence is added.";
    }
} else {
    $errors[]='Could not isolate marine PMS deployment block.';
}

// Generic mobile/browser/app claims must not be promoted to a specific platform.
if(strpos($sql,"SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000")===false){
    $errors[]='Marine PMS mobile access must be inserted as not_yet_verified.';
}
if(preg_match("/'supported','supported','vendor_documentation'.*WHERE p\.slug IN\([^;]*(dnv-shipmanager-technical|bassnet-neo-maintenance|smartpal-maintenance|sertica-maintenance|cloud-fleet-manager-maintenance)/s",$sql)){
    $errors[]='Do not infer Android/iOS/mobile-web support from generic app/browser/mobile claims.';
}

if($errors){
    fwrite(STDERR,"Marine PMS catalog check failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}

echo "Marine PMS catalog contract passed: 1 canonical category, 5 current products, first-party evidence, exact evidence links, companion-module boundaries, conservative deployment/mobile handling and ranking neutrality.\n";
