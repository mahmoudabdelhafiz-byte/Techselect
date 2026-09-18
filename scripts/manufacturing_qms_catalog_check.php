<?php

declare(strict_types=1);

$root=dirname(__DIR__);
$migration=$root.'/db/mysql/126_manufacturing_quality_management_eqms_catalog.sql';
$sql=@file_get_contents($migration);
$errors=[];

if($sql===false){
    fwrite(STDERR,"Missing migration: db/mysql/126_manufacturing_quality_management_eqms_catalog.sql\n");
    exit(1);
}

$category='manufacturing-quality-management-eqms';
$products=[
    'etq-reliance',
    'mastercontrol-quality-excellence',
    'siemens-opcenter-x-quality',
    'ideagen-quality-management',
    'qt9-qms'
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
    'qms-document-change-control','qms-capa','qms-nonconformance-deviation','qms-audit-management',
    'qms-training-competency','qms-supplier-quality','qms-inspection-spc','qms-risk-fmea',
    'qms-regulated-records','qms-quality-analytics','qms-enterprise-integration'
] as $needle){
    if(strpos($sql,$needle)===false)$errors[]="Missing QMS invariant: {$needle}";
}

$allowedHosts=[
    'etq.com','www.etq.com','host.etq.com',
    'mastercontrol.com','www.mastercontrol.com',
    'siemens.com','www.siemens.com','blogs.sw.siemens.com',
    'ideagen.com','www.ideagen.com',
    'qt9software.com','www.qt9software.com'
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
if(preg_match('/INSERT INTO cat126_sources VALUES\s*(.*?);\s*\n\s*INSERT INTO evidence_sources/is',$sql,$sm)){
    preg_match_all("/\\('(?:''|[^'])*','(https:\/\/(?:''|[^'])+)'/",$sm[1],$sourceMatches);
    $registered=array_fill_keys($sourceMatches[1]??[],true);
    if(preg_match('/INSERT INTO cat126_facts VALUES\s*(.*?);\s*\n\s*INSERT INTO product_capabilities/is',$sql,$fm)){
        preg_match_all("/\\('(?:''|[^'])*','(?:''|[^'])*','(?:''|[^'])*',[0-9.]+,'(?:''|[^'])*','(https:\/\/(?:''|[^'])+)'\\)/",$fm[1],$factMatches);
        foreach(array_unique($factMatches[1]??[]) as $url){
            if(!isset($registered[$url]))$errors[]="Capability source URL is not registered in cat126_sources: {$url}";
        }
    } else {
        $errors[]='Could not parse cat126_facts block for evidence-link validation.';
    }
} else {
    $errors[]='Could not parse cat126_sources block for evidence-link validation.';
}

// Preserve partial/add-on/product-scope boundaries.
foreach([
    "'etq-reliance','qms-inspection-spc','partially_supported',0.970",
    "'etq-reliance','qms-risk-fmea','partially_supported',0.970",
    "'etq-reliance','qms-regulated-records','partially_supported',0.970",
    "'mastercontrol-quality-excellence','qms-supplier-quality','partially_supported',0.990",
    "'mastercontrol-quality-excellence','qms-risk-fmea','partially_supported',0.970",
    "'mastercontrol-quality-excellence','qms-quality-analytics','partially_supported',0.970",
    "'siemens-opcenter-x-quality','qms-capa','partially_supported',0.960",
    "'siemens-opcenter-x-quality','qms-regulated-records','partially_supported',0.950",
    "'ideagen-quality-management','qms-risk-fmea','partially_supported',0.960",
    "'ideagen-quality-management','qms-regulated-records','partially_supported',0.970",
    "'qt9-qms','qms-inspection-spc','partially_supported',0.970"
] as $required){
    if(strpos($sql,$required)===false)$errors[]="Required QMS scope boundary missing: {$required}";
}

foreach([
    'does not establish a native SPC package equivalent to dedicated SPC products',
    'universal FMEA entitlement is not inferred',
    'universal electronic-signature scope depends on licensed applications',
    'presented as an add-on rather than assumed core Quality Excellence entitlement',
    'FMEA-specific functionality is not inferred',
    'Data & Analytics as an add-on',
    'full enterprise CAPA lifecycle is not inferred',
    'does not establish broad e-signature/Part 11 parity',
    'FMEA-specific scope is not inferred',
    'exact electronic-signature/validation scope should be confirmed',
    'dedicated SPC depth is not inferred'
] as $phrase){
    if(strpos($sql,$phrase)===false)$errors[]="Missing explicit QMS limitation text: {$phrase}";
}

// Siemens Opcenter X Quality must not inherit broad enterprise-QMS functions without evidence.
$siemensUnknown=[
    'qms-document-change-control',
    'qms-audit-management',
    'qms-training-competency',
    'qms-risk-fmea'
];
foreach($siemensUnknown as $cap){
    if(strpos($sql,"'siemens-opcenter-x-quality','{$cap}','supported'")!==false ||
       strpos($sql,"'siemens-opcenter-x-quality','{$cap}','partially_supported'")!==false){
        $errors[]="Siemens Opcenter X Quality capability must remain not_yet_verified: {$cap}";
    }
}

// Deployment promotion is intentionally narrow and explicit.
if(strpos($sql,"WHERE p.slug IN('etq-reliance','mastercontrol-quality-excellence','siemens-opcenter-x-quality','qt9-qms')")===false){
    $errors[]='Explicit QMS public-SaaS deployment set is missing or broadened.';
}
if(strpos($sql,"WHERE p.slug='qt9-qms'")===false){
    $errors[]='QT9 QMS explicit on-premises deployment evidence must remain present.';
}
if(preg_match('/-- Promote deployment only where the current product-specific evidence is explicit\.(.*?)-- Do not infer Android\/iOS\/mobile-web/s',$sql,$dm)){
    if(strpos($dm[1],"'ideagen-quality-management'")!==false){
        $errors[]='Ideagen Quality Management deployment must remain unverified in batch 126.';
    }
} else {
    $errors[]='Could not isolate QMS deployment block.';
}

// Platform-specific mobile access remains unknown for all five products.
if(strpos($sql,"SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000")===false){
    $errors[]='QMS mobile access must default to not_yet_verified.';
}
if(preg_match("/'supported','supported','vendor_documentation'.*WHERE p\.slug IN\([^;]*(etq-reliance|mastercontrol-quality-excellence|siemens-opcenter-x-quality|ideagen-quality-management|qt9-qms)/s",$sql)){
    $errors[]='Do not infer Android/iOS/mobile-web support from generic mobile/browser/cloud claims.';
}

if($errors){
    fwrite(STDERR,"Manufacturing QMS catalog check failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}

echo "Manufacturing QMS catalog contract passed: 1 canonical category, 5 current products, first-party evidence, add-on/scope boundaries, explicit unknowns, conservative deployment/mobile handling and ranking neutrality.\n";
