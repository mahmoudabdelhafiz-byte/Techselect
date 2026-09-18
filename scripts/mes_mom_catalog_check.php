<?php

declare(strict_types=1);

$root=dirname(__DIR__);
$migration=$root.'/db/mysql/118_manufacturing_execution_systems_mom_catalog.sql';
$sql=@file_get_contents($migration);
$errors=[];

if($sql===false){
    fwrite(STDERR,"Missing migration: db/mysql/118_manufacturing_execution_systems_mom_catalog.sql\n");
    exit(1);
}

$category='manufacturing-execution-systems-mom';
$products=[
    'siemens-opcenter-execution',
    'sap-digital-manufacturing',
    'aveva-manufacturing-execution-system',
    'delmia-apriso',
    'critical-manufacturing-mes'
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
    'mes-production-execution','mes-work-instructions-paperless','mes-scheduling-dispatch',
    'mes-wip-traceability-genealogy','mes-quality-compliance','mes-equipment-connectivity',
    'mes-oee-analytics','mes-labor-resource-management','mes-enterprise-integration','mes-multisite-standardization'
] as $needle){
    if(strpos($sql,$needle)===false)$errors[]="Missing MES/MOM invariant: {$needle}";
}

$allowedHosts=[
    'siemens.com','www.siemens.com',
    'sap.com','www.sap.com','help.sap.com',
    'aveva.com','www.aveva.com',
    '3ds.com','www.3ds.com',
    'criticalmanufacturing.com','www.criticalmanufacturing.com'
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

// Every promoted capability must resolve to a registered source URL.
if(preg_match('/INSERT INTO cat118_sources VALUES\s*(.*?);\s*\n\s*INSERT INTO evidence_sources/is',$sql,$sm)){
    preg_match_all("/\\('(?:''|[^'])*','(https:\/\/(?:''|[^'])+)'/",$sm[1],$sourceMatches);
    $registered=array_fill_keys($sourceMatches[1]??[],true);
    if(preg_match('/INSERT INTO cat118_facts VALUES\s*(.*?);\s*\n\s*INSERT INTO product_capabilities/is',$sql,$fm)){
        preg_match_all("/\\('(?:''|[^'])*','(?:''|[^'])*','(?:''|[^'])*',[0-9.]+,'(?:''|[^'])*','(https:\/\/(?:''|[^'])+)'\\)/",$fm[1],$factMatches);
        foreach(array_unique($factMatches[1]??[]) as $url){
            if(!isset($registered[$url]))$errors[]="Capability source URL is not registered in cat118_sources: {$url}";
        }
    } else {
        $errors[]='Could not parse cat118_facts block for evidence-link validation.';
    }
} else {
    $errors[]='Could not parse cat118_sources block for evidence-link validation.';
}

// Preserve evidence boundaries that distinguish core MES from adjacent modules.
if(strpos($sql,"'critical-manufacturing-mes','mes-labor-resource-management','partially_supported',0.950")===false){
    $errors[]='Critical Manufacturing labor/resource scope must remain partially_supported.';
}
if(strpos($sql,'a full standalone labor-management scope is not inferred')===false){
    $errors[]='Critical Manufacturing labor limitation must remain explicit.';
}
if(strpos($sql,'deeper advanced scheduling optimization may use separate/partner APS capabilities')===false){
    $errors[]='AVEVA scheduling boundary must preserve separate/partner APS caveat.';
}
if(strpos($sql,'exact functions vary by selected edition')===false &&
   strpos($sql,'exact work-instruction and electronic-record functions vary by selected Opcenter edition')===false){
    $errors[]='Siemens Opcenter edition boundary must remain explicit.';
}

// Deployment is only promoted where product-specific deployment evidence is explicit.
if(strpos($sql,"WHERE p.slug='sap-digital-manufacturing'")===false){
    $errors[]='SAP Digital Manufacturing cloud/SaaS deployment evidence must remain explicit.';
}
if(strpos($sql,"WHERE p.slug IN('aveva-manufacturing-execution-system','delmia-apriso','critical-manufacturing-mes')")===false){
    $errors[]='Explicit on-premises deployment rows for AVEVA, Apriso and Critical Manufacturing must remain present.';
}
if(preg_match('/-- Promote deployment only where current product-specific evidence is explicit\.(.*?)-- Do not infer platform-specific mobile access/s',$sql,$dm)){
    if(strpos($dm[1],"'siemens-opcenter-execution'")!==false){
        $errors[]='Siemens Opcenter deployment must remain unverified in this batch.';
    }
} else {
    $errors[]='Could not isolate MES deployment block.';
}

// Platform-specific mobile access remains unknown for all five products.
if(strpos($sql,"SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000")===false){
    $errors[]='MES mobile access must be inserted as not_yet_verified.';
}
if(preg_match("/'supported','supported','vendor_documentation'.*WHERE p\.slug IN\([^;]*(siemens-opcenter-execution|sap-digital-manufacturing|aveva-manufacturing-execution-system|delmia-apriso|critical-manufacturing-mes)/s",$sql)){
    $errors[]='Do not infer supported platform-specific mobile access for MES products.';
}

if($errors){
    fwrite(STDERR,"MES/MOM catalog check failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}

echo "MES/MOM catalog contract passed: 1 canonical category, 5 current products, first-party evidence, exact evidence links, explicit scope boundaries, conservative deployment/mobile handling and ranking neutrality.\n";
