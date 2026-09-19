<?php
declare(strict_types=1);

$root=dirname(__DIR__);
$sql=(string)@file_get_contents($root.'/db/mysql/146_workforce_rostering_shift_scheduling_catalog.sql');
$page=(string)@file_get_contents($root.'/software_page.php');
$api=(string)@file_get_contents($root.'/api/index.php');
$neutral=(string)@file_get_contents($root.'/scripts/recommendation_neutrality_check.php');
$doc=(string)@file_get_contents($root.'/docs/WORKFORCE_ROSTERING_DEPTH_PROGRAM.md');
$errors=[];

if($sql==='')$errors[]='Missing migration 146';
if($doc==='')$errors[]='Missing workforce rostering depth documentation';

foreach([
 'workforce-rostering-shift-scheduling',
 'rostering-demand-planning','rostering-schedule-generation','rostering-compliance-fatigue',
 'rostering-operational-allocation','rostering-self-service','rostering-governance',
 'rostering-integration-data','rostering-analytics-control','rostering-platform-operations',
 'manpoweriq','ukg-shiftboard','ukg-pro-workforce-management','quinyx-workforce-management','atoss-workforce-management','legion-wfm',
 'product_relationship_disclosures','Related-party product','The relationship does not increase Fit Score, Evidence Confidence or ranking position.',
 'Unknown != Unsupported','not_yet_verified'
] as $needle){
 if(strpos($sql,$needle)===false)$errors[]="Missing rostering invariant: {$needle}";
}

preg_match_all("/'rostering-[a-z0-9-]+' slug/",$sql,$capMatches);
if(count(array_unique($capMatches[0]??[]))!==58)$errors[]='Rostering foundation must define exactly 58 specialized criteria';

$allowed=['barmageyat.net','www.barmageyat.net','ukg.com','www.ukg.com','marketplace.ukg.com','quinyx.com','www.quinyx.com','atoss.com','www.atoss.com','legion.co','www.legion.co'];
preg_match_all('#https://[^\s\'\"]+#',$sql,$matches);
foreach(array_unique($matches[0]??[]) as $url){
 $url=rtrim($url,');,');
 $host=strtolower((string)parse_url($url,PHP_URL_HOST));
 if($host==='techselectai.com')continue;
 if($host===''||!in_array($host,$allowed,true))$errors[]="Unapproved rostering evidence host: {$host}";
}

foreach([
 "'manpoweriq','rostering-roster-builder','supported',0.960",
 "'manpoweriq','rostering-department-location-allocation','supported',0.980",
 "'manpoweriq','rostering-roster-approval-workflow','supported',0.980",
 "'manpoweriq','rostering-manpower-status-monitoring','supported',0.970",
 "'manpoweriq','rostering-multi-location-operations','supported',0.960"
] as $fact){
 if(strpos($sql,$fact)===false)$errors[]="Missing conservative ManpowerIQ public fact: {$fact}";
}
foreach([
 'rostering-automated-scheduling','rostering-workforce-demand-forecasting','rostering-fatigue-risk-rules',
 'rostering-enterprise-sso','rostering-api-webhook-integration','rostering-payroll-integration'
] as $unverified){
 if(strpos($sql,"'manpoweriq','{$unverified}'")!==false)$errors[]="Do not infer unpublished ManpowerIQ capability: {$unverified}";
}

if(strpos($sql,"p.slug IN('manpoweriq','cardiq')")===false)$errors[]='Both current Barmageyat-owned catalog products must receive relationship disclosures';
if(strpos($page,'product_relationship_disclosures')===false||strpos($page,'Relationship disclosure')===false)$errors[]='Software page must visibly render relationship disclosures';
if(strpos($api,'product_relationship_disclosures')===false||strpos($api,"'disclosures'")===false)$errors[]='Product API must expose relationship disclosures';
foreach(['manpoweriq','barmageyat','product_relationship_disclosures','related_party'] as $needle){
 if(stripos($neutral,$needle)===false)$errors[]="Neutrality guard must cover relationship/product token: {$needle}";
}

foreach(['g2.com','capterra','recommendation_rank','Scoring::','overall_score','fit_score','popularity_score','sponsored_rank'] as $bad){
 if(stripos($sql,$bad)!==false)$errors[]="Rostering migration contains prohibited source/ranking coupling: {$bad}";
}
if(strpos($sql,'product_deployments')!==false)$errors[]='Foundation must not infer rostering deployment models';
if(strpos($sql,"SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000")===false)$errors[]='All rostering mobile access must start unverified';
if(strpos($sql,'ON DUPLICATE KEY UPDATE product_id=VALUES(product_id);')===false)$errors[]='Rostering mobile defaults must be rerun-safe';

if(strpos($doc,'58 buyer-selectable operational criteria')===false)$errors[]='Program doc must state the 58-criterion foundation';
if(strpos($doc,'The disclosure must never change Fit Score')===false)$errors[]='Program doc must state ownership/scoring separation';

if($errors){fwrite(STDERR,"Workforce rostering catalog check failed:\n- ".implode("\n- ",$errors)."\n");exit(1);}
echo "Workforce rostering catalog contract passed: 58 specialist criteria, six first-party-evidenced products, explicit ManpowerIQ ownership disclosure, unknown discipline and scoring neutrality.\n";
