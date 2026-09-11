<?php
$root=dirname(__DIR__);
$checks=[
 'db/mysql/030_external_authority_tracker.sql'=>['CREATE TABLE IF NOT EXISTS authority_sources','mention_requires_approval','mention_approved','published_url','backlink_status','first_verified_at','last_checked_at'],
 'app/lib/AuthoritySources.php'=>['mention_approval_required_before_publish','published_url_required_for_active_backlink','customer_mention','vendor_mention','partner','active_backlinks','lost_backlinks'],
 'api/authority_sources.php'=>["Security::requireRole(['reviewer','admin','super_admin'])",'Security::sameOrigin','Security::requireCsrf','AUTHORITY_SOURCE_CREATE','AUTHORITY_SOURCE_UPDATE'],
 'authority_admin.php'=>['External Authority & Backlinks','/api/authority-sources','This tool does not automate outreach or link building.'],
 '.htaccess'=>['authority-admin','api/authority-sources']
];
$failed=[];
foreach($checks as $file=>$needles){$text=@file_get_contents($root.'/'.$file)?:'';foreach($needles as $needle){if(strpos($text,$needle)===false)$failed[]="$file missing $needle";}}
$service=@file_get_contents($root.'/app/lib/AuthoritySources.php')?:'';
foreach(['curl_exec','file_get_contents($publishedUrl','mail(','wp_remote_post','INSERT INTO ai_referral_events'] as $forbidden){if(strpos($service,$forbidden)!==false)$failed[]="Authority tracker must not automate outreach/link creation or fake referral events: $forbidden";}
if(strpos($service,"$backlink==='active'&&$publishedUrl===null")!==false)$failed[]='Regression guard string interpolation error';
if($failed){fwrite(STDERR,"External authority tracker checks failed:\n- ".implode("\n- ",$failed)."\n");exit(1);}echo "External authority tracker checks passed.\n";
