<?php

declare(strict_types=1);

$root=dirname(__DIR__);
$migration=$root.'/db/mysql/104_security_operations_catalog.sql';
$sql=@file_get_contents($migration);
$errors=[];
if($sql===false){fwrite(STDERR,"Missing migration: db/mysql/104_security_operations_catalog.sql\n");exit(1);}

foreach(['INSERT INTO categories','INSERT INTO modules','INSERT INTO capabilities'] as $needle){
    if(stripos($sql,$needle)!==false)$errors[]="104 must reuse canonical taxonomy; found {$needle}";
}
foreach(['siem-security-operations','privileged-access-management'] as $slug){
    if(strpos($sql,"'{$slug}'")===false)$errors[]="Missing canonical category {$slug}";
}
if(strpos($sql,"'siem-security-analytics'")!==false)$errors[]='Do not create the duplicate SIEM category slug siem-security-analytics.';

$products=[
 'google-security-operations','fortinet-fortisiem','sumo-logic-cloud-siem','rapid7-siem-insightidr',
 'netwrix-privilege-secure','keeperpam','arcon-pam',
];
foreach($products as $slug){
    if(substr_count($sql,"'{$slug}'")<3)$errors[]="Product {$slug} is not carried through product/evidence/mobile or deployment rows";
}

$migrations=glob($root.'/db/mysql/*.sql')?:[];
foreach($products as $slug){
    $hits=[];
    foreach($migrations as $file){
        if(realpath($file)===realpath($migration))continue;
        $text=@file_get_contents($file)?:'';
        if(strpos($text,"'{$slug}'")!==false)$hits[]=basename($file);
    }
    if($hits)$errors[]="Potential duplicate product shell {$slug} already exists in ".implode(', ',$hits);
}

foreach([
 'not_yet_verified','product_capability_evidence','vendor_documentation',
 'product_mobile_access',"'android'", "'ios'", "'mobile_web'",
 'product_deployments',"'public-saas'", "'on-premise'",'last_reviewed_at','Unknown != Unsupported',
] as $needle){
    if(strpos($sql,$needle)===false)$errors[]="Missing evidence/catalog invariant: {$needle}";
}

$allowedHosts=[
 'cloud.google.com',
 'fortinet.com','www.fortinet.com',
 'sumologic.com','www.sumologic.com',
 'rapid7.com','www.rapid7.com','help.rapid7.com','docs.rapid7.com',
 'netwrix.com','www.netwrix.com','docs.netwrix.com',
 'keepersecurity.com','www.keepersecurity.com',
 'arconnet.com','www.arconnet.com',
];
preg_match_all('#https://[^\s\'\"]+#',$sql,$matches);
foreach(array_unique($matches[0]??[]) as $url){
    $url=rtrim($url,');,');
    $host=strtolower((string)parse_url($url,PHP_URL_HOST));
    if($host===''||!in_array($host,$allowedHosts,true))$errors[]="Non-first-party or unapproved host: {$host} ({$url})";
}

foreach(['consultation_recommendations','recommendation_rank','Scoring::','overall_score'] as $needle){
    if(stripos($sql,$needle)!==false)$errors[]="Catalog migration must not affect ranking/scoring: {$needle}";
}

if(strpos($sql,"'google-security-operations','siem-behavior-risk','partially_supported'")===false)$errors[]='Google UEBA/risk must preserve package limitation.';
if(strpos($sql,"'sumo-logic-cloud-siem','siem-soar'")!==false)$errors[]='Sumo Logic SOAR must remain unknown for the Cloud SIEM product until bundled entitlement is verified.';
if(strpos($sql,"'netwrix-privilege-secure','pam-rotation'")!==false)$errors[]='Netwrix password rotation must remain unknown until product-specific rotation support is verified.';
if(strpos($sql,"'arcon-pam','pam-rotation'")!==false)$errors[]='ARCON password rotation must remain unknown until PAM-product-specific automation is verified.';

foreach([
 'microsoft-sentinel','splunk-enterprise-security','ibm-qradar-siem','elastic-security','cortex-xsiam','exabeam-new-scale-siem',
 'cyberark-privilege-cloud','beyondtrust-password-safe','delinea-secret-server','manageengine-pam360','one-identity-safeguard-privileged-passwords','wallix-bastion'
] as $existing){
    if(strpos($sql,"'{$existing}'")!==false)$errors[]="104 must not re-add existing catalog peer {$existing}";
}

if($errors){fwrite(STDERR,"Security operations catalog check failed:\n- ".implode("\n- ",$errors)."\n");exit(1);}
echo "Security operations catalog contract passed: canonical SIEM/PAM taxonomy, 7 new peers, first-party evidence, explicit unknowns, deployment/mobile coverage, and ranking neutrality.\n";
