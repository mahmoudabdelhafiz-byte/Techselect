<?php
declare(strict_types=1);

$root=dirname(__DIR__);
$sql=(string)@file_get_contents($root.'/db/mysql/147_rostering_manpoweriq_depth_evidence.sql');
$neutral=(string)@file_get_contents($root.'/scripts/recommendation_neutrality_check.php');
$errors=[];
if($sql===''){fwrite(STDERR,"Missing migration 147\n");exit(1);}

$expected=[
    ['rostering-workload-driven-staffing','partially_supported','0.960'],
    ['rostering-roster-builder','supported','0.990'],
    ['rostering-automated-scheduling','supported','0.990'],
    ['rostering-recurring-shift-patterns','supported','0.990'],
    ['rostering-shift-slot-assignment','supported','0.980'],
    ['rostering-skills-based-assignment','supported','0.990'],
    ['rostering-certification-based-assignment','supported','0.990'],
    ['rostering-availability-aware-scheduling','supported','0.990'],
    ['rostering-fair-overtime-distribution','supported','0.990'],
    ['rostering-department-location-allocation','supported','0.990'],
    ['rostering-work-area-role-allocation','supported','0.980'],
    ['rostering-equipment-machine-qualification','supported','0.990'],
    ['rostering-cross-site-labor-pools','supported','0.990'],
    ['rostering-roster-approval-workflow','supported','0.990'],
    ['rostering-scheduling-audit-trail','partially_supported','0.960'],
    ['rostering-coverage-gap-visibility','partially_supported','0.970'],
    ['rostering-manpower-status-monitoring','supported','0.990'],
    ['rostering-overtime-labor-cost-analytics','partially_supported','0.970'],
    ['rostering-shift-dashboard','supported','0.980'],
    ['rostering-multi-location-operations','supported','0.990'],
    ['rostering-operations-demand-integration','partially_supported','0.950']
];
if(count($expected)!==21)$errors[]='Expected exactly 21 reviewed ManpowerIQ depth facts';
foreach($expected as [$capability,$status,$confidence]){
    $needle="'{$capability}','{$status}',{$confidence}";
    if(strpos($sql,$needle)===false)$errors[]="Missing ManpowerIQ depth fact: {$needle}";
}

foreach(['ukg-shiftboard','ukg-pro-workforce-management','quinyx-workforce-management','atoss-workforce-management','legion-wfm'] as $other){
    if(strpos($sql,"'{$other}'")!==false)$errors[]="ManpowerIQ evidence pass must not modify another rostering product: {$other}";
}
if(substr_count($sql,"'manpoweriq'")!==1)$errors[]='ManpowerIQ product scope changed unexpectedly';

preg_match_all('#https://[^\s\'\"]+#',$sql,$matches);
foreach(array_unique($matches[0]??[]) as $url){
    $url=rtrim($url,');,');
    $host=strtolower((string)parse_url($url,PHP_URL_HOST));
    if(!in_array($host,['barmageyat.net','www.barmageyat.net','techselectai.com'],true))$errors[]="Unapproved ManpowerIQ evidence/disclosure host: {$host}";
}

foreach([
    'Operational-demand wording is not promoted into an external TOS/ERP/MES/API integration claim',
    'Leave management is not promoted into employee self-service leave requests',
    'Approval history is partial evidence for auditability',
    'Deployment, SSO, payroll, attendance, API/webhook and platform-specific mobile support remain not_yet_verified',
    'does not establish quantitative workload-to-headcount calculations',
    'does not establish a complete audit trail',
    'explicit automated understaffing/overstaffing gap detection is not separately described',
    'broader labor-cost modeling and analytics are not separately documented',
    'does not establish an external TOS, ERP, MES or API integration'
] as $phrase){
    if(strpos($sql,$phrase)===false)$errors[]="Missing ManpowerIQ evidence boundary: {$phrase}";
}

foreach([
 'rostering-workforce-demand-forecasting','rostering-staffing-requirements-modeling','rostering-fatigue-risk-rules',
 'rostering-rest-period-rules','rostering-payroll-integration','rostering-time-attendance-integration',
 'rostering-api-webhook-integration','rostering-enterprise-sso','rostering-leave-timeoff-requests',
 'rostering-shift-swaps','rostering-shift-bidding'
] as $unsupportedPromotion){
    if(strpos($sql,"'{$unsupportedPromotion}'")!==false)$errors[]="ManpowerIQ depth pass must not promote unverified capability: {$unsupportedPromotion}";
}
foreach(["'public-saas'","'on-premise'","'mobile_web'","'android'","'ios'"] as $deploymentOrMobile){
    if(strpos($sql,$deploymentOrMobile)!==false)$errors[]="ManpowerIQ depth pass must not infer deployment/mobile status: {$deploymentOrMobile}";
}

foreach(['g2.com','capterra','recommendation_rank','Scoring::','overall_score','fit_score','popularity_score','sponsored_rank'] as $bad){
    if(stripos($sql,$bad)!==false)$errors[]="ManpowerIQ depth migration contains prohibited source/ranking coupling: {$bad}";
}
foreach(['manpoweriq','barmageyat','product_relationship_disclosures'] as $needle){
    if(stripos($neutral,$needle)===false)$errors[]="Recommendation neutrality guard missing related-party token: {$needle}";
}

if(strpos($sql,'product_capability_evidence')===false)$errors[]='ManpowerIQ depth facts must retain evidence links';
if(strpos($sql,'Unknown != Unsupported')===false)$errors[]='Migration must preserve the Unknown != Unsupported boundary';

if($errors){
    fwrite(STDERR,"ManpowerIQ depth check failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}
echo "ManpowerIQ depth contract passed: 21 current first-party facts, explicit related-party disclosure, conservative scope boundaries and ranking neutrality.\n";
