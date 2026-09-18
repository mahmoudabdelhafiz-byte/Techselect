<?php

declare(strict_types=1);

$root=dirname(__DIR__);
$migration=$root.'/db/mysql/128_industrial_scada_hmi_platforms_catalog.sql';
$sql=@file_get_contents($migration);
$errors=[];

if($sql===false){
    fwrite(STDERR,"Missing migration: db/mysql/128_industrial_scada_hmi_platforms_catalog.sql\n");
    exit(1);
}

$category='industrial-scada-hmi-platforms';
$products=[
    'inductive-automation-ignition',
    'simatic-wincc-unified',
    'factorytalk-view-se',
    'ge-vernova-cimplicity',
    'ecostruxure-geo-scada-expert'
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
    'scada-hmi-visualization-control','scada-alarm-event-management','scada-industrial-connectivity',
    'scada-web-mobile-remote','scada-historian-logging','scada-redundancy-high-availability',
    'scada-scripting-extensibility','scada-reporting-analytics','scada-enterprise-multisite',
    'scada-security-rbac-audit'
] as $needle){
    if(strpos($sql,$needle)===false)$errors[]="Missing SCADA/HMI invariant: {$needle}";
}

$allowedHosts=[
    'inductiveautomation.com','www.inductiveautomation.com',
    'siemens.com','www.siemens.com','support.industry.siemens.com','press.siemens.com',
    'rockwellautomation.com','www.rockwellautomation.com',
    'gevernova.com','www.gevernova.com',
    'se.com','www.se.com','download.se.com','eshop.se.com'
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
if(preg_match('/INSERT INTO cat128_sources VALUES\s*(.*?);\s*\n\s*INSERT INTO evidence_sources/is',$sql,$sm)){
    preg_match_all("/\\('(?:''|[^'])*','(https:\/\/(?:''|[^'])+)'/",$sm[1],$sourceMatches);
    $registered=array_fill_keys($sourceMatches[1]??[],true);
    if(preg_match('/INSERT INTO cat128_facts VALUES\s*(.*?);\s*\n\s*INSERT INTO product_capabilities/is',$sql,$fm)){
        preg_match_all("/\\('(?:''|[^'])*','(?:''|[^'])*','(?:''|[^'])*',[0-9.]+,'(?:''|[^'])*','(https:\/\/(?:''|[^'])+)'\\)/",$fm[1],$factMatches);
        foreach(array_unique($factMatches[1]??[]) as $url){
            if(!isset($registered[$url]))$errors[]="Capability source URL is not registered in cat128_sources: {$url}";
        }
    } else {
        $errors[]='Could not parse cat128_facts block for evidence-link validation.';
    }
} else {
    $errors[]='Could not parse cat128_sources block for evidence-link validation.';
}

// Preserve module/option/companion-product boundaries.
foreach([
    "'inductive-automation-ignition','scada-web-mobile-remote','partially_supported',0.990",
    "'inductive-automation-ignition','scada-historian-logging','partially_supported',0.990",
    "'inductive-automation-ignition','scada-reporting-analytics','partially_supported',0.980",
    "'inductive-automation-ignition','scada-enterprise-multisite','partially_supported',0.980",
    "'simatic-wincc-unified','scada-redundancy-high-availability','partially_supported',0.990",
    "'simatic-wincc-unified','scada-enterprise-multisite','partially_supported',0.970",
    "'factorytalk-view-se','scada-web-mobile-remote','partially_supported',0.980",
    "'factorytalk-view-se','scada-historian-logging','partially_supported',0.990",
    "'factorytalk-view-se','scada-reporting-analytics','partially_supported',0.970",
    "'ge-vernova-cimplicity','scada-historian-logging','partially_supported',0.990",
    "'ge-vernova-cimplicity','scada-security-rbac-audit','partially_supported',0.970",
    "'ecostruxure-geo-scada-expert','scada-web-mobile-remote','partially_supported',0.990",
    "'ecostruxure-geo-scada-expert','scada-reporting-analytics','partially_supported',0.970",
    "'ecostruxure-geo-scada-expert','scada-security-rbac-audit','partially_supported',0.960"
] as $required){
    if(strpos($sql,$required)===false)$errors[]="Required SCADA/HMI scope boundary missing: {$required}";
}

foreach([
    'Perspective is a module rather than assumed in every platform configuration',
    'modular rather than universal in every license configuration',
    'Enterprise Administration for centralized management of multiple Ignition installations',
    'redundancy requires a separate option license',
    'FactoryTalk ViewPoint provides web-client access',
    'FactoryTalk Historian SE is a separate historian product',
    'separate Proficy Historian product is not treated as universally bundled',
    'WebX and mobile access are licensed components',
    'broad enterprise BI/reporting suite is not inferred'
] as $phrase){
    if(strpos($sql,$phrase)===false)$errors[]="Missing explicit SCADA/HMI limitation text: {$phrase}";
}

// Keep unverified product capabilities unknown instead of assuming suite parity.
$mustRemainUnknown=[
    ['inductive-automation-ignition','scada-redundancy-high-availability'],
    ['inductive-automation-ignition','scada-security-rbac-audit'],
    ['simatic-wincc-unified','scada-reporting-analytics'],
    ['simatic-wincc-unified','scada-security-rbac-audit'],
    ['factorytalk-view-se','scada-enterprise-multisite'],
    ['factorytalk-view-se','scada-security-rbac-audit']
];
foreach($mustRemainUnknown as [$product,$cap]){
    if(strpos($sql,"'{$product}','{$cap}','supported'")!==false ||
       strpos($sql,"'{$product}','{$cap}','partially_supported'")!==false){
        $errors[]="Unverified capability must remain not_yet_verified: {$product} / {$cap}";
    }
}

// Deployment: explicit on-premises set only; GE remains unverified and no public-SaaS inference.
if(strpos($sql,"WHERE p.slug IN('inductive-automation-ignition','simatic-wincc-unified','factorytalk-view-se','ecostruxure-geo-scada-expert')")===false){
    $errors[]='Explicit SCADA on-premises deployment set is missing or broadened.';
}
if(strpos($sql,"d.slug='public-saas'")!==false){
    $errors[]='Do not promote public SaaS in SCADA batch 128.';
}
if(preg_match('/-- Promote on-premises deployment only where current product-specific evidence is explicit\.(.*?)-- GE documents cloud\/hybrid support/s',$sql,$dm)){
    if(strpos($dm[1],"'ge-vernova-cimplicity'")!==false){
        $errors[]='CIMPLICITY deployment must remain unverified in batch 128.';
    }
} else {
    $errors[]='Could not isolate SCADA deployment block.';
}

// Mobile/platform support is promoted only where current evidence is explicit.
foreach(["'inductive-automation-ignition'","'simatic-wincc-unified'","'factorytalk-view-se'","'ge-vernova-cimplicity'","'ecostruxure-geo-scada-expert'"] as $slug){
    if(strpos($sql,$slug)===false)$errors[]="Missing SCADA product mobile scope: {$slug}";
}
if(strpos($sql,"WHERE p.slug='inductive-automation-ignition'")===false){
    $errors[]='Ignition explicit Android/iOS/mobile-web support block must remain present.';
}
if(strpos($sql,"WHERE p.slug IN('simatic-wincc-unified','factorytalk-view-se','ge-vernova-cimplicity','ecostruxure-geo-scada-expert')")===false){
    $errors[]='Explicit mobile-web product set is missing or broadened.';
}
foreach(['simatic-wincc-unified','factorytalk-view-se','ge-vernova-cimplicity','ecostruxure-geo-scada-expert'] as $slug){
    foreach(['android','ios'] as $platform){
        if(strpos($sql,"'{$slug}','{$platform}','supported'")!==false){
            $errors[]="Do not infer native {$platform} support for {$slug}.";
        }
    }
}

if($errors){
    fwrite(STDERR,"Industrial SCADA/HMI catalog check failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}

echo "Industrial SCADA/HMI catalog contract passed: 1 canonical category, 5 current products, first-party evidence, module/companion boundaries, explicit unknowns, deployment/mobile discipline and ranking neutrality.\n";
