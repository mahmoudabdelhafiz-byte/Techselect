<?php
$root=dirname(__DIR__);$failed=[];
$need=[
 'db/mysql/033_service_tiers.sql'=>['user_plan_assignments','free_registered','plan_status','expires_at'],
 'app/lib/Entitlements.php'=>['PUBLIC','REGISTERED','PRO','requireFeature','advanced_requirements_builder','rfp_generator','decision_pack'],
 'api/auth.php'=>['Entitlements::context','free_registered','user_plan_assignments'],
 'plans.php'=>['Public / no login','Free registered','Paid plans are intentionally deferred','Procurement operations remain outside scope'],
 '.htaccess'=>['^plans/?$ plans.php'],
 'sitemap.php'=>["'/plans'"],
 'docs/service_tiers.md'=>['Administrative `role` is not a paid-plan entitlement','server-side','Every current non-public product feature must require `free_registered`, not `pro`'],
];
foreach($need as $file=>$needles){$txt=@file_get_contents($root.'/'.$file)?:'';foreach($needles as $n)if(strpos($txt,$n)===false)$failed[]="$file missing $n";}
$ent=@file_get_contents($root.'/app/lib/Entitlements.php')?:'';
$currentRegisteredFeatures=[
 'save_products','save_comparisons','persistent_shortlist','selection_projects','requirements_capture','saved_partner_options','resume_consultations','basic_decision_matrix','limited_exports','project_tracking',
 'advanced_requirements_builder','contextual_fit_scoring','weighted_decision_matrix','advanced_shortlist','full_business_case','roi_tco_model','rfp_generator','decision_pack','rich_exports',
];
foreach($currentRegisteredFeatures as $feature){
    if(strpos($ent,"'{$feature}'=>self::REGISTERED")===false)$failed[]="$feature must be available to normal registered users";
}
if(preg_match("/'[^']+'=>self::PRO/",$ent))$failed[]='No current product feature may require Pro while paid plans are deferred';
if(strpos($ent,"'full_business_case'=>self::PUBLIC")!==false||strpos($ent,"'rfp_generator'=>self::PUBLIC")!==false)$failed[]='Advanced decision features must still require registration';
if(strpos($ent,"'public_product_profiles'=>self::PUBLIC")===false)$failed[]='Public product profiles must remain public';
$plans=@file_get_contents($root.'/plans.php')?:'';
foreach(['Pro unlocks','Free registered\' : \'Pro','Registered and Pro'] as $legacy)if(strpos($plans,$legacy)!==false)$failed[]="plans.php still markets legacy Pro access: $legacy";
if($failed){fwrite(STDERR,"Service tier checks failed:\n- ".implode("\n- ",$failed)."\n");exit(1);}echo "Service tier checks passed: all current authenticated capabilities are registered-user access.\n";
