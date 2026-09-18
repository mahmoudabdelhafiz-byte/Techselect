<?php

declare(strict_types=1);

$root=dirname(__DIR__);
$migration=$root.'/db/mysql/127_laboratory_information_management_systems_catalog.sql';
$sql=@file_get_contents($migration);
$errors=[];

if($sql===false){
    fwrite(STDERR,"Missing migration: db/mysql/127_laboratory_information_management_systems_catalog.sql\n");
    exit(1);
}

$category='laboratory-information-management-systems';
$products=[
    'labware-lims',
    'labvantage-lims',
    'thermo-samplemanager-lims',
    'starlims-quality-manufacturing-lims',
    'sapio-lims'
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
    'lims-sample-chain-custody','lims-test-workflow-execution','lims-instrument-integration',
    'lims-lab-inventory','lims-batch-stability-coa','lims-regulated-records',
    'lims-scheduling-resource-planning','lims-analytics-kpis','lims-multisite-enterprise',
    'lims-enterprise-integration'
] as $needle){
    if(strpos($sql,$needle)===false)$errors[]="Missing LIMS invariant: {$needle}";
}

$allowedHosts=[
    'labware.com','www.labware.com',
    'labvantage.com','www.labvantage.com',
    'thermofisher.com','www.thermofisher.com','documents.thermofisher.com',
    'starlims.com','www.starlims.com',
    'sapiosciences.com','www.sapiosciences.com'
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
if(preg_match('/INSERT INTO cat127_sources VALUES\s*(.*?);\s*\n\s*INSERT INTO evidence_sources/is',$sql,$sm)){
    preg_match_all("/\\('(?:''|[^'])*','(https:\/\/(?:''|[^'])+)'/",$sm[1],$sourceMatches);
    $registered=array_fill_keys($sourceMatches[1]??[],true);
    if(preg_match('/INSERT INTO cat127_facts VALUES\s*(.*?);\s*\n\s*INSERT INTO product_capabilities/is',$sql,$fm)){
        preg_match_all("/\\('(?:''|[^'])*','(?:''|[^'])*','(?:''|[^'])*',[0-9.]+,'(?:''|[^'])*','(https:\/\/(?:''|[^'])+)'\\)/",$fm[1],$factMatches);
        foreach(array_unique($factMatches[1]??[]) as $url){
            if(!isset($registered[$url]))$errors[]="Capability source URL is not registered in cat127_sources: {$url}";
        }
    } else {
        $errors[]='Could not parse cat127_facts block for evidence-link validation.';
    }
} else {
    $errors[]='Could not parse cat127_sources block for evidence-link validation.';
}

// Preserve product/package boundaries where adjacent modules are not universally bundled.
foreach([
    "'labvantage-lims','lims-batch-stability-coa','partially_supported',0.970",
    "'thermo-samplemanager-lims','lims-batch-stability-coa','partially_supported',0.970",
    "'starlims-quality-manufacturing-lims','lims-analytics-kpis','partially_supported',0.970",
    "'sapio-lims','lims-batch-stability-coa','partially_supported',0.980",
    "'sapio-lims','lims-scheduling-resource-planning','partially_supported',0.950",
    "'sapio-lims','lims-multisite-enterprise','partially_supported',0.950"
] as $required){
    if(strpos($sql,$required)===false)$errors[]="Required LIMS scope boundary missing: {$required}";
}

foreach([
    'universal lot-release/COA workflow parity is not inferred',
    'does not establish universal lot-release/COA packaging',
    'Advanced Analytics is a value-added/adjacent solution',
    'universal COA/product-release scope across all Sapio LIMS editions is not inferred',
    'full laboratory resource-planning engine is not inferred',
    'explicit cross-site governance features are not inferred'
] as $phrase){
    if(strpos($sql,$phrase)===false)$errors[]="Missing explicit LIMS limitation text: {$phrase}";
}

// Deployment rules: only LabWare and LabVantage get explicit SaaS.
if(strpos($sql,"WHERE p.slug IN('labware-lims','labvantage-lims')")===false){
    $errors[]='Explicit LIMS SaaS deployment set must remain LabWare and LabVantage.';
}
if(strpos($sql,"WHERE p.slug IN('labware-lims','labvantage-lims','thermo-samplemanager-lims','sapio-lims')")===false){
    $errors[]='Explicit LIMS on-premises deployment set is missing or broadened.';
}
if(preg_match('/-- Promote deployment only where current product-specific evidence is explicit\.(.*?)-- Hosted cloud or browser access is not automatically classified as public SaaS\./s',$sql,$dm)){
    if(strpos($dm[1],"'starlims-quality-manufacturing-lims'")!==false){
        $errors[]='STARLIMS deployment must remain unverified in batch 127.';
    }
    foreach(['thermo-samplemanager-lims','sapio-lims'] as $slug){
        if(preg_match("/d\.slug='public-saas'.*?{$slug}/s",$dm[1])){
            $errors[]="Do not infer public SaaS for {$slug} from hosted/cloud wording.";
        }
    }
} else {
    $errors[]='Could not isolate LIMS deployment block.';
}

// Platform-specific mobile access remains unknown for all five products.
if(strpos($sql,"SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000")===false){
    $errors[]='LIMS mobile access must default to not_yet_verified.';
}
if(preg_match("/'supported','supported','vendor_documentation'.*WHERE p\.slug IN\([^;]*(labware-lims|labvantage-lims|thermo-samplemanager-lims|starlims-quality-manufacturing-lims|sapio-lims)/s",$sql)){
    $errors[]='Do not infer Android/iOS/mobile-web support from generic mobile/browser/tablet claims.';
}

if($errors){
    fwrite(STDERR,"LIMS catalog check failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}

echo "LIMS catalog contract passed: 1 canonical category, 5 current products, first-party evidence, package boundaries, explicit unknowns, conservative deployment/mobile handling and ranking neutrality.\n";
