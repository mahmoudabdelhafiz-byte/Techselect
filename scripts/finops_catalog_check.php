<?php

declare(strict_types=1);

$root=dirname(__DIR__);
$migration=$root.'/db/mysql/112_finops_cloud_cost_catalog.sql';
$sql=@file_get_contents($migration);
$errors=[];
if($sql===false){fwrite(STDERR,"Missing migration: db/mysql/112_finops_cloud_cost_catalog.sql\n");exit(1);}

$category='finops-cloud-cost-management';
$products=['ibm-cloudability','cloudhealth-by-broadcom','finout-finops','ibm-kubecost','vantage-cloud-cost-management'];

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
 'finops-cost-visibility','finops-cost-allocation','finops-budget-forecast','finops-unit-economics',
 'finops-anomaly-detection','finops-rightsizing-optimization','finops-commitment-optimization','finops-kubernetes-cost'
] as $needle){
    if(strpos($sql,$needle)===false)$errors[]="Missing evidence/catalog invariant: {$needle}";
}

$allowedHosts=[
 'ibm.com','www.ibm.com',
 'apptio.com','www.apptio.com',
 'broadcom.com','www.broadcom.com','community.broadcom.com',
 'finout.io','www.finout.io',
 'vantage.sh','www.vantage.sh',
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

if(strpos($sql,"'ibm-cloudability','finops-kubernetes-cost','partially_supported',0.950")===false)$errors[]='Cloudability Kubernetes support must preserve add-on boundary.';
if(strpos($sql,'Cloudability Advanced Containers powered by Kubecost')===false)$errors[]='Cloudability Kubernetes add-on limitation must remain explicit.';

foreach([
 "'ibm-kubecost','finops-cost-visibility','supported'",
 "'ibm-kubecost','finops-budget-forecast','supported'",
 "'ibm-kubecost','finops-unit-economics','supported'",
 "'ibm-kubecost','finops-anomaly-detection','supported'",
 "'ibm-kubecost','finops-commitment-optimization','supported'"
] as $forbidden){
    if(strpos($sql,$forbidden)!==false)$errors[]="IBM Kubecost must remain narrowly scoped unless directly evidenced: {$forbidden}";
}

foreach(["'public-saas'","'on-premise'","'private-cloud'"] as $deployment){
    if(strpos($sql,$deployment)!==false)$errors[]="112 must not infer deployment model from hosted product availability: {$deployment}";
}

if(strpos($sql,'Deployment and mobile administration are not inferred')===false)$errors[]='Deployment/mobile inference guard must remain documented.';

if($errors){
    fwrite(STDERR,"FinOps catalog check failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}
echo "FinOps catalog contract passed: 1 canonical category, 5 current products, first-party evidence, explicit unknowns, package boundaries, duplicate protection and ranking neutrality.\n";
