<?php
$root=dirname(__DIR__);$checks=[
 'shell'=>['app/lib/AdminShell.php',['ts-admin-shell','AdminControlCenter::navigation','tsAdminMenu']],
 'overview'=>['admin.php',['Operational control center','Needs attention','Operational workspaces','Users & Roles','Audit Log','System Health']],
 'service'=>['app/lib/AdminControlCenter.php',['Evidence attention','Products missing evaluation','SEO/indexing alerts','Vendor claims waiting']],
 'wrapper'=>['admin_shell_page.php',['AdminShell::decorate','community-intelligence-admin','search-console','authority-admin']],
 'routes'=>['.htaccess',['Unified admin shell','admin_shell_page.php']]
];$bad=[];foreach($checks as $name=>[$file,$needles]){$text=@file_get_contents($root.'/'.$file);if($text===false){$bad[]="$name:missing:$file";continue;}foreach($needles as $n)if(strpos($text,$n)===false)$bad[]="$name:missing-token:$n";}
if($bad){fwrite(STDERR,implode("\n",$bad)."\n");exit(1);}echo "admin control center contract ok\n";
