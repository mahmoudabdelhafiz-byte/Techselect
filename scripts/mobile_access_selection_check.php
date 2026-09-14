<?php
$root=dirname(__DIR__);$errors=[];
$migration=file_get_contents($root.'/db/mysql/087_mobile_access_selection_criteria.sql')?:'';
$scoring=file_get_contents($root.'/app/lib/Scoring.php')?:'';
$ai=file_get_contents($root.'/app/lib/AiExtraction.php')?:'';
$api=file_get_contents($root.'/api/index.php')?:'';

foreach(['Mobile Access','mobile-android-app','mobile-ios-app','mobile-web-access','product_mobile_access','not_yet_verified','trg_mobile_access_capability_update','trg_mobile_access_capability_insert'] as $term){
  if(!str_contains($migration,$term))$errors[]="087 migration missing {$term}";
}
if(!str_contains($migration,"pma.support_status"))$errors[]='mobile capability support must mirror canonical product_mobile_access status';
if(!str_contains($migration,"pma.confidence_score"))$errors[]='mobile capability confidence must mirror canonical product_mobile_access confidence';
if(str_contains($migration,"support_status='supported'"))$errors[]='087 must not invent supported status';
if(!str_contains($scoring,"'not_yet_verified'=>0.40"))$errors[]='unknown/not-yet-verified scoring contract changed unexpectedly';
if(!str_contains($scoring,'mandatoryGaps'))$errors[]='mandatory gap logic required for buyer-selected mobile criteria';
if(!str_contains($ai,'SELECT c.slug,c.name FROM capabilities c WHERE c.is_active=1'))$errors[]='AI extraction must discover active mobile capability criteria';
if(!str_contains($api,'product_capabilities'))$errors[]='recommendation/compare engine must continue to use product capabilities';
foreach(['mobile_bonus','mobile_score_bonus','preferred_mobile_vendor'] as $term){
  if(str_contains(strtolower($migration),$term))$errors[]='mobile availability must not receive an automatic ranking bonus';
}
if($errors){fwrite(STDERR,"Mobile access selection contract failed:\n- ".implode("\n- ",$errors)."\n");exit(1);}echo "Mobile access selection contract passed.\n";
