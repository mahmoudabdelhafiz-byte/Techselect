<?php
$files=[
 'app/lib/AdminGovernance.php'=>['PERMISSIONS','last_active_super_admin_required','cannot_manage_equal_or_higher_role','auditCsv','entityLink'],
 'api/admin_governance.php'=>['USER_ROLE_STATUS_UPDATE','Security::audit','/api/admin-governance/audit.csv'],
 'admin_users.php'=>['Permission matrix','/api/admin-governance/users'],
 'admin_audit.php'=>['Export CSV','actor_user_id','entity_type','outcome'],
 '.htaccess'=>['admin-users','admin-audit','api/admin-governance'],
];
$ok=true;foreach($files as $f=>$needles){$c=@file_get_contents(__DIR__.'/../'.$f);if($c===false){echo "MISSING $f\n";$ok=false;continue;}foreach($needles as $n){if(strpos($c,$n)===false){echo "MISSING CONTRACT $f :: $n\n";$ok=false;}}}
exit($ok?0:1);
