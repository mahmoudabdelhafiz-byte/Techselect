<?php
$root=dirname(__DIR__);
$checks=[
  'migration'=>['db/mysql/046_vendor_claims_self_service.sql',['vendor_profile_claims','vendor_memberships','vendor_update_requests','vendor_self_service_history']],
  'helper'=>['app/lib/VendorSelfService.php',['editorial_field_blocked','vendor_membership_required','product_not_in_verified_portfolio','approveClaim']],
  'vendor_api'=>['api/vendor_self_service.php',['authentication_required','VENDOR_PROFILE_CLAIM','VENDOR_UPDATE_SUBMIT']],
  'admin_api'=>['api/vendor_self_service_admin.php',['VENDOR_PROFILE_CLAIM_VERIFY','VENDOR_UPDATE_APPROVE','reason_required']],
  'portal'=>['vendor_portal.php',['Verified Vendor Portal','submit factual updates for review']],
  'admin_ui'=>['vendor_self_service_admin.php',['Vendor Self-Service Review','scores, rankings or recommendations']],
  'routes'=>['.htaccess',['vendor-portal','vendor-self-service-admin','api/vendor-self-service']]
];
$fail=[];foreach($checks as $name=>[$file,$needles]){$txt=@file_get_contents($root.'/'.$file);if($txt===false){$fail[]="$name missing $file";continue;}foreach($needles as $needle)if(strpos($txt,$needle)===false)$fail[]="$name missing $needle";}
if($fail){fwrite(STDERR,implode("\n",$fail)."\n");exit(1);}echo "vendor self-service contract OK\n";
