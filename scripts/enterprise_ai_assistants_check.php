<?php

declare(strict_types=1);

$root=dirname(__DIR__);
$migration=$root.'/db/mysql/111_enterprise_ai_assistants_catalog.sql';
$sql=@file_get_contents($migration);
$errors=[];
if($sql===false){fwrite(STDERR,"Missing migration: db/mysql/111_enterprise_ai_assistants_catalog.sql\n");exit(1);}

$category='enterprise-ai-assistants';
$products=['chatgpt-enterprise','claude-enterprise','gemini-enterprise','microsoft-365-copilot','perplexity-enterprise'];

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
 'product_mobile_access',"'android'","'ios'","'mobile_web'",'last_reviewed_at','Unknown != Unsupported',
 'eai-chat-reasoning','eai-web-research','eai-business-connectors','eai-agents-workflows',
 'eai-enterprise-identity','eai-no-training-default','eai-retention-audit-governance'
] as $needle){
    if(strpos($sql,$needle)===false)$errors[]="Missing evidence/catalog invariant: {$needle}";
}

$allowedHosts=[
 'openai.com','www.openai.com','help.openai.com',
 'anthropic.com','www.anthropic.com',
 'cloud.google.com','docs.cloud.google.com',
 'microsoft.com','www.microsoft.com',
 'perplexity.ai','www.perplexity.ai',
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

if(strpos($sql,"'gemini-enterprise','eai-retention-audit-governance','partially_supported',0.950")===false)$errors[]='Gemini governance capability must preserve edition limitation.';
if(strpos($sql,'advanced sovereignty, encryption and compliance controls can be edition-dependent')===false)$errors[]='Gemini edition boundary must remain explicit.';
if(strpos($sql,'it requires a qualifying Microsoft 365 subscription')===false)$errors[]='Microsoft 365 Copilot qualifying-license dependency must remain explicit.';

foreach([
 "'gemini-enterprise','eai-no-training-default','supported'",
 "'microsoft-365-copilot','eai-no-training-default','supported'",
 "'microsoft-365-copilot','eai-retention-audit-governance','supported'",
 "'claude-enterprise','eai-web-research','supported'"
] as $forbidden){
    if(strpos($sql,$forbidden)!==false)$errors[]="Capability must remain not_yet_verified until directly evidenced in 111: {$forbidden}";
}

foreach(["'public-saas'","'on-premise'","'private-cloud'"] as $deployment){
    if(strpos($sql,$deployment)!==false)$errors[]="111 must not infer deployment model from assistant availability: {$deployment}";
}
if(strpos($sql,'Mobile support is not inferred from general vendor mobile apps in this first batch.')===false)$errors[]='Mobile inference guard must remain documented.';

if($errors){
    fwrite(STDERR,"Enterprise AI assistants catalog check failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}
echo "Enterprise AI assistants contract passed: 1 canonical category, 5 products, first-party evidence, explicit unknowns, plan boundaries, duplicate protection and ranking neutrality.\n";
