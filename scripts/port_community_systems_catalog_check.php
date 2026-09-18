<?php

declare(strict_types=1);

$root=dirname(__DIR__);
$migration=$root.'/db/mysql/122_port_community_systems_catalog.sql';
$sql=@file_get_contents($migration);
$errors=[];

if($sql===false){
    fwrite(STDERR,"Missing migration: db/mysql/122_port_community_systems_catalog.sql\n");
    exit(1);
}

$category='port-community-systems';
$products=[
    'kale-port-community-system',
    'soget-s-one',
    'webb-ports',
    'portall-port-community-system',
    'maqta-port-community-system'
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
    'pcs-stakeholder-collaboration','pcs-single-window','pcs-vessel-clearance',
    'pcs-customs-regulatory','pcs-digital-documents','pcs-cargo-visibility',
    'pcs-tos-carrier-inland-integration','pcs-payments-billing','pcs-truck-gate-coordination',
    'pcs-edi-api-connectivity','pcs-analytics-forecasting'
] as $needle){
    if(strpos($sql,$needle)===false)$errors[]="Missing PCS invariant: {$needle}";
}

$allowedHosts=[
    'kalelogistics.com','www.kalelogistics.com',
    'soget.fr','www.soget.fr',
    'webbfontaine.com','www.webbfontaine.com','portfolio.webbfontaine.com',
    'portall.in','www.portall.in',
    'adportsgroup.com','www.adportsgroup.com','wpvip.adportsgroup.com'
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
if(preg_match('/INSERT INTO cat122_sources VALUES\s*(.*?);\s*\n\s*INSERT INTO evidence_sources/is',$sql,$sm)){
    preg_match_all("/\\('(?:''|[^'])*','(https:\/\/(?:''|[^'])+)'/",$sm[1],$sourceMatches);
    $registered=array_fill_keys($sourceMatches[1]??[],true);
    if(preg_match('/INSERT INTO cat122_facts VALUES\s*(.*?);\s*\n\s*INSERT INTO product_capabilities/is',$sql,$fm)){
        preg_match_all("/\\('(?:''|[^'])*','(?:''|[^'])*','(?:''|[^'])*',[0-9.]+,'(?:''|[^'])*','(https:\/\/(?:''|[^'])+)'\\)/",$fm[1],$factMatches);
        foreach(array_unique($factMatches[1]??[]) as $url){
            if(!isset($registered[$url]))$errors[]="Capability source URL is not registered in cat122_sources: {$url}";
        }
    } else {
        $errors[]='Could not parse cat122_facts block for evidence-link validation.';
    }
} else {
    $errors[]='Could not parse cat122_sources block for evidence-link validation.';
}

// Preserve companion-service and scope boundaries.
foreach([
    "'kale-port-community-system','pcs-truck-gate-coordination','partially_supported',0.950",
    "'soget-s-one','pcs-truck-gate-coordination','partially_supported',0.980",
    "'soget-s-one','pcs-analytics-forecasting','partially_supported',0.970",
    "'webb-ports','pcs-edi-api-connectivity','partially_supported',0.970",
    "'portall-port-community-system','pcs-edi-api-connectivity','partially_supported',0.970",
    "'maqta-port-community-system','pcs-customs-regulatory','partially_supported',0.960",
    "'maqta-port-community-system','pcs-cargo-visibility','partially_supported',0.950",
    "'maqta-port-community-system','pcs-truck-gate-coordination','partially_supported',0.970"
] as $required){
    if(strpos($sql,$required)===false)$errors[]="Required PCS scope boundary missing: {$required}";
}

foreach([
    'standalone truck-appointment module is not inferred',
    'TAS Truck Appointment System as a complementary S ONE service',
    'Business Intelligence as an additional service around S ONE',
    'universal public API catalogue is not inferred',
    'general-purpose public API catalogue is not inferred',
    'exact customs feature set bundled in every mPCS deployment is not inferred',
    'separate Manara application',
    'truck management is not assumed to be universally bundled in core mPCS'
] as $phrase){
    if(strpos($sql,$phrase)===false)$errors[]="Missing explicit PCS limitation text: {$phrase}";
}

// Keep unverified areas unknown rather than assuming parity across PCS products.
$mustRemainUnknown=[
    ['kale-port-community-system','pcs-payments-billing'],
    ['kale-port-community-system','pcs-edi-api-connectivity'],
    ['kale-port-community-system','pcs-analytics-forecasting'],
    ['soget-s-one','pcs-payments-billing'],
    ['webb-ports','pcs-cargo-visibility'],
    ['webb-ports','pcs-truck-gate-coordination'],
    ['portall-port-community-system','pcs-truck-gate-coordination'],
    ['maqta-port-community-system','pcs-vessel-clearance'],
    ['maqta-port-community-system','pcs-digital-documents'],
    ['maqta-port-community-system','pcs-payments-billing'],
    ['maqta-port-community-system','pcs-edi-api-connectivity'],
    ['maqta-port-community-system','pcs-analytics-forecasting']
];
foreach($mustRemainUnknown as [$product,$cap]){
    if(strpos($sql,"'{$product}','{$cap}','supported'")!==false ||
       strpos($sql,"'{$product}','{$cap}','partially_supported'")!==false){
        $errors[]="Unverified capability must remain not_yet_verified: {$product} / {$cap}";
    }
}

// Deployment remains unknown in this batch: cloud-hosted or internationally deployed != SaaS.
if(strpos($sql,'INSERT INTO product_deployments')!==false){
    $errors[]='Do not promote PCS deployment models in batch 122; reviewed evidence does not justify a common SaaS/on-prem classification.';
}
if(strpos($sql,'Cloud-hosted or internationally deployed does not automatically mean public SaaS.')===false){
    $errors[]='PCS deployment inference warning must remain explicit.';
}

// Platform-specific mobile access remains unknown for all five products.
if(strpos($sql,"SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000")===false){
    $errors[]='PCS mobile access must be inserted as not_yet_verified.';
}
if(preg_match("/'supported','supported','vendor_documentation'.*WHERE p\.slug IN\([^;]*(kale-port-community-system|soget-s-one|webb-ports|portall-port-community-system|maqta-port-community-system)/s",$sql)){
    $errors[]='Do not infer Android/iOS/mobile-web support for PCS products.';
}

if($errors){
    fwrite(STDERR,"PCS catalog check failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}

echo "PCS catalog contract passed: 1 canonical category, 5 current products, first-party evidence, exact evidence links, explicit companion-service limits, unknown deployment/mobile handling and ranking neutrality.\n";
