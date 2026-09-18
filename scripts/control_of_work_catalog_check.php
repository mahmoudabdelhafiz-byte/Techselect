<?php

declare(strict_types=1);

$root=dirname(__DIR__);
$migration=$root.'/db/mysql/134_digital_permit_control_of_work_catalog.sql';
$sql=@file_get_contents($migration);
$errors=[];

if($sql===false){
    fwrite(STDERR,"Missing migration: db/mysql/134_digital_permit_control_of_work_catalog.sql\n");
    exit(1);
}

$category='digital-permit-control-of-work';
$products=[
    'enablon-control-of-work',
    'sphera-control-of-work',
    'hexagon-j5-control-of-work',
    'intelex-permit-to-work',
    'ecoonline-permit-to-work'
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
    'cow-permit-lifecycle','cow-risk-jsa','cow-isolation-loto','cow-worker-authorization',
    'cow-simops-conflict','cow-mobile-field','cow-site-visualization',
    'cow-handover-coordination','cow-eam-workorder-integration','cow-audit-analytics'
] as $needle){
    if(strpos($sql,$needle)===false)$errors[]="Missing Control of Work invariant: {$needle}";
}

$allowedHosts=[
    'wolterskluwer.com','www.wolterskluwer.com',
    'sphera.com','www.sphera.com',
    'aliresources.hexagon.com','hexagon.com','www.hexagon.com',
    'intelex.com','www.intelex.com',
    'ecoonline.com','www.ecoonline.com'
];
preg_match_all('#https://[^\s\'\"]+#',$sql,$matches);
foreach(array_unique($matches[0]??[]) as $url){
    $url=rtrim($url,');,');
    $host=strtolower((string)parse_url($url,PHP_URL_HOST));
    if($host===''||!in_array($host,$allowedHosts,true))$errors[]="Non-first-party or unapproved host: {$host} ({$url})";
}

foreach(['g2.com','capterra','getapp','softwareadvice','consultation_recommendations','recommendation_rank','Scoring::','overall_score','fit_score'] as $needle){
    if(stripos($sql,$needle)!==false)$errors[]="Catalog migration contains prohibited source/ranking coupling: {$needle}";
}

// Every promoted capability must resolve to a registered first-party source URL.
if(preg_match('/INSERT INTO cat134_sources VALUES\s*(.*?);\s*\n\s*INSERT INTO evidence_sources/is',$sql,$sm)){
    preg_match_all("/\\('(?:''|[^'])*','(https:\/\/(?:''|[^'])+)'/",$sm[1],$sourceMatches);
    $registered=array_fill_keys($sourceMatches[1]??[],true);
    if(preg_match('/INSERT INTO cat134_facts VALUES\s*(.*?);\s*\n\s*INSERT INTO product_capabilities/is',$sql,$fm)){
        preg_match_all("/\\('(?:''|[^'])*','(?:''|[^'])*','(?:''|[^'])*',[0-9.]+,'(?:''|[^'])*','(https:\/\/(?:''|[^'])+)'\\)/",$fm[1],$factMatches);
        foreach(array_unique($factMatches[1]??[]) as $url){
            if(!isset($registered[$url]))$errors[]="Capability source URL is not registered in cat134_sources: {$url}";
        }
    } else {
        $errors[]='Could not parse cat134_facts block for evidence-link validation.';
    }
} else {
    $errors[]='Could not parse cat134_sources block for evidence-link validation.';
}

