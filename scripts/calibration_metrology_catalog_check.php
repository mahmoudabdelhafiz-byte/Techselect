<?php

declare(strict_types=1);

$root=dirname(__DIR__);
$migration=$root.'/db/mysql/135_calibration_metrology_management_catalog.sql';
$sql=@file_get_contents($migration);
$errors=[];

if($sql===false){
    fwrite(STDERR,"Missing migration: db/mysql/135_calibration_metrology_management_catalog.sql\n");
    exit(1);
}

$category='calibration-metrology-management';
$products=[
    'beamex-cmx',
    'fluke-metcal-metteam',
    'indysoft-calibration-management',
    'prime-pcx',
    'cybermetrics-gagetrak'
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
    'cal-asset-scheduling','cal-procedure-execution','cal-uncertainty-decision-rules',
    'cal-reference-traceability','cal-asfound-asleft-oot','cal-certificates-esign',
    'cal-instrument-automation','cal-field-offline','cal-regulated-audit',
    'cal-enterprise-integration-scale'
] as $needle){
    if(strpos($sql,$needle)===false)$errors[]="Missing calibration/metrology invariant: {$needle}";
}

$allowedHosts=[
    'beamex.com','www.beamex.com',
    'fluke.com','www.fluke.com',
    'indysoft.com','www.indysoft.com','docs.indysoft.com',
    'primetechpa.com','www.primetechpa.com','helpcenter.primetechpa.com',
    'gagetrak.com','www.gagetrak.com',
    'cybermetrics.com','www.cybermetrics.com'
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
if(preg_match('/INSERT INTO cat135_sources VALUES\s*(.*?);\s*\n\s*INSERT INTO evidence_sources/is',$sql,$sm)){
    preg_match_all("/\\('(?:''|[^'])*','(https:\/\/(?:''|[^'])+)'/",$sm[1],$sourceMatches);
    $registered=array_fill_keys($sourceMatches[1]??[],true);
    if(preg_match('/INSERT INTO cat135_facts VALUES\s*(.*?);\s*\n\s*INSERT INTO product_capabilities/is',$sql,$fm)){
        preg_match_all("/\\('(?:''|[^'])*','(?:''|[^'])*','(?:''|[^'])*',[0-9.]+,'(?:''|[^'])*','(https:\/\/(?:''|[^'])+)'\\)/",$fm[1],$factMatches);
        foreach(array_unique($factMatches[1]??[]) as $url){
            if(!isset($registered[$url]))$errors[]="Capability source URL is not registered in cat135_sources: {$url}";
        }
    } else {
        $errors[]='Could not parse cat135_facts block for evidence-link validation.';
    }
} else {
    $errors[]='Could not parse cat135_sources block for evidence-link validation.';
}

// Preserve scope boundaries where evidence is incomplete or delivered through companion modules/options.
foreach([
    "'beamex-cmx','cal-asfound-asleft-oot','partially_supported',0.970",
    "'beamex-cmx','cal-field-offline','partially_supported',0.990",
    "'fluke-metcal-metteam','cal-asfound-asleft-oot','partially_supported',0.970",
    "'fluke-metcal-metteam','cal-field-offline','partially_supported',0.960",
    "'fluke-metcal-metteam','cal-enterprise-integration-scale','partially_supported',0.970",
    "'prime-pcx','cal-asset-scheduling','partially_supported',0.960",
    "'prime-pcx','cal-uncertainty-decision-rules','partially_supported',0.980",
    "'prime-pcx','cal-asfound-asleft-oot','partially_supported',0.960",
    "'prime-pcx','cal-regulated-audit','partially_supported',0.960",
    "'cybermetrics-gagetrak','cal-reference-traceability','partially_supported',0.960",
    "'cybermetrics-gagetrak','cal-asfound-asleft-oot','partially_supported',0.980",
    "'cybermetrics-gagetrak','cal-regulated-audit','partially_supported',0.990",
    "'cybermetrics-gagetrak','cal-enterprise-integration-scale','partially_supported',0.970"
] as $required){
    if(strpos($sql,$required)===false)$errors[]="Required calibration scope boundary missing: {$required}";
}

foreach([
    'dedicated impact-assessment workflow for every out-of-tolerance case is not inferred',
    'companion Beamex bMobile application rather than assumed as native functionality',
    'universal out-of-tolerance impact-assessment workflow is not inferred',
    'offline/detached behavior and entitlement should be verified',
    'global multi-site governance depth is not inferred',
    'full depth of advanced interval/scheduling logic',
    'full uncertainty-budget and decision-rule functionality should be verified',
    'complete out-of-tolerance impact workflow is not inferred',
    'legacy ProCalV5 regulatory claims are not automatically inherited',
    'metrological reference-chain depth is not inferred',
    'FDA 21 CFR Part 11 support requires the separate FDA Compliance Manager option',
    'global multi-site governance depth is not inferred'
] as $phrase){
    if(strpos($sql,$phrase)===false)$errors[]="Missing explicit calibration limitation text: {$phrase}";
}

// Keep unverified automation/field capabilities unknown instead of treating generic calibration management as automation.
$mustRemainUnknown=[
    ['indysoft-calibration-management','cal-instrument-automation'],
    ['prime-pcx','cal-field-offline'],
    ['prime-pcx','cal-enterprise-integration-scale'],
    ['cybermetrics-gagetrak','cal-uncertainty-decision-rules'],
    ['cybermetrics-gagetrak','cal-instrument-automation'],
    ['cybermetrics-gagetrak','cal-field-offline']
];
foreach($mustRemainUnknown as [$product,$cap]){
    if(strpos($sql,"'{$product}','{$cap}','supported'")!==false ||
       strpos($sql,"'{$product}','{$cap}','partially_supported'")!==false){
        $errors[]="Unverified capability must remain not_yet_verified: {$product} / {$cap}";
    }
}

// Deployment is promoted only from explicit product-specific evidence.
if(strpos($sql,"WHERE p.slug IN('beamex-cmx','cybermetrics-gagetrak')")===false){
    $errors[]='Explicit calibration on-premises deployment set is missing or broadened.';
}
if(strpos($sql,"WHERE p.slug='prime-pcx'")===false){
    $errors[]='PCX explicit public-SaaS deployment evidence must remain present.';
}
foreach([
    'Beamex CMX also documents cloud installation and IndySoft offers IndySoft Cloud, but those deployment forms are not automatically mapped to this catalog\'s public-SaaS label without clearer commercial-model evidence.',
    'Fluke MET/TEAM browser access is not treated as evidence of a public-SaaS deployment model.'
] as $phrase){
    if(strpos($sql,$phrase)===false)$errors[]="Missing deployment inference guard: {$phrase}";
}
if(preg_match('/INSERT INTO product_deployments.*?d\.slug=\'public-saas\'.*?WHERE p\.slug=\'([^\']+)\'/s',$sql,$saasMatch)){
    if($saasMatch[1]!=='prime-pcx')$errors[]='Public SaaS promotion must remain limited to PCX in batch 135.';
} else {
    $errors[]='Could not isolate explicit public-SaaS product.';
}

// Companion apps/modules must not silently become core platform mobile support.
if(strpos($sql,"SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000")===false){
    $errors[]='Calibration mobile access must default to not_yet_verified.';
}
if(strpos($sql,'companion mobile/offline modules do not establish native Android/iOS/mobile-web support for the core product')===false){
    $errors[]='Calibration companion-mobile boundary must remain explicit.';
}
if(preg_match("/'supported','supported','vendor_documentation'.*WHERE p\.slug IN\([^;]*(beamex-cmx|fluke-metcal-metteam|indysoft-calibration-management|prime-pcx|cybermetrics-gagetrak)/s",$sql)){
    $errors[]='Do not infer platform-specific mobile support from field, browser or companion-module evidence.';
}

if($errors){
    fwrite(STDERR,"Calibration & metrology catalog check failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}

echo "Calibration & metrology catalog contract passed: 1 canonical category, 5 current products, first-party evidence, metrology-specific capability boundaries, explicit unknowns, conservative deployment/mobile handling and ranking neutrality.\n";
