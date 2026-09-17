<?php

declare(strict_types=1);

$root=dirname(__DIR__);
$migration=$root.'/db/mysql/107_expense_management_catalog.sql';
$sql=@file_get_contents($migration);
$errors=[];
if($sql===false){fwrite(STDERR,"Missing migration: db/mysql/107_expense_management_catalog.sql\n");exit(1);}

$category='expense-management';
$products=['concur-expense','expensify-expense-management','ramp-expense-management','emburse-expense-professional','brex-expenses'];

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
 'expense-receipt-capture','expense-report-submission','expense-policy-approvals',
 'expense-reimbursements','expense-accounting-integration','expense-reporting-analytics','expense-mobile'
] as $needle){
    if(strpos($sql,$needle)===false)$errors[]="Missing evidence/catalog invariant: {$needle}";
}

$allowedHosts=[
 'concur.com','www.concur.com',
 'use.expensify.com',
 'ramp.com','www.ramp.com','support.ramp.com',
 'emburse.com','www.emburse.com',
 'brex.com','www.brex.com','developer.brex.com',
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

if(strpos($sql,"'brex-expenses','expense-report-submission','partially_supported'")===false)$errors[]='Brex transaction-centric reporting boundary must remain explicit.';
if(strpos($sql,'transaction-centric spend records rather than a traditional report-first workflow')===false)$errors[]='Brex report-model limitation must remain explicit.';

foreach([
 "'ramp-expense-management','expense-mobile','supported'",
 "'brex-expenses','expense-mobile','supported'"
] as $forbidden){
    if(strpos($sql,$forbidden)!==false)$errors[]="Mobile expense support must remain not_yet_verified until product-specific mobile evidence is added: {$forbidden}";
}

foreach(['travel booking','bill pay','business banking'] as $scope){
    if(stripos($sql,$scope)!==false)$errors[]="107 must not promote adjacent spend-platform scope as an expense-management capability: {$scope}";
}

if($errors){
    fwrite(STDERR,"Expense management catalog check failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}
echo "Expense management catalog contract passed: 1 canonical category, 5 new products, first-party evidence, explicit unknowns, conservative mobile scope, duplicate protection and ranking neutrality.\n";
