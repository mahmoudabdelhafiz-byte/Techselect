<?php

declare(strict_types=1);

$root=dirname(__DIR__);
$migration=$root.'/db/mysql/133_environment_health_safety_management_catalog.sql';
$sql=@file_get_contents($migration);
$errors=[];

if($sql===false){
    fwrite(STDERR,"Missing migration: db/mysql/133_environment_health_safety_management_catalog.sql\n");
    exit(1);
}

$category='environment-health-safety-management';
$products=[
    'intelex-ehs-platform',
    'corityone',
    'spheracloud-ehs',
    'enablon-vision-platform',
    'benchmark-gensuite-ehs'
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
    'ehs-incident-nearmiss','ehs-audits-inspections','ehs-risk-assessment',
    'ehs-permit-control-work','ehs-occupational-health','ehs-industrial-hygiene',
    'ehs-environmental-compliance','ehs-regulatory-actions',
    'ehs-analytics-kpis','ehs-enterprise-integration-scale'
] as $needle){
    if(strpos($sql,$needle)===false)$errors[]="Missing EHS invariant: {$needle}";
}

$allowedHosts=[
    'intelex.com','www.intelex.com',
    'cority.com','www.cority.com',
    'sphera.com','www.sphera.com',
    'wolterskluwer.com','www.wolterskluwer.com',
    'benchmarkgensuite.com','www.benchmarkgensuite.com'
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
if(preg_match('/INSERT INTO cat133_sources VALUES\s*(.*?);\s*\n\s*INSERT INTO evidence_sources/is',$sql,$sm)){
    preg_match_all("/\\('(?:''|[^'])*','(https:\/\/(?:''|[^'])+)'/",$sm[1],$sourceMatches);
    $registered=array_fill_keys($sourceMatches[1]??[],true);
    if(preg_match('/INSERT INTO cat133_facts VALUES\s*(.*?);\s*\n\s*INSERT INTO product_capabilities/is',$sql,$fm)){
        preg_match_all("/\\('(?:''|[^'])*','(?:''|[^'])*','(?:''|[^'])*',[0-9.]+,'(?:''|[^'])*','(https:\/\/(?:''|[^'])+)'\\)/",$fm[1],$factMatches);
        foreach(array_unique($factMatches[1]??[]) as $url){
            if(!isset($registered[$url]))$errors[]="Capability source URL is not registered in cat133_sources: {$url}";
        }
    } else {
        $errors[]='Could not parse cat133_facts block for evidence-link validation.';
    }
} else {
    $errors[]='Could not parse cat133_sources block for evidence-link validation.';
}

// Preserve application/module boundaries for control-of-work.
foreach([
    "'spheracloud-ehs','ehs-permit-control-work','partially_supported',0.970",
    "'enablon-vision-platform','ehs-permit-control-work','partially_supported',0.990"
] as $required){
    if(strpos($sql,$required)===false)$errors[]="Required EHS module boundary missing: {$required}";
}

foreach([
    'entitlement depends on the licensed application bundle',
    'exact packaging should be validated for the selected CorityOne configuration',
    'permit-to-work is not inferred as universally included in the Health and Safety suite',
    'dedicated Control of Work and permit-to-work applications in the broader Vision portfolio rather than assuming universal base EHS entitlement',
    'individual regulatory-content applications may require separate licensing',
    'Open Insights is an additional cloud-native analytics layer'
] as $phrase){
    if(strpos($sql,$phrase)===false)$errors[]="Missing explicit EHS limitation text: {$phrase}";
}

// Broad EHS suites must not inherit unsupported worker-health/control-of-work functions.
$mustRemainUnknown=[
    ['spheracloud-ehs','ehs-occupational-health'],
    ['spheracloud-ehs','ehs-industrial-hygiene'],
    ['benchmark-gensuite-ehs','ehs-permit-control-work'],
    ['benchmark-gensuite-ehs','ehs-occupational-health'],
    ['benchmark-gensuite-ehs','ehs-industrial-hygiene']
];
foreach($mustRemainUnknown as [$product,$cap]){
    if(strpos($sql,"'{$product}','{$cap}','supported'")!==false ||
       strpos($sql,"'{$product}','{$cap}','partially_supported'")!==false){
        $errors[]="Unverified capability must remain not_yet_verified: {$product} / {$cap}";
    }
}

// Deployment promotion is intentionally limited to explicit SaaS evidence.
if(strpos($sql,"WHERE p.slug IN('corityone','spheracloud-ehs','enablon-vision-platform')")===false){
    $errors[]='Explicit EHS public-SaaS deployment set is missing or broadened.';
}
if(strpos($sql,'Intelex is web-based and Benchmark is cloud-based in vendor material, but those phrases are not converted automatically into this catalog\'s public-SaaS classification.')===false){
    $errors[]='EHS web/cloud deployment inference warning must remain explicit.';
}
if(preg_match('/-- Promote deployment only where the commercial SaaS model is explicit\.(.*?)-- Intelex is web-based/s',$sql,$dm)){
    foreach(['intelex-ehs-platform','benchmark-gensuite-ehs'] as $slug){
        if(strpos($dm[1],"'{$slug}'")!==false)$errors[]="Deployment must remain unverified for {$slug} in batch 133.";
    }
} else {
    $errors[]='Could not isolate EHS deployment block.';
}

// Mobile defaults unknown; only Enablon and Benchmark have explicit current iOS/Android evidence.
if(strpos($sql,"SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000")===false){
    $errors[]='EHS mobile access must default to not_yet_verified.';
}
if(strpos($sql,"WHERE p.slug IN('enablon-vision-platform','benchmark-gensuite-ehs')")===false){
    $errors[]='Explicit Enablon/Benchmark Android+iOS mobile support set is missing.';
}
foreach(['intelex-ehs-platform','corityone','spheracloud-ehs'] as $slug){
    if(preg_match("/SELECT p\.id,x\.platform,'supported'.*?WHERE p\.slug IN\([^;]*{$slug}/s",$sql)){
        $errors[]="Do not infer platform-specific native mobile support for {$slug}.";
    }
}

// Keep Enablon vendor ownership attributed to Wolters Kluwer rather than an obsolete standalone vendor shell.
if(strpos($sql,"('wolters-kluwer','environment-health-safety-management','Enablon Vision Platform'")===false){
    $errors[]='Enablon Vision Platform must remain attributed to Wolters Kluwer.';
}

if($errors){
    fwrite(STDERR,"EHS catalog check failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}

echo "EHS catalog contract passed: 1 canonical category, 5 current products, first-party evidence, suite/module boundaries, explicit unknowns, conservative deployment/mobile handling and ranking neutrality.\n";
