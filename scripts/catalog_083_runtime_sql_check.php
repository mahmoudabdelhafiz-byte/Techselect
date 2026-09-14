<?php
$path=__DIR__.'/../db/mysql/083_add_customer_service_collaboration_categories.sql';
$sql=file_get_contents($path);
$errors=[];
if(strpos($sql,"'Salesforce Service Cloud' title,'Salesforce' publisher")===false)$errors[]='083 evidence derived table must alias title and publisher explicitly';
if(strpos($sql,'x.url,x.title,x.publisher')===false)$errors[]='083 evidence insert must read the aliased source columns';
if(strpos($sql,'WHERE NOT EXISTS(SELECT 1 FROM evidence_sources')===false)$errors[]='083 evidence insert must remain rerunnable after a partial import';
if(strpos($sql,'ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id)')===false)$errors[]='083 product upsert must remain rerunnable after a partial import';
if($errors){fwrite(STDERR,implode("\n",$errors)."\n");exit(1);}echo "Catalog 083 runtime SQL contract passed.\n";
