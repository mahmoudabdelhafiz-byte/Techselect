<?php

declare(strict_types=1);

$root=dirname(__DIR__);
$migration=$root.'/db/mysql/110_mlops_ai_platform_catalog.sql';
$sql=@file_get_contents($migration);
$errors=[];
if($sql===false){fwrite(STDERR,"Missing migration: db/mysql/110_mlops_ai_platform_catalog.sql\n");exit(1);}

$category='mlops-machine-learning-platforms';
$products=['databricks-machine-learning','amazon-sagemaker-ai','domino-enterprise-mlops','azure-machine-learning','dataiku-mlops'];

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
 'mlops-experiment-tracking','mlops-pipelines','mlops-model-registry','mlops-feature-store','mlops-model-serving','mlops-model-monitoring'
] as $needle){
    if(strpos($sql,$needle)===false)$errors[]="Missing evidence/catalog invariant: {$needle}";
}

$allowedHosts=[
 'databricks.com','www.databricks.com','docs.databricks.com',
 'aws.amazon.com','docs.aws.amazon.com',
 'domino.ai','www.domino.ai','docs.dominodatalab.com',
 'microsoft.com','www.microsoft.com','azure.microsoft.com','learn.microsoft.com',
 'dataiku.com','www.dataiku.com','doc.dataiku.com',
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

foreach([
 "'amazon-sagemaker-ai','mlops-experiment-tracking','supported'",
 "'amazon-sagemaker-ai','mlops-model-monitoring','supported'",
 "'domino-enterprise-mlops','mlops-feature-store','supported'",
 "'azure-machine-learning','mlops-experiment-tracking','supported'",
 "'azure-machine-learning','mlops-pipelines','supported'"
] as $forbidden){
    if(strpos($sql,$forbidden)!==false)$errors[]="Capability must remain not_yet_verified until directly evidenced in 110: {$forbidden}";
}

if(strpos($sql,"'dataiku-mlops','mlops-pipelines','supported',0.970")===false)$errors[]='Dataiku pipeline support must preserve its implementation-model limitation.';
if(strpos($sql,'orchestration differs from dedicated cloud pipeline services')===false)$errors[]='Dataiku pipeline boundary must remain explicit.';
if(strpos($sql,"'databricks-machine-learning','mlops-model-monitoring','supported',0.970")===false)$errors[]='Databricks monitoring capability must preserve workload-depth limitation.';

foreach(["'public-saas'","'on-premise'","'private-cloud'"] as $deployment){
    if(strpos($sql,$deployment)!==false)$errors[]="110 must not infer deployment support without selected-product deployment evidence: {$deployment}";
}
if(strpos($sql,'Deployment and mobile administration are intentionally not inferred in this first batch.')===false)$errors[]='Deployment/mobile inference guard must remain documented.';

if($errors){
    fwrite(STDERR,"MLOps catalog check failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}
echo "MLOps catalog contract passed: 1 canonical category, 5 new products, first-party evidence, explicit unknowns, lifecycle boundaries, duplicate protection and ranking neutrality.\n";