// Preserve suite/module and capability-depth boundaries.
foreach([
    "'enablon-control-of-work','cow-handover-coordination','partially_supported',0.970",
    "'sphera-control-of-work','cow-site-visualization','partially_supported',0.990",
    "'sphera-control-of-work','cow-handover-coordination','partially_supported',0.990",
    "'intelex-permit-to-work','cow-isolation-loto','partially_supported',0.970",
    "'intelex-permit-to-work','cow-simops-conflict','partially_supported',0.970",
    "'intelex-permit-to-work','cow-mobile-field','partially_supported',0.970",
    "'intelex-permit-to-work','cow-eam-workorder-integration','partially_supported',0.950",
    "'ecoonline-permit-to-work','cow-risk-jsa','partially_supported',0.980",
    "'ecoonline-permit-to-work','cow-isolation-loto','partially_supported',0.980",
    "'ecoonline-permit-to-work','cow-worker-authorization','partially_supported',0.980",
    "'ecoonline-permit-to-work','cow-simops-conflict','partially_supported',0.960",
    "'ecoonline-permit-to-work','cow-handover-coordination','partially_supported',0.970"
] as $required){
    if(strpos($sql,$required)===false)$errors[]="Required Control of Work scope boundary missing: {$required}";
}

foreach([
    'specialized applications rather than assumed base permit entitlement',
    'dedicated suite module; full diagram/P&ID entitlement is therefore not assumed',
    'dedicated isolation-point planning and dependency-management engine is not inferred',
    'automated SIMOPS incompatibility/risk-conflict logic is not inferred',
    'does not establish that every permit workflow/configuration is available identically offline',
    'direct prebuilt CMMS/EAM work-order integration for Permit to Work is not established',
    'dedicated in-permit JSA engine is not inferred',
    'dedicated isolation-point dependency planning is not inferred',
    'depends on companion contractor/access modules',
    'universal automated SIMOPS engine is not inferred',
    'dedicated shift-handover/logbook application is not inferred'
] as $phrase){
    if(strpos($sql,$phrase)===false)$errors[]="Missing explicit Control of Work limitation text: {$phrase}";
}

// Keep unverified capabilities unknown rather than inferring suite parity.
$mustRemainUnknown=[
    ['enablon-control-of-work','cow-eam-workorder-integration'],
    ['hexagon-j5-control-of-work','cow-worker-authorization'],
    ['hexagon-j5-control-of-work','cow-simops-conflict'],
    ['hexagon-j5-control-of-work','cow-handover-coordination'],
    ['intelex-permit-to-work','cow-worker-authorization'],
    ['intelex-permit-to-work','cow-site-visualization'],
    ['intelex-permit-to-work','cow-handover-coordination'],
    ['ecoonline-permit-to-work','cow-site-visualization'],
    ['ecoonline-permit-to-work','cow-eam-workorder-integration']
];
foreach($mustRemainUnknown as [$product,$cap]){
    if(strpos($sql,"'{$product}','{$cap}','supported'")!==false ||
       strpos($sql,"'{$product}','{$cap}','partially_supported'")!==false){
        $errors[]="Unverified capability must remain not_yet_verified: {$product} / {$cap}";
    }
}

// No commercial deployment model is promoted in this batch.
if(strpos($sql,'INSERT INTO product_deployments')!==false){
    $errors[]='Control of Work batch 134 must not promote deployment models without explicit commercial-model evidence.';
}
if(strpos($sql,"Deployment remains not_yet_verified for all five products in this batch.")===false){
    $errors[]='Explicit deployment non-inference comment is required.';
}

// Generic mobile capability does not establish Android/iOS/mobile-web product-platform evidence.
if(strpos($sql,"SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000")===false){
    $errors[]='Control of Work platform-specific mobile access must default to not_yet_verified.';
}
if(preg_match("/'supported','supported','vendor_documentation'.*WHERE p\.slug IN\([^;]*(enablon-control-of-work|sphera-control-of-work|hexagon-j5-control-of-work|intelex-permit-to-work|ecoonline-permit-to-work)/s",$sql)){
    $errors[]='Do not infer Android/iOS/mobile-web support from generic mobile/field capability.';
}

if($errors){
    fwrite(STDERR,"Control of Work catalog check failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}

echo "Control of Work catalog contract passed: 1 specialized category, 5 current products, first-party evidence, suite-depth boundaries, explicit unknowns, no deployment inference and ranking neutrality.\n";
