<?php
$root=dirname(__DIR__);$failed=[];
$need=[
 'db/mysql/033_service_tiers.sql'=>['user_plan_assignments','free_registered','plan_status','expires_at'],
 'app/lib/Entitlements.php'=>['PUBLIC','REGISTERED','PRO','requireFeature','advanced_requirements_builder','rfp_generator','decision_pack'],
 'api/auth.php'=>['Entitlements::context','free_registered','user_plan_assignments'],
 'plans.php'=>['Public / no login','Free registered','Pro','Procurement execution'],
 '.htaccess'=>['^plans/?$ plans.php'],
 'sitemap.php'=>["'/plans'"],
 'docs/service_tiers.md'=>['Administrative `role` is not a paid-plan entitlement','server-side','free_registered'],
];
foreach($need as $file=>$needles){$txt=@file_get_contents($root.'/'.$file)?:'';foreach($needles as $n)if(strpos($txt,$n)===false)$failed[]="$file missing $n";}
$ent=@file_get_contents($root.'/app/lib/Entitlements.php')?:'';
if(strpos($ent,"return self::PRO")!==false&&strpos($ent,'plan_code')===false)$failed[]='Pro access must derive from a plan assignment';
if(strpos($ent,"'full_business_case'=>self::PUBLIC")!==false||strpos($ent,"'rfp_generator'=>self::PUBLIC")!==false)$failed[]='Pro decision features must not be public';
if(strpos($ent,"'rfp_generator'=>self::REGISTERED")!==false)$failed[]='RFP generator must require Pro';
if(strpos($ent,"'public_product_profiles'=>self::PRO")!==false)$failed[]='Public product profiles must remain public';
if($failed){fwrite(STDERR,"Service tier checks failed:\n- ".implode("\n- ",$failed)."\n");exit(1);}echo "Service tier checks passed.\n";
