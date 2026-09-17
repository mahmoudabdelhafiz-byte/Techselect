<?php

declare(strict_types=1);

$root=dirname(__DIR__);
$migration=$root.'/db/mysql/106_contract_lifecycle_management_catalog.sql';
$sql=@file_get_contents($migration);
$errors=[];
if($sql===false){fwrite(STDERR,"Missing migration: db/mysql/106_contract_lifecycle_management_catalog.sql\n");exit(1);}

$category='contract-lifecycle-management';
$products=['ironclad-clm','icertis-contract-management','docusign-clm','conga-clm','sirion-agentic-clm','agiloft-clm'];

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
 'clm-authoring-templates','clm-workflow-approvals','clm-negotiation-redlining',
 'clm-repository-search','clm-obligations-renewals','clm-analytics-ai','clm-enterprise-integrations'
] as $needle){
    if(strpos($sql,$needle)===false)$errors[]="Missing evidence/catalog invariant: {$needle}";
}

$allowedHosts=[
 'ironcladapp.com','support.ironcladapp.com','developer.ironcladapp.com',
 'icertis.com','www.icertis.com',
 'docusign.com','www.docusign.com',
 'conga.com','www.conga.com','documentation.conga.com',
 'sirion.ai','www.sirion.ai',
 'agiloft.com','www.agiloft.com','help.agiloft.com',
];
preg_match_all('#https://[^\s\'\"]+#',$sql,$matches);
foreach(array_unique($matches[0]??[]) as $url){
    $url=rtrim($url,');,');
    $host=strtolower((string)parse_url($url,PHP_URL_HOST));
    if($host===''||!in_array($host,$allowedHosts,true))$errors[]="Non-first-party or unapproved host: {$host} ({$url})";
}

foreach(['consultation_recommendations','recommendation_rank','Scoring::','overall_score','fit_score'] as $needle){
    if(stripos($sql,$needle)!==false)$errors[]="Catalog migration must not affect ranking/scoring: {$needle}";
}

// Keep package/product boundaries explicit.
if(strpos($sql,"'conga-clm','clm-analytics-ai','supported',0.950")===false)$errors[]='Conga analytics/AI edition limitation must remain explicit.';
if(strpos($sql,'deeper AI/Contract Intelligence capabilities may depend on edition or companion products')===false)$errors[]='Conga Contract Intelligence boundary must remain explicit.';
if(strpos($sql,"WHERE p.slug IN('docusign-clm','conga-clm')")===false)$errors[]='Only deployment-explicit products should be promoted to public SaaS in 106.';
foreach(['ironclad-clm','icertis-contract-management','sirion-agentic-clm','agiloft-clm'] as $slug){
    if(preg_match("/WHERE p\.slug IN\([^;]*'".preg_quote($slug,'/')."'[^;]*\)\s*ON DUPLICATE KEY UPDATE support_status/s",$sql)) {
        $errors[]="Deployment must remain unverified in 106 for {$slug}";
    }
}
if(strpos($sql,'Mobile administrative scope is not inferred from general mobile availability.')===false)$errors[]='Mobile administration inference guard must remain documented.';

if($errors){
    fwrite(STDERR,"CLM catalog check failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}
echo "CLM catalog contract passed: 1 canonical category, 6 new products, first-party evidence, explicit unknowns, conservative deployment/mobile handling, duplicate protection and ranking neutrality.\n";
