<?php
$root=dirname(__DIR__);
$api=(string)@file_get_contents($root.'/api/reviews.php');
$page=(string)@file_get_contents($root.'/my_reviews.php');
$brand=(string)@file_get_contents($root.'/brand_page.php');
$ht=(string)@file_get_contents($root.'/.htaccess');
$checks=[
  'page exists'=>$page!=='',
  'auth required'=>strpos($page,"if(!Security::user())")!==false,
  'own reviews endpoint'=>strpos($page,"fetch('/api/reviews/mine')")!==false,
  'api scopes to current user'=>strpos($api,'WHERE r.user_id=?')!==false,
  'reward status exposed'=>strpos($api,'reward_eligibility_status')!==false && strpos($api,'reward_status')!==false,
  'raw reward reference not exposed'=>strpos($api,'reward_reference_hash')===false && strpos($page,'reward_reference_hash')===false,
  'private verification evidence not exposed'=>strpos($api,'verification_reference_hash')===false,
  'my reviews branded'=>strpos($brand,"$target='my_reviews.php'")!==false,
  'my reviews route'=>strpos($ht,'RewriteRule ^my-reviews/?$ brand_page.php')!==false,
  'no ranking mutation'=>strpos($page,'consultation_product_scores')===false && strpos($api,'UPDATE recommendation')===false,
];
$failed=[];foreach($checks as $label=>$ok){echo ($ok?'PASS':'FAIL').' '.$label.PHP_EOL;if(!$ok)$failed[]=$label;}
if($failed){fwrite(STDERR,"My reviews status check failed:\n- ".implode("\n- ",$failed)."\n");exit(1);}echo "My reviews status checks passed.\n";
