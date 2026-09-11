<?php
$root=dirname(__DIR__);
$checks=[
 ['db/mysql/056_authority_outreach_campaigns.sql','authority_campaigns'],
 ['db/mysql/056_authority_outreach_campaigns.sql','authority_outreach_events'],
 ['app/lib/AuthorityCampaigns.php','published_url_required_for_backlink_verification'],
 ['app/lib/AuthorityCampaigns.php','mention_approval_required_before_backlink_verification'],
 ['app/lib/AuthorityCampaigns.php','priority_score'],
 ['api/authority_campaigns.php','Security::requireRole'],
 ['api/authority_campaigns.php','Security::requireCsrf'],
 ['authority_campaigns.php','/research/software-evidence-benchmark'],
 ['authority_campaigns.php','backlink_verified'],
 ['.htaccess','api/authority-campaigns'],
 ['admin_shell_page.php',"'/authority-campaigns'=>'authority_campaigns.php'"]
];
$fail=[];foreach($checks as [$file,$needle]){$body=@file_get_contents($root.'/'.$file);if($body===false||strpos($body,$needle)===false)$fail[]=$file.' missing '.$needle;}
if($fail){fwrite(STDERR,"Authority campaign contract failed:\n- ".implode("\n- ",$fail)."\n");exit(1);}echo "Authority campaign contract OK\n";
