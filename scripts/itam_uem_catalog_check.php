<?php

declare(strict_types=1);

$root=dirname(__DIR__);
$migration=$root.'/db/mysql/105_itam_uem_catalog.sql';
$sql=@file_get_contents($migration);
$errors=[];
if($sql===false){fwrite(STDERR,"Missing migration: db/mysql/105_itam_uem_catalog.sql\n");exit(1);}

$categories=['it-asset-management','unified-endpoint-management'];
$products=[
 'lansweeper-it-asset-management','flexera-one-itam','servicenow-it-asset-management','manageengine-assetexplorer',
 'microsoft-intune','omnissa-workspace-one-uem','manageengine-endpoint-central','hexnode-uem',
];

foreach($categories as $slug){
    if(strpos($sql,"'{$slug}'")===false)$errors[]="Missing category {$slug}";
}
foreach($products as $slug){
    if(substr_count($sql,"'{$slug}'")<3)$errors[]="Product {$slug} is not carried through product/evidence/mobile or deployment rows";
}

$migrations=glob($root.'/db/mysql/*.sql')?:[];
foreach(array_merge($categories,$products) as $slug){
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
 'itam-discovery-inventory','itam-asset-lifecycle','itam-software-license-management','itam-contract-purchase-management','itam-cmdb-itsm-integration',
 'uem-cross-platform-management','uem-enrollment-provisioning','uem-configuration-policy','uem-application-management','uem-patch-update-management','uem-compliance-security','uem-remote-support'
] as $needle){
    if(strpos($sql,$needle)===false)$errors[]="Missing evidence/catalog invariant: {$needle}";
}

$allowedHosts=[
 'lansweeper.com','www.lansweeper.com',
 'flexera.com','www.flexera.com',
 'servicenow.com','www.servicenow.com',
 'manageengine.com','www.manageengine.com','download.manageengine.com',
 'microsoft.com','www.microsoft.com',
 'omnissa.com','www.omnissa.com','docs.omnissa.com',
 'hexnode.com','www.hexnode.com',
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

// Preserve evidence boundaries rather than turning Unknown into Unsupported or unsupported claims into Supported.
foreach([
 "'lansweeper-it-asset-management','itam-asset-lifecycle'",
 "'lansweeper-it-asset-management','itam-software-license-management'",
 "'lansweeper-it-asset-management','itam-contract-purchase-management'",
 "'lansweeper-it-asset-management','uem-",
 "'omnissa-workspace-one-uem','uem-remote-support'",
 "'microsoft-intune','uem-remote-support'"
] as $forbiddenFact){
    if(strpos($sql,$forbiddenFact)!==false)$errors[]="Capability must remain not_yet_verified unless separately evidenced: {$forbiddenFact}";
}

if(strpos($sql,"'hexnode-uem','uem-patch-update-management','supported'")===false)$errors[]='Hexnode patch/update support with limitation must remain explicit.';
if(strpos($sql,'exact coverage differs by platform and plan')===false)$errors[]='Hexnode patch/update platform/plan limitation must remain explicit.';
if(strpos($sql,'Mobile administration is not inferred from managed-device agents/apps.')===false)$errors[]='Mobile-app inference guard must remain documented.';

if($errors){
    fwrite(STDERR,"ITAM/UEM catalog check failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}
echo "ITAM/UEM catalog contract passed: 2 canonical categories, 8 new products, first-party evidence, explicit unknowns, deployment/mobile coverage, duplicate protection and ranking neutrality.\n";
