<?php

declare(strict_types=1);

$root=dirname(__DIR__);
$migration=$root.'/db/mysql/109_enterprise_search_knowledge_catalog.sql';
$sql=@file_get_contents($migration);
$errors=[];
if($sql===false){fwrite(STDERR,"Missing migration: db/mysql/109_enterprise_search_knowledge_catalog.sql\n");exit(1);}

$category='enterprise-search-knowledge-discovery';
$products=['glean-search','coveo-platform','sinequa-enterprise-ai-search','guru-enterprise-ai-search','lucidworks-platform'];

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
 'es-connectors-indexing','es-relevance-search','es-permissions-aware','es-ai-answers','es-knowledge-curation','es-analytics-admin'
] as $needle){
    if(strpos($sql,$needle)===false)$errors[]="Missing evidence/catalog invariant: {$needle}";
}

$allowedHosts=[
 'glean.com','www.glean.com',
 'coveo.com','www.coveo.com','docs.coveo.com',
 'sinequa.com','www.sinequa.com',
 'getguru.com','www.getguru.com',
 'lucidworks.com','www.lucidworks.com',
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

if(stripos($sql,'elastic-workplace-search')!==false)$errors[]='Elastic Workplace Search must not be added as a current product.';
if(stripos($sql,'maintenance mode / not recommended for new search experiences')===false)$errors[]='Elastic maintenance-mode exclusion must remain documented.';

if(strpos($sql,"'coveo-platform','es-ai-answers','supported',0.990")===false)$errors[]='Coveo generative answering must remain explicitly evidenced.';
if(strpos($sql,'it is a paid product extension')===false)$errors[]='Coveo RGA paid-extension boundary must remain explicit.';
if(strpos($sql,"'lucidworks-platform','es-ai-answers','supported',0.970")===false)$errors[]='Lucidworks AI-answer support must preserve package limitation.';
if(strpos($sql,'exact agent modules depend on selected package')===false)$errors[]='Lucidworks package boundary must remain explicit.';

foreach([
 "'glean-search','es-knowledge-curation','supported'",
 "'coveo-platform','es-knowledge-curation','supported'",
 "'sinequa-enterprise-ai-search','es-knowledge-curation','supported'",
 "'lucidworks-platform','es-knowledge-curation','supported'"
] as $forbidden){
    if(strpos($sql,$forbidden)!==false)$errors[]="Knowledge curation must remain unknown unless directly evidenced: {$forbidden}";
}

if(strpos($sql,'Mobile administrative scope is not inferred from browser extensions, mobile access or collaboration integrations.')===false)$errors[]='Mobile inference guard must remain documented.';

if($errors){
    fwrite(STDERR,"Enterprise search catalog check failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}
echo "Enterprise search catalog contract passed: 1 canonical category, 5 current products, first-party evidence, deprecated-product exclusion, explicit unknowns, deployment/mobile boundaries and ranking neutrality.\n";
