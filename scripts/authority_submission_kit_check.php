<?php
$root=dirname(__DIR__);
$files=[
  'app/lib/AuthoritySubmissionKit.php'=>['AI-Powered Software & Technology Advisory','ownership, sponsorship and commercial relationships','utm_campaign','eligibility_check','Product Hunt','Crunchbase','StartupBlink','LinkedIn','Wamda','G2','Capterra','AlternativeTo','SaaSHub'],
  'authority_submission_kit.php'=>['Authority Submission Kit','noindex,nofollow','Nothing on this page means a profile, submission, publication, endorsement or backlink already exists.'],
  'authority_admin.php'=>['/authority-submission-kit'],
  '.htaccess'=>['authority-submission-kit'],
];
$failed=[];
foreach($files as $file=>$needles){$text=@file_get_contents($root.'/'.$file)?:'';foreach($needles as $needle)if(strpos($text,$needle)===false)$failed[]="$file missing $needle";}
$kit=@file_get_contents($root.'/app/lib/AuthoritySubmissionKit.php')?:'';
foreach(['universally ranking the best software','Do not imply endorsement','not a conventional software vendor'] as $needle)if(strpos($kit,$needle)===false)$failed[]="Missing factual boundary: $needle";
foreach(['we are listed on','featured by','endorsed by','#1 software','guaranteed best'] as $forbidden)if(stripos($kit,$forbidden)!==false)$failed[]="Fabricated/exaggerated claim found: $forbidden";
if(strpos($kit,"'homepage'=>'https://techselectai.com/'")===false||strpos($kit,"'about'=>'https://techselectai.com/about-techselectai'")===false)$failed[]='Canonical links missing';
if($failed){fwrite(STDERR,"Authority submission kit checks failed:\n- ".implode("\n- ",$failed)."\n");exit(1);}echo "Authority submission kit checks passed.\n";
