<?php
$root=dirname(__DIR__);
$required=[
  'db/mysql/102_product_community_notifications.sql',
  'api/product_follows.php',
  'api/product_community.php',
  'product_follow.js',
  'scripts/product_community_notifications.php',
];
$errors=[];$text=[];
foreach($required as $file){$path=$root.'/'.$file;if(!is_file($path)){$errors[]='missing '.$file;continue;}$text[$file]=file_get_contents($path);}
$m=$text['db/mysql/102_product_community_notifications.sql']??'';
if(strpos($m,'community_notifications TINYINT(1) NOT NULL DEFAULT 0')===false)$errors[]='community email preference must default off';
if(strpos($m,'UNIQUE KEY uq_product_community_notification(post_id,follow_id)')===false)$errors[]='delivery dedupe key missing';
$api=$text['api/product_community.php']??'';
foreach(['pf.community_notifications=1','pf.user_id<>?','INSERT IGNORE INTO product_community_notification_deliveries'] as $needle)if(strpos($api,$needle)===false)$errors[]='community enqueue guard missing: '.$needle;
if(strpos($api,"$action==='helpful'")===false)$errors[]='helpful action missing';
$follow=$text['api/product_follows.php']??'';
if(strpos($follow,"$method==='PATCH'")===false||strpos($follow,'setCommunityNotifications')===false)$errors[]='separate preference API missing';
$js=$text['product_follow.js']??'';
foreach(['Email me about new community questions and replies',"method:'PATCH'"] as $needle)if(strpos($js,$needle)===false)$errors[]='follow UI preference missing: '.$needle;
$worker=$text['scripts/product_community_notifications.php']??'';
foreach(["d.status IN ('pending','failed')","d.attempt_count<5",'pf.community_notifications=1','#community','never affect TechSelectAI Fit Score'] as $needle)if(strpos($worker,$needle)===false)$errors[]='worker safety/retry contract missing: '.$needle;
$all=implode("\n",$text);
foreach(['fit_score=','fit_score =','ORDER BY fit_score','recommendation_score','ranking_boost'] as $forbidden)if(stripos($all,$forbidden)!==false)$errors[]='community notification feature must not touch ranking/scoring: '.$forbidden;
if($errors){fwrite(STDERR,implode("\n",$errors)."\n");exit(1);}echo "Product community notification contract OK\n";
