<?php
$root=dirname(__DIR__);
$checks=[
  'about_techselectai.php'=>['Official citation resource','Independence disclosure','AboutPage','Organization','https://techselectai.com/methodology'],
  'app/lib/AuthorityReferralAnalytics.php'=>['sanitizeAcquisition','sanitizeReferrer','query strings','classify','authority_sources','utm_source','referrer'],
  'app/lib/UserConsultationHistory.php'=>['utm_source,utm_medium,utm_campaign,referrer','UserConsultationHistory'],
  'api/secure.php'=>['ts_acq','AuthorityReferralAnalytics::sanitizeAcquisition','UserConsultationHistory::create'],
  'frontend/index.html'=>['document.referrer','utm_source','ts_acq','SameSite=Lax'],
  'authority_analytics.php'=>['External Authority & Referral Analytics','noindex,nofollow','AuthorityReferralAnalytics::summary'],
  '.htaccess'=>['about-techselectai','authority-analytics'],
  'sitemap.php'=>["'/about-techselectai'"],
  'llms.txt'=>['Official citation/about resource','https://techselectai.com/about-techselectai'],
];
$failed=[];
foreach($checks as $file=>$needles){$text=@file_get_contents($root.'/'.$file)?:'';foreach($needles as $needle){if(strpos($text,$needle)===false)$failed[]="$file missing $needle";}}
$service=@file_get_contents($root.'/app/lib/AuthorityReferralAnalytics.php')?:'';
if(strpos($service,"$u['query']")!==false||strpos($service,"$u['fragment']")!==false)$failed[]='Referral storage must not include referrer query strings or fragments';
$about=@file_get_contents($root.'/about_techselectai.php')?:'';
foreach(['guaranteed best','number one software','endorsed by all vendors'] as $forbidden)if(stripos($about,$forbidden)!==false)$failed[]="Unverifiable citation claim: $forbidden";
if($failed){fwrite(STDERR,"Citation/referral checks failed:\n- ".implode("\n- ",$failed)."\n");exit(1);}echo "Citation/referral checks passed.\n";
