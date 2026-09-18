<?php

declare(strict_types=1);

$root=dirname(__DIR__);
$migration=$root.'/db/mysql/121_warehouse_execution_control_systems_catalog.sql';
$sql=@file_get_contents($migration);
$errors=[];

if($sql===false){
    fwrite(STDERR,"Missing migration: db/mysql/121_warehouse_execution_control_systems_catalog.sql\n");
    exit(1);
}

$category='warehouse-execution-control-systems';
$products=[
    'honeywell-momentum-wes',
    'fortna-wes',
    'dematic-warehouse-execution-system',
    'swisslog-synq',
    'blue-yonder-warehouse-execution'
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
    'wes-task-prioritization','wes-human-robot-orchestration','wes-resource-labor-optimization',
    'wes-inventory-workflow','wes-automation-integration','wes-material-flow-control',
    'wes-host-integration','wes-visibility-exceptions','wes-analytics-kpis','wes-simulation-digital-twin'
] as $needle){
    if(strpos($sql,$needle)===false)$errors[]="Missing WES/WCS invariant: {$needle}";
}

$allowedHosts=[
    'honeywell.com','www.honeywell.com','automation.honeywell.com',
    'fortna.com','www.fortna.com',
    'dematic.com','www.dematic.com',
    'swisslog.com','www.swisslog.com',
    'blueyonder.com','www.blueyonder.com','media.blueyonder.com'
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
if(preg_match('/INSERT INTO cat121_sources VALUES\s*(.*?);\s*\n\s*INSERT INTO evidence_sources/is',$sql,$sm)){
    preg_match_all("/\\('(?:''|[^'])*','(https:\/\/(?:''|[^'])+)'/",$sm[1],$sourceMatches);
    $registered=array_fill_keys($sourceMatches[1]??[],true);
    if(preg_match('/INSERT INTO cat121_facts VALUES\s*(.*?);\s*\n\s*INSERT INTO product_capabilities/is',$sql,$fm)){
        preg_match_all("/\\('(?:''|[^'])*','(?:''|[^'])*','(?:''|[^'])*',[0-9.]+,'(?:''|[^'])*','(https:\/\/(?:''|[^'])+)'\\)/",$fm[1],$factMatches);
        foreach(array_unique($factMatches[1]??[]) as $url){
            if(!isset($registered[$url]))$errors[]="Capability source URL is not registered in cat121_sources: {$url}";
        }
    } else {
        $errors[]='Could not parse cat121_facts block for evidence-link validation.';
    }
} else {
    $errors[]='Could not parse cat121_sources block for evidence-link validation.';
}

// WES orchestration must not be conflated with separate WCS/device-control products.
foreach([
    "'honeywell-momentum-wes','wes-material-flow-control','partially_supported',0.970",
    "'fortna-wes','wes-material-flow-control','partially_supported',0.980",
    "'dematic-warehouse-execution-system','wes-material-flow-control','partially_supported',0.970",
    "'blue-yonder-warehouse-execution','wes-material-flow-control','partially_supported',0.950"
] as $required){
    if(strpos($sql,$required)===false)$errors[]="Required WCS/control scope boundary missing: {$required}";
}
if(strpos($sql,'separate Momentum Core components')===false){
    $errors[]='Honeywell Momentum WCS/machine-control boundary must remain explicit.';
}
if(strpos($sql,'separate FORTNA WCS product')===false){
    $errors[]='FORTNA WCS companion-product boundary must remain explicit.';
}
if(strpos($sql,'separate Dematic WCS layer')===false){
    $errors[]='Dematic WCS layer boundary must remain explicit.';
}
if(strpos($sql,'direct PLC/WCS machine-control functionality is not inferred')===false){
    $errors[]='Blue Yonder machine-control boundary must remain explicit.';
}

// Preserve other product-specific scope boundaries.
if(strpos($sql,"'swisslog-synq','wes-resource-labor-optimization','partially_supported',0.950")===false){
    $errors[]='SynQ labor/resource scope must remain partially_supported.';
}
if(strpos($sql,"'blue-yonder-warehouse-execution','wes-inventory-workflow','partially_supported',0.970")===false){
    $errors[]='Blue Yonder inventory/workflow scope must remain partial rather than full WMS inference.';
}
if(strpos($sql,"'blue-yonder-warehouse-execution','wes-analytics-kpis','partially_supported',0.960")===false){
    $errors[]='Blue Yonder WES analytics scope must remain partially_supported.';
}

// Simulation/digital twin is explicit for SynQ only in this batch.
if(strpos($sql,"'swisslog-synq','wes-simulation-digital-twin','supported',0.990")===false){
    $errors[]='SynQ digital twin / simulation evidence must remain explicit.';
}
foreach(['honeywell-momentum-wes','fortna-wes','dematic-warehouse-execution-system','blue-yonder-warehouse-execution'] as $slug){
    if(strpos($sql,"'{$slug}','wes-simulation-digital-twin','supported'")!==false ||
       strpos($sql,"'{$slug}','wes-simulation-digital-twin','partially_supported'")!==false){
        $errors[]="Simulation/digital-twin support must remain not_yet_verified for {$slug} in batch 121.";
    }
}

// SaaS promotion is intentionally limited to explicit product-specific evidence.
if(strpos($sql,"WHERE p.slug IN('honeywell-momentum-wes','blue-yonder-warehouse-execution')")===false){
    $errors[]='Explicit SaaS deployment set must remain Honeywell Momentum WES and Blue Yonder Warehouse Execution.';
}
if(preg_match('/-- Promote SaaS only where the product-specific vendor evidence is explicit\.(.*?)-- Do not infer Android\/iOS\/mobile-web/s',$sql,$dm)){
    foreach(['fortna-wes','dematic-warehouse-execution-system','swisslog-synq'] as $slug){
        if(strpos($dm[1],"'{$slug}'")!==false)$errors[]="Deployment must remain unverified for {$slug} unless product-specific evidence is added.";
    }
} else {
    $errors[]='Could not isolate WES/WCS deployment block.';
}

// Platform-specific mobile access remains unknown for all five products.
if(strpos($sql,"SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000")===false){
    $errors[]='WES/WCS mobile access must be inserted as not_yet_verified.';
}
if(preg_match("/'supported','supported','vendor_documentation'.*WHERE p\.slug IN\([^;]*(honeywell-momentum-wes|fortna-wes|dematic-warehouse-execution-system|swisslog-synq|blue-yonder-warehouse-execution)/s",$sql)){
    $errors[]='Do not infer Android/iOS/mobile-web support for WES/WCS products.';
}

if($errors){
    fwrite(STDERR,"WES/WCS catalog check failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}

echo "WES/WCS catalog contract passed: 1 canonical category, 5 current products, first-party evidence, exact evidence links, WES/WCS scope discipline, conservative deployment/mobile handling and ranking neutrality.\n";
