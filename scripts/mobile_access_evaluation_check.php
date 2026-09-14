<?php
$root=dirname(__DIR__);$errors=[];
$files=[
 'db/mysql/086_mobile_access_evaluation.sql'=>['product_mobile_access','android','ios','mobile_web','not_yet_verified','com.card_iq.myapp','official_app_store'],
 'app/lib/SoftwareManagement.php'=>['mobileAccess','Mobile access validation rows present','mobile_access_not_yet_verified','not yet verified; do not treat them as unsupported'],
 'api/software_management.php'=>['/mobile-access','PRODUCT_MOBILE_ACCESS_UPDATE','evidence_url_required_for_verified_mobile_status','not_yet_verified'],
 'software_management.php'=>['renderMobile','saveMobile','not_yet_verified','Mobile access evidence saved']
];
foreach($files as $file=>$terms){$path=$root.'/'.$file;if(!is_file($path)){$errors[]="missing:$file";continue;}$txt=file_get_contents($path);foreach($terms as $term)if(strpos($txt,$term)===false)$errors[]="$file missing $term";}
$migration=file_get_contents($root.'/db/mysql/086_mobile_access_evaluation.sql')?:'';
if(strpos($migration,"'not_supported'")!==false)$errors[]='migration must not infer unsupported mobile platforms';
if(strpos($migration,"confidence_score=0.990")===false)$errors[]='CardIQ Android evidence confidence missing';
$api=file_get_contents($root.'/api/software_management.php')?:'';
foreach(['Scoring::','fit_score','recommendation_rank','recommendation_score'] as $term)if(strpos($api,$term)!==false)$errors[]="mobile validation API must remain independent from recommendation scoring: $term";
if($errors){fwrite(STDERR,"Mobile access evaluation contract failed:\n- ".implode("\n- ",$errors)."\n");exit(1);}echo "Mobile access evaluation contract passed.\n";
