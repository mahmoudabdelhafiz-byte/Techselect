<?php
$root=dirname(__DIR__);
$checks=[
 'about_techselectai.php'=>['Official citation resource','TechSelectAI is operated by','Independence disclosure','https://techselectai.com/methodology','Organization'],
 'app/lib/AuthoritySources.php'=>['mention_approval_required_before_publish','published_url_required_for_active_backlink','SOURCE_TYPES','BACKLINK'],
 'api/authority_sources.php'=>['AUTHORITY_SOURCE_CREATE','AUTHORITY_SOURCE_UPDATE','requireCsrf','authority-sources-write'],
 'authority_admin.php'=>['External Authority & Backlinks','backlink_status','mention_approved','published_url'],
 'authority_analytics.php'=>['External Authority & Referral Analytics','visitor_sessions','utm_source','active_backlinks'],
 'app/lib/UserConsultationHistory.php'=>['utm_source','utm_medium','utm_campaign','referrer'],
 'api/secure.php'=>['consultation_acquisition','HTTP_REFERER','utm_source','parse_str'],
 'db/mysql/030_external_authority.sql'=>['CREATE TABLE IF NOT EXISTS authority_sources','backlink_status','mention_requires_approval','published_url'],
 '.htaccess'=>['about-techselectai','authority-admin','authority-analytics','api/authority-sources'],
 'sitemap.php'=>["'/about-techselectai'"],
 'llms.txt'=>['Official citation/about resource','https://techselectai.com/about-techselectai'],
 'docs/external_authority_outreach.md'=>['Never buy ranking links','UTM','authority-admin','authority-analytics']
];
$failed=[];
foreach($checks as $file=>$needles){$text=@file_get_contents($root.'/'.$file)?:'';foreach($needles as $needle)if(strpos($text,$needle)===false)$failed[]="$file missing $needle";}
$about=@file_get_contents($root.'/about_techselectai.php')?:'';
foreach(['guaranteed best','number one software','independently endorsed by vendors'] as $forbidden)if(stripos($about,$forbidden)!==false)$failed[]="Public citation page contains unverifiable claim: $forbidden";
$secure=@file_get_contents($root.'/api/secure.php')?:'';
if(strpos($secure,"$referrer=$scheme.'://'.strtolower((string)$u['host']).((string)($u['path']??'/'))")===false)$failed[]='Referrer must be stored without query strings';
if($failed){fwrite(STDERR,"External authority checks failed:\n- ".implode("\n- ",$failed)."\n");exit(1);}echo "External authority checks passed.\n";
