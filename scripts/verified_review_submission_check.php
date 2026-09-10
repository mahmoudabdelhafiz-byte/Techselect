<?php
$root=dirname(__DIR__);
$checks=[];
function check($name,$ok){global $checks;$checks[]=['name'=>$name,'ok'=>(bool)$ok];}
$ht=(string)@file_get_contents($root.'/.htaccess');
$page=(string)@file_get_contents($root.'/review.php');
$api=(string)@file_get_contents($root.'/api/reviews.php');
check('review page exists',$page!=='');
check('review API exists',$api!=='');
check('review route wired',strpos($ht,'RewriteRule ^review/[a-z0-9-]+/?$ review.php')!==false);
check('review API route wired',strpos($ht,'RewriteRule ^api/reviews(?:/.*)?$ api/reviews.php')!==false);
check('verified email required',strpos($api,"verified_email_required")!==false&&strpos($api,'email_verified_at')!==false);
check('CSRF required',strpos($api,'Security::requireCsrf()')!==false);
check('rate limit required',strpos($api,"review-submit")!==false);
check('pending moderation default',strpos($api,"'pending'")!==false);
check('baseline verification created',strpos($api,"'email_verified'")!==false&&strpos($api,"'verified'")!==false);
check('duplicate response handled',strpos($api,'review_already_exists')!==false);
check('public display not introduced',strpos($page,'noindex,follow')!==false);
$failed=array_values(array_filter($checks,fn($c)=>!$c['ok']));
foreach($checks as $c)echo ($c['ok']?'PASS':'FAIL').' '.$c['name'].PHP_EOL;
if($failed){exit(1);}echo "Verified review submission checks passed.\n";
