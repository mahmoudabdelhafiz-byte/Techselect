<?php

declare(strict_types=1);

$root=dirname(__DIR__);
$path=$root.'/db/mysql/104_security_operations_catalog.sql';
$sql=@file_get_contents($path);
$errors=[];
if($sql===false){fwrite(STDERR,"Missing migration: db/mysql/104_security_operations_catalog.sql\n");exit(1);}

$categories=['siem-security-analytics','privileged-access-management'];
$products=[
 'microsoft-sentinel','splunk-enterprise-security','ibm-qradar-siem','google-security-operations',
 'cyberark-privileged-access-manager','beyondtrust-password-safe','delinea-secret-server','one-identity-safeguard-privileged-passwords',
];
foreach($categories as $slug) if(strpos($sql,"'{$slug}'")===false)$errors[]="Missing category {$slug}";
foreach($products as $slug){
 if(strpos($sql,"'{$slug}'")===false)$errors[]="Missing product {$slug}";
 if(substr_count($sql,"'{$slug}'")<3)$errors[]="Product {$slug} is not carried through product/evidence/mobile catalog rows";
}

foreach([
 'not_yet_verified',
 'product_capability_evidence',
 'vendor_documentation',
 "verification_status,confidence,checked_at",
 'product_mobile_access',
 "'android'",
 "'ios'",
 "'mobile_web'",
 'last_reviewed_at',
 'Unknown != Unsupported',
] as $needle) if(strpos($sql,$needle)===false)$errors[]="Missing evidence invariant: {$needle}";

$allowedHosts=[
 'microsoft.com','www.microsoft.com','learn.microsoft.com',
 'splunk.com','www.splunk.com',
 'ibm.com','www.ibm.com',
 'cloud.google.com',
 'cyberark.com','www.cyberark.com',
 'beyondtrust.com','www.beyondtrust.com','docs.beyondtrust.com',
 'delinea.com','www.delinea.com',
 'oneidentity.com','www.oneidentity.com','support.oneidentity.com',
];
preg_match_all('#https://[^\s\'\"]+#',$sql,$matches);
foreach(array_unique($matches[0]??[]) as $url){
 $url=rtrim($url,');,');
 $host=strtolower((string)parse_url($url,PHP_URL_HOST));
 if($host===''||!in_array($host,$allowedHosts,true))$errors[]="Non-first-party or unapproved evidence host: {$host} ({$url})";
}

foreach(['consultation_recommendations','recommendation_rank','Scoring::','overall_score'] as $needle){
 if(stripos($sql,$needle)!==false)$errors[]="Catalog migration must not affect ranking/scoring: {$needle}";
}

if(strpos($sql,"'splunk-enterprise-security','siem-soar-automation','partially_supported'")===false)$errors[]='Splunk SOAR edition limitation must remain explicit.';
if(strpos($sql,"'ibm-qradar-siem','siem-soar-automation'")!==false)$errors[]='IBM SOAR must remain unknown until separately verified.';
if(strpos($sql,"'delinea-secret-server','pam-jit-access'")!==false)$errors[]='Delinea JIT must remain unknown until separately verified.';
if(strpos($sql,"'one-identity-safeguard-privileged-passwords','pam-session-monitoring'")!==false)$errors[]='One Identity SPP session monitoring must remain unknown because privileged sessions are a separate Safeguard product.';

if($errors){fwrite(STDERR,"Security operations catalog check failed:\n- ".implode("\n- ",$errors)."\n");exit(1);}
echo "Security operations catalog contract passed: 2 categories, 8 products, first-party evidence, explicit unknowns, and ranking neutrality.\n";
