<?php
$root=dirname(__DIR__);
$sql=@file_get_contents($root.'/db/mysql/059_catalog_expansion_batch4.sql')?:'';
$guard=@file_get_contents($root.'/db/mysql/060_catalog_expansion_batch4_readiness_guard.sql')?:'';
$failed=[];

$categories=['siem-security-operations','identity-access-management','privileged-access-management','warehouse-management-systems','low-code-bpm'];
foreach($categories as $slug){if(strpos($sql,$slug)===false)$failed[]='missing category '.$slug;}

$products=[
'microsoft-sentinel','splunk-enterprise-security','ibm-qradar-siem','elastic-security',
'microsoft-entra-id','okta-workforce-identity','pingone-for-workforce','jumpcloud-identity-platform',
'cyberark-privilege-cloud','beyondtrust-password-safe','delinea-secret-server','manageengine-pam360',
'sap-extended-warehouse-management','oracle-fusion-cloud-warehouse-management','manhattan-active-warehouse-management','blue-yonder-warehouse-management',
'microsoft-power-apps','mendix-platform','outsystems-platform','appian-platform'];
foreach($products as $slug){if(substr_count($sql,$slug)<1)$failed[]='missing product '.$slug;if(strpos($guard,"'{$slug}'")===false)$failed[]='draft guard missing '.$slug;}

if(stripos($sql,'g2.com')!==false||stripos($sql,'capterra')!==false)$failed[]='restricted marketplace source present';
if(strpos($sql,"'not_supported'")!==false)$failed[]='not_supported used in seed migration';
if(strpos($sql,"'not_yet_verified'")===false)$failed[]='Unknown != Unsupported guard missing';
if(strpos($sql,'product_pricing')!==false)$failed[]='pricing must not be fabricated in batch 4';
if(strpos($sql,'product_compliance')!==false||strpos($sql,'compliance_facts')!==false)$failed[]='compliance must not be fabricated in batch 4';
if(strpos($sql,'regional_availability')!==false)$failed[]='regional availability must not be fabricated in batch 4';
if(strpos($guard,"SET status='draft'")===false)$failed[]='draft readiness guard missing';

if($failed){fwrite(STDERR,"Catalog expansion batch 4 contract FAILED\n - ".implode("\n - ",$failed)."\n");exit(1);}
echo "Catalog expansion batch 4 contract OK: 5 categories, 20 draft products, evidence guardrails present.\n";
