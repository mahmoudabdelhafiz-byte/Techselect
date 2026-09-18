<?php

declare(strict_types=1);

$root=dirname(__DIR__);
$migration=$root.'/db/mysql/125_manufacturing_advanced_planning_scheduling_catalog.sql';
$sql=@file_get_contents($migration);
$errors=[];

if($sql===false){
    fwrite(STDERR,"Missing migration: db/mysql/125_manufacturing_advanced_planning_scheduling_catalog.sql\n");
    exit(1);
}

$category='advanced-planning-scheduling-manufacturing';
$products=[
    'siemens-opcenter-aps',
    'delmia-ortems',
    'asprova-aps',
    'cai-planettogether-aps',
    'sap-s4hana-ppds'
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
    'product_deployments',"'on-premise'",'last_reviewed_at','Unknown != Unsupported',
    'aps-finite-capacity-scheduling','aps-material-bom-constraints','aps-secondary-resource-constraints',
    'aps-sequence-changeover-optimization','aps-capacity-production-planning','aps-whatif-scenarios',
    'aps-dynamic-rescheduling','aps-multisite-planning','aps-erp-mes-integration','aps-planning-analytics'
] as $needle){
    if(strpos($sql,$needle)===false)$errors[]="Missing APS invariant: {$needle}";
}

$allowedHosts=[
    'siemens.com','www.siemens.com',
    '3ds.com','www.3ds.com',
    'asprova.com','www.asprova.com','lib.asprova.com',
    'planettogether.com','www.planettogether.com',
    'caisoft.com','www.caisoft.com',
    'help.sap.com'
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
if(preg_match('/INSERT INTO cat125_sources VALUES\s*(.*?);\s*\n\s*INSERT INTO evidence_sources/is',$sql,$sm)){
    preg_match_all("/\\('(?:''|[^'])*','(https:\/\/(?:''|[^'])+)'/",$sm[1],$sourceMatches);
    $registered=array_fill_keys($sourceMatches[1]??[],true);
    if(preg_match('/INSERT INTO cat125_facts VALUES\s*(.*?);\s*\n\s*INSERT INTO product_capabilities/is',$sql,$fm)){
        preg_match_all("/\\('(?:''|[^'])*','(?:''|[^'])*','(?:''|[^'])*',[0-9.]+,'(?:''|[^'])*','(https:\/\/(?:''|[^'])+)'\\)/",$fm[1],$factMatches);
        foreach(array_unique($factMatches[1]??[]) as $url){
            if(!isset($registered[$url]))$errors[]="Capability source URL is not registered in cat125_sources: {$url}";
        }
    } else {
        $errors[]='Could not parse cat125_facts block for evidence-link validation.';
    }
} else {
    $errors[]='Could not parse cat125_sources block for evidence-link validation.';
}

// Preserve product-family / optional-module boundaries.
foreach([
    "'siemens-opcenter-aps','aps-erp-mes-integration','partially_supported',0.960",
    "'asprova-aps','aps-sequence-changeover-optimization','partially_supported',0.980",
    "'asprova-aps','aps-planning-analytics','partially_supported',0.960",
    "'sap-s4hana-ppds','aps-secondary-resource-constraints','partially_supported',0.950",
    "'sap-s4hana-ppds','aps-erp-mes-integration','partially_supported',0.990",
    "'sap-s4hana-ppds','aps-planning-analytics','partially_supported',0.960"
] as $required){
    if(strpos($sql,$required)===false)$errors[]="Required APS scope boundary missing: {$required}";
}

foreach([
    'universal APS-native ERP/MES adapter catalogue is not inferred',
    'Optimization as an optional feature rather than assuming universal entitlement',
    'KPI costing/analysis is documented as an optional feature',
    'do not justify assuming generic labor/skill/tool scheduling parity',
    'not evidence of broad third-party MES/ERP connector coverage',
    'standalone APS KPI/analytics package is not inferred'
] as $phrase){
    if(strpos($sql,$phrase)===false)$errors[]="Missing explicit APS limitation text: {$phrase}";
}

// Keep currently unverified capability areas unknown.
$mustRemainUnknown=[
    ['siemens-opcenter-aps','aps-multisite-planning'],
    ['delmia-ortems','aps-multisite-planning'],
    ['asprova-aps','aps-whatif-scenarios'],
    ['asprova-aps','aps-multisite-planning'],
    ['sap-s4hana-ppds','aps-whatif-scenarios'],
    ['sap-s4hana-ppds','aps-multisite-planning']
];
foreach($mustRemainUnknown as [$product,$cap]){
    if(strpos($sql,"'{$product}','{$cap}','supported'")!==false ||
       strpos($sql,"'{$product}','{$cap}','partially_supported'")!==false){
        $errors[]="Unverified capability must remain not_yet_verified: {$product} / {$cap}";
    }
}

// PlanetTogether's current vendor identity must follow the 2026 CAI acquisition/rebrand.
if(strpos($sql,"('cai-software','advanced-planning-scheduling-manufacturing','CAI PlanetTogether APS','cai-planettogether-aps'")===false){
    $errors[]='PlanetTogether must remain attributed to current owner/vendor CAI Software.';
}
if(strpos($sql,'PlanetTogether currently documents a client-server architecture with cloud or on-premises server options.')===false){
    $errors[]='PlanetTogether deployment boundary must remain explicit.';
}

// SAP PP/DS must remain scoped as embedded S/4HANA capability, not a standalone vendor-neutral APS.
if(strpos($sql,'Embedded SAP S/4HANA production-planning and detailed-scheduling capability')===false){
    $errors[]='SAP PP/DS embedded S/4HANA scope must remain explicit.';
}

// Deployment promotion is intentionally limited to explicit install/on-prem evidence.
if(strpos($sql,"WHERE p.slug IN('delmia-ortems','asprova-aps','cai-planettogether-aps','sap-s4hana-ppds')")===false){
    $errors[]='Explicit APS on-premises deployment set is missing or broadened.';
}
if(strpos($sql,"d.slug='public-saas'")!==false){
    $errors[]='Do not promote public SaaS for APS batch 125; reviewed evidence does not justify it.';
}
if(preg_match('/-- Promote on-premises deployment only where current product-specific evidence is explicit\.(.*?)-- Do not infer SaaS/s',$sql,$dm)){
    if(strpos($dm[1],"'siemens-opcenter-aps'")!==false){
        $errors[]='Siemens Opcenter APS deployment must remain unverified in batch 125.';
    }
} else {
    $errors[]='Could not isolate APS deployment block.';
}

// Platform-specific mobile access remains unknown for all products.
if(strpos($sql,"SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000")===false){
    $errors[]='APS mobile access must default to not_yet_verified.';
}
if(preg_match("/'supported','supported','vendor_documentation'.*WHERE p\.slug IN\([^;]*(siemens-opcenter-aps|delmia-ortems|asprova-aps|cai-planettogether-aps|sap-s4hana-ppds)/s",$sql)){
    $errors[]='Do not infer Android/iOS/mobile-web support for APS products.';
}

if($errors){
    fwrite(STDERR,"Manufacturing APS catalog check failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}

echo "Manufacturing APS catalog contract passed: 1 canonical category, 5 current products, first-party evidence, option/module boundaries, explicit unknowns, conservative deployment/mobile handling and ranking neutrality.\n";
