<?php
$root=dirname(__DIR__);$checks=[
 'account_settings.php'=>'/api/account/settings',
 'api/account_history.php'=>"current_password_invalid",
 'frontend/src/accountNav.js'=>'/account-settings',
 '.htaccess'=>'account-settings/?$ account_settings.php'
];$failed=[];foreach($checks as $file=>$needle){$p=$root.'/'.$file;$c=is_file($p)?file_get_contents($p):'';if($c===false||strpos($c,$needle)===false)$failed[]=$file.' missing '.$needle;}
if($failed){fwrite(STDERR,"Account settings checks failed:\n- ".implode("\n- ",$failed)."\n");exit(1);}echo "Account settings checks passed.\n";
