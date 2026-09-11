<?php
$root=dirname(__DIR__);$checks=[
 'workspace route'=>['.htaccess','software-management'],
 'api route'=>['.htaccess','api/software-management'],
 'readiness service'=>['app/lib/SoftwareManagement.php','function readiness'],
 'reviewer activation guard'=>['api/software_management.php','reviewer_required_to_activate'],
 'activation readiness guard'=>['api/software_management.php','publishing_readiness_failed'],
 'safe bulk lifecycle'=>['api/software_management.php','bulk-status'],
 'audit update'=>['api/software_management.php','PRODUCT_UPDATE'],
 'audit bulk'=>['api/software_management.php','PRODUCT_BULK_STATUS'],
 'public page action'=>['software_management.php','View public page'],
 'detail tabs'=>['software_management.php','capabilities'],
 'admin nav'=>['app/lib/AdminControlCenter.php','/software-management'],
];$failed=[];foreach($checks as $name=>$spec){$text=@file_get_contents($root.'/'.$spec[0]);if($text===false||strpos($text,$spec[1])===false)$failed[]=$name;}if($failed){fwrite(STDERR,'FAILED: '.implode(', ',$failed).PHP_EOL);exit(1);}echo "software management contract OK\n";
