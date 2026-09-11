<?php
$root=dirname(__DIR__);
$sql=@file_get_contents($root.'/db/mysql/061_catalog_expansion_batch5.sql')?:'';
$failed=[];
$categories=['observability-apm','network-monitoring','transportation-management-systems','document-management','e-signature'];
foreach($categories as $slug){if(strpos($sql,$slug)===false)$failed[]='missing category '.$slug;}
$products=[
'datadog-apm','new-relic-apm-360','dynatrace-application-observability','elastic-apm',
'solarwinds-network-performance-monitor','manageengine-opmanager','datadog-network-monitoring','logicmonitor-network-monitoring',
'sap-transportation-management','oracle-transportation-management','blue-yonder-transportation-management','descartes-transportation-manager',
'microsoft-sharepoint','m-files-document-management','opentext-content-management','box-intelligent-content-management',
'docusign-esignature','adobe-acrobat-sign','dropbox-sign','zoho-sign'];
foreach($products as $slug){if(strpos($sql,$slug)===false)$failed[]='missing product '.$slug;}
if(stripos($sql,'g2.com')!==false||stripos($sql,'capterra')!==false)$failed[]='restricted marketplace source present';
if(strpos($sql,"'not_supported'")!==false)$failed[]='not_supported used in seed migration';
if(strpos($sql,"'not_yet_verified'")===false)$failed[]='Unknown != Unsupported guard missing';
if(strpos($sql,"'draft',NOW()")===false)$failed[]='new products are not seeded as draft';
if(strpos($sql,'product_pricing')!==false)$failed[]='pricing must not be fabricated';
if(strpos($sql,'regional_availability')!==false)$failed[]='regional availability must not be fabricated';
if(strpos($sql,'company_software_relationship')!==false)$failed[]='partner relationships must not be fabricated';
if($failed){fwrite(STDERR,"Catalog expansion batch 5 contract FAILED\n - ".implode("\n - ",$failed)."\n");exit(1);}echo "Catalog expansion batch 5 contract OK: 5 categories, 20 draft products, evidence guardrails present.\n";
