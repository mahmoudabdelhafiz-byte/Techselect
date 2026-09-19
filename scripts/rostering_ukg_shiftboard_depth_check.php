<?php
declare(strict_types=1);

$root=dirname(__DIR__);
$sql=(string)@file_get_contents($root.'/db/mysql/148_rostering_ukg_shiftboard_depth_evidence.sql');
$errors=[];
if($sql===''){fwrite(STDERR,"Missing migration 148\n");exit(1);}

$expected=[
    ['rostering-staffing-requirements-modeling','supported','0.990'],
    ['rostering-workload-driven-staffing','supported','0.990'],
    ['rostering-coverage-targets','supported','0.980'],
    ['rostering-operations-demand-integration','partially_supported','0.970'],
    ['rostering-roster-builder','supported','0.990'],
    ['rostering-automated-scheduling','supported','0.990'],
    ['rostering-recurring-shift-patterns','supported','0.980'],
    ['rostering-shift-slot-assignment','supported','0.990'],
    ['rostering-skills-based-assignment','supported','0.990'],
    ['rostering-certification-based-assignment','supported','0.990'],
    ['rostering-availability-aware-scheduling','supported','0.990'],
    ['rostering-preference-aware-scheduling','supported','0.990'],
    ['rostering-labor-law-compliance','supported','0.990'],
    ['rostering-collective-agreement-rules','supported','0.990'],
    ['rostering-rest-period-rules','supported','0.990'],
    ['rostering-fatigue-risk-rules','supported','0.990'],
    ['rostering-max-hours-consecutive-shifts','supported','0.990'],
    ['rostering-overtime-thresholds','supported','0.990'],
    ['rostering-fair-overtime-distribution','supported','0.990'],
    ['rostering-seniority-rules','supported','0.990'],
    ['rostering-department-location-allocation','supported','0.980'],
    ['rostering-work-area-role-allocation','supported','0.990'],
    ['rostering-crew-gang-team-assignment','supported','0.980'],
    ['rostering-minimum-skill-mix','supported','0.990'],
    ['rostering-absence-backfill','supported','0.990'],
    ['rostering-intraday-reassignment','supported','0.990'],
    ['rostering-schedule-self-service','partially_supported','0.960'],
    ['rostering-shift-swaps','supported','0.990'],
    ['rostering-shift-bidding','supported','0.990'],
    ['rostering-open-shift-volunteering','supported','0.990'],
    ['rostering-leave-timeoff-requests','supported','0.990'],
    ['rostering-availability-preference-self-service','supported','0.980'],
    ['rostering-manager-override','supported','0.990'],
    ['rostering-scheduling-audit-trail','supported','0.990'],
    ['rostering-hris-integration','partially_supported','0.980'],
    ['rostering-payroll-integration','partially_supported','0.940'],
    ['rostering-time-attendance-integration','supported','0.990'],
    ['rostering-coverage-gap-visibility','supported','0.990'],
    ['rostering-manpower-status-monitoring','supported','0.980'],
    ['rostering-overtime-labor-cost-analytics','supported','0.990'],
    ['rostering-staffing-alerts-exceptions','supported','0.990'],
    ['rostering-multi-location-operations','supported','0.980'],
    ['rostering-continuous-24x7-operations','supported','0.990']
];
if(count($expected)!==43)$errors[]='Expected exactly 43 reviewed UKG Shiftboard depth facts';
foreach($expected as [$capability,$status,$confidence]){
    $needle="'{$capability}','{$status}',{$confidence}";
    if(strpos($sql,$needle)===false)$errors[]="Missing UKG Shiftboard depth fact: {$needle}";
}

foreach(['manpoweriq','ukg-pro-workforce-management','quinyx-workforce-management','atoss-workforce-management','legion-wfm'] as $other){
    if(strpos($sql,"'{$other}'")!==false)$errors[]="UKG Shiftboard evidence pass must not modify another rostering product: {$other}";
}
if(substr_count($sql,"'ukg-shiftboard'")!==1)$errors[]='UKG Shiftboard product scope changed unexpectedly';

$allowed=['ukg.com','www.ukg.com','marketplace.ukg.com'];
preg_match_all('#https://[^\s\'\"]+#',$sql,$matches);
foreach(array_unique($matches[0]??[]) as $url){
    $url=rtrim($url,');,');
    $host=strtolower((string)parse_url($url,PHP_URL_HOST));
    if($host===''||!in_array($host,$allowed,true))$errors[]="Unapproved UKG Shiftboard evidence host: {$host}";
}
if(strpos($sql,'https://www.ukg.com/sites/default/files/2026-03/UKG-Shiftboard-Product-Profile.pdf')===false)$errors[]='Official UKG Shiftboard product profile source must be registered';

foreach([
    'does not copy broader UKG Pro Workforce Management features',
    'Production-plan alignment is not promoted into a generic ERP/MES/API integration claim',
    'not promoted into a generic HRIS/payroll connector catalogue',
    'not promoted into Android/iOS/mobile-web platform support',
    'Deployment model, APIs/webhooks, enterprise SSO and large-workforce scale remain not_yet_verified',
    'does not establish a generic external ERP/MES/API connector',
    'this proves suite integration but not a generic HRIS connector catalogue',
    'does not establish direct payroll export or a generic payroll-connector catalogue',
    'native app platform support is not inferred',
    'does not explicitly state full published-roster viewing'
] as $phrase){
    if(strpos($sql,$phrase)===false)$errors[]="Missing UKG Shiftboard evidence boundary: {$phrase}";
}

foreach([
 'rostering-workforce-demand-forecasting','rostering-staffing-scenario-planning',
 'rostering-rotating-shifts','rostering-equipment-machine-qualification',
 'rostering-cross-site-labor-pools','rostering-roster-approval-workflow',
 'rostering-roster-change-approval','rostering-roster-version-history',
 'rostering-role-based-scheduling-access','rostering-operations-system-integration',
 'rostering-api-webhook-integration','rostering-enterprise-sso',
 'rostering-planned-vs-actual-staffing','rostering-large-workforce-scale'
] as $unsupportedPromotion){
    if(strpos($sql,"'{$unsupportedPromotion}'")!==false)$errors[]="UKG Shiftboard depth pass must not promote unverified capability: {$unsupportedPromotion}";
}
foreach(["'public-saas'","'on-premise'","'mobile_web'","'android'","'ios'"] as $deploymentOrMobile){
    if(strpos($sql,$deploymentOrMobile)!==false)$errors[]="UKG Shiftboard depth pass must not infer deployment/mobile status: {$deploymentOrMobile}";
}

foreach(['g2.com','capterra','recommendation_rank','Scoring::','overall_score','fit_score','popularity_score','sponsored_rank'] as $bad){
    if(stripos($sql,$bad)!==false)$errors[]="UKG Shiftboard depth migration contains prohibited source/ranking coupling: {$bad}";
}

if(strpos($sql,'product_capability_evidence')===false)$errors[]='UKG Shiftboard depth facts must retain evidence links';
if(strpos($sql,'Unknown != Unsupported')===false)$errors[]='Migration must preserve the Unknown != Unsupported boundary';

if($errors){
    fwrite(STDERR,"UKG Shiftboard depth check failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}
echo "UKG Shiftboard depth contract passed: 43 current first-party facts, explicit UKG Pro WFM/integration/mobile boundaries and ranking neutrality.\n";
