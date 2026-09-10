<?php
$root=dirname(__DIR__);
$svc=(string)@file_get_contents($root.'/app/lib/VerifiedReviewRewards.php');
$api=(string)@file_get_contents($root.'/api/review_rewards.php');
$page=(string)@file_get_contents($root.'/review_rewards.php');
$ht=(string)@file_get_contents($root.'/.htaccess');
$checks=[
 'V1 reward types only'=>strpos($svc,"['cardiq_pro_voucher','premium_report_access']")!==false,
 'approved review required'=>strpos($svc,"r.moderation_status='approved'")!==false,
 'verified review required'=>strpos($svc,"verification_status='verified'")!==false,
 'no sentiment eligibility'=>strpos($svc,'overall_rating')===false && strpos($svc,'pros')===false && strpos($svc,'cons')===false,
 'one-way reward reference'=>strpos($svc,"hash('sha256',$ref,true)")!==false,
 'duplicate issuance blocked'=>strpos($svc,'reward_already_issued')!==false,
 'reward API protected'=>strpos($api,"requireRole(['reviewer','admin','super_admin'])")!==false && strpos($api,'Security::requireCsrf()')!==false,
 'reward page explains neutrality'=>strpos($page,'never depends on whether the review is positive or negative')!==false,
 'reward route wired'=>strpos($ht,'api/review-rewards(?:/.*)?$ api/review_rewards.php')!==false,
 'reward page branded'=>strpos($ht,'review-rewards/?$ brand_page.php')!==false,
 'no ranking mutation'=>strpos($svc,'consultation_product_scores')===false && strpos($api,'recommendation')===false,
];
$failed=[];foreach($checks as $label=>$ok){echo ($ok?'PASS':'FAIL').' '.$label.PHP_EOL;if(!$ok)$failed[]=$label;}if($failed){fwrite(STDERR,"Verified review rewards check failed:\n- ".implode("\n- ",$failed)."\n");exit(1);}echo "Verified review rewards checks passed.\n";
