<?php

declare(strict_types=1);

$root=dirname(__DIR__);
$migration=$root.'/db/mysql/131_asset_performance_management_predictive_maintenance_catalog.sql';
$sql=@file_get_contents($migration);
$errors=[];

if($sql===false){
    fwrite(STDERR,"Missing migration: db/mysql/131_asset_performance_management_predictive_maintenance_catalog.sql\n");
    exit(1);
}

$category='asset-performance-management-predictive-maintenance';
$products=[
    'ge-vernova-apm',
    'aspen-mtell',
    'siemens-senseye-predictive-maintenance',
    'aveva-predictive-analytics',
    'abb-genix-apm'
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
    'apm-asset-health-monitoring','apm-anomaly-detection','apm-failure-prediction',
    'apm-prescriptive-recommendations','apm-risk-strategy','apm-rcm-fmea-reliability',
    'apm-eam-workflow-integration','apm-ot-data-integration',
    'apm-case-collaboration','apm-enterprise-multisite'
] as $needle){
    if(strpos($sql,$needle)===false)$errors[]="Missing APM invariant: {$needle}";
}

$allowedHosts=[
    'gevernova.com','www.gevernova.com',
    'aspentech.com','www.aspentech.com',
    'siemens.com','www.siemens.com','cache.industry.siemens.com','developer.siemens.com',
    'aveva.com','www.aveva.com',
    'abb.com','www.abb.com','new.abb.com'
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

if(preg_match('/INSERT INTO cat131_sources VALUES\s*(.*?);\s*\n\s*INSERT INTO evidence_sources/is',$sql,$sm)){
    preg_match_all("/\\('(?:''|[^'])*','(https:\/\/(?:''|[^'])+)'/",$sm[1],$sourceMatches);
    $registered=array_fill_keys($sourceMatches[1]??[],true);
    if(preg_match('/INSERT INTO cat131_facts VALUES\s*(.*?);\s*\n\s*INSERT INTO product_capabilities/is',$sql,$fm)){
        preg_match_all("/\\('(?:''|[^'])*','(?:''|[^'])*','(?:''|[^'])*',[0-9.]+,'(?:''|[^'])*','(https:\/\/(?:''|[^'])+)'\\)/",$fm[1],$factMatches);
        foreach(array_unique($factMatches[1]??[]) as $url){
            if(!isset($registered[$url]))$errors[]="Capability source URL is not registered in cat131_sources: {$url}";
        }
    } else {
        $errors[]='Could not parse cat131_facts block for evidence-link validation.';
    }
} else {
    $errors[]='Could not parse cat131_sources block for evidence-link validation.';
}

// Preserve point-product vs suite/module boundaries.
foreach([
    "'aspen-mtell','apm-risk-strategy','partially_supported',0.960",
    "'aspen-mtell','apm-rcm-fmea-reliability','partially_supported',0.990",
    "'aspen-mtell','apm-ot-data-integration','partially_supported',0.970",
    "'siemens-senseye-predictive-maintenance','apm-prescriptive-recommendations','partially_supported',0.970",
    "'siemens-senseye-predictive-maintenance','apm-risk-strategy','partially_supported',0.960",
    "'siemens-senseye-predictive-maintenance','apm-eam-workflow-integration','partially_supported',0.960",
    "'aveva-predictive-analytics','apm-ot-data-integration','partially_supported',0.970",
    "'abb-genix-apm','apm-risk-strategy','partially_supported',0.970"
] as $required){
    if(strpos($sql,$required)===false)$errors[]="Required APM scope boundary missing: {$required}";
}

foreach([
    'full standalone asset-criticality and maintenance-strategy optimization module is not inferred',
    'full RCM and broad statistical reliability-analysis parity are not inferred',
    'universal historian/OT connector catalogue is not inferred',
    'formal prescriptive-maintenance recommendation engine equivalent to FMEA-guided prescriptions is not inferred',
    'full criticality/maintenance-strategy optimization module is not inferred',
    'does not establish universal closed-loop work-order integration',
    'PI System is a related product rather than assumed bundled connectivity',
    'full standalone asset-strategy optimization parity is not inferred'
] as $phrase){
    if(strpos($sql,$phrase)===false)$errors[]="Missing explicit APM limitation text: {$phrase}";
}

// Point products must not inherit broad APM-suite functions from adjacent vendor products.
$mustRemainUnknown=[
    ['aspen-mtell','apm-case-collaboration'],
    ['siemens-senseye-predictive-maintenance','apm-rcm-fmea-reliability'],
    ['aveva-predictive-analytics','apm-risk-strategy'],
    ['aveva-predictive-analytics','apm-rcm-fmea-reliability'],
    ['aveva-predictive-analytics','apm-eam-workflow-integration'],
    ['abb-genix-apm','apm-rcm-fmea-reliability'],
    ['abb-genix-apm','apm-case-collaboration']
];
foreach($mustRemainUnknown as [$product,$cap]){
    if(strpos($sql,"'{$product}','{$cap}','supported'")!==false ||
       strpos($sql,"'{$product}','{$cap}','partially_supported'")!==false){
        $errors[]="Unverified capability must remain not_yet_verified: {$product} / {$cap}";
    }
}

// GE suite capabilities are allowed but the module boundary must remain explicit in evidence text.
foreach([
    'it is a module within the broader GE Vernova APM suite',
    'SmartSignal is an integrated APM application rather than base-platform entitlement',
    'dedicated suite application',
    'exact function depends on selected APM applications'
] as $phrase){
    if(strpos($sql,$phrase)===false)$errors[]="GE APM modular-suite boundary missing: {$phrase}";
}

// Deployment promotion is narrow and evidence-specific.
if(strpos($sql,"WHERE p.slug IN('ge-vernova-apm','siemens-senseye-predictive-maintenance')")===false){
    $errors[]='Explicit APM public-SaaS deployment set is missing or broadened.';
}
if(strpos($sql,"WHERE p.slug='ge-vernova-apm'")===false){
    $errors[]='GE Vernova APM explicit on-premises deployment evidence must remain present.';
}
if(strpos($sql,'Aspen Mtell cloud VM support, AVEVA cloud-enabled wording and ABB flexible deployment do not by themselves establish the commercial deployment labels used by this catalog.')===false){
    $errors[]='APM deployment inference warning must remain explicit.';
}
if(preg_match('/-- Promote deployment only where current product-specific evidence is explicit\.(.*?)-- Aspen Mtell cloud VM support/s',$sql,$dm)){
    foreach(['aspen-mtell','aveva-predictive-analytics','abb-genix-apm'] as $slug){
        if(strpos($dm[1],"'{$slug}'")!==false)$errors[]="Deployment must remain unverified for {$slug} in batch 131.";
    }
} else {
    $errors[]='Could not isolate APM deployment block.';
}

// Mobile defaults unknown; only Senseye mobile web is promoted from its product data sheet.
if(strpos($sql,"SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000")===false){
    $errors[]='APM mobile access must default to not_yet_verified.';
}
if(strpos($sql,"SELECT p.id,'mobile_web','supported','supported','vendor_documentation',0.990")===false ||
   strpos($sql,"WHERE p.slug='siemens-senseye-predictive-maintenance'")===false){
    $errors[]='Senseye explicit mobile-web evidence must remain present.';
}
foreach(['ge-vernova-apm','aspen-mtell','aveva-predictive-analytics','abb-genix-apm'] as $slug){
    if(preg_match("/SELECT p\.id,'(?:android|ios|mobile_web)','supported'.*WHERE p\.slug='{$slug}'/s",$sql)){
        $errors[]="Do not infer platform-specific mobile support for {$slug}.";
    }
}

if($errors){
    fwrite(STDERR,"Asset Performance Management catalog check failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}

echo "Asset Performance Management catalog contract passed: 1 canonical category, 5 current products, first-party evidence, suite/point-product boundaries, explicit unknowns, conservative deployment/mobile handling and ranking neutrality.\n";
