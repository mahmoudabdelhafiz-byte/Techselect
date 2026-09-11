<?php
$root=dirname(__DIR__);
$checks=[
  'db/mysql/032_authority_execution_readiness.sql'=>['submission_url','route_source_url','prerequisites','required_assets','readiness_status','route_verified_at','eligibility_check','backlink_status=\'not_published\''],
  'app/lib/AuthoritySources.php'=>["READINESS=['researching','ready','eligibility_check','blocked','submitted']",'invalid_readiness_status','submission_url','route_source_url','route_verified_at','submitted_readiness_requires_outreach_state'],
  'authority_admin.php'=>['Execution queue','Submission/contact URL','Route evidence URL','Prerequisites','Required assets','readiness_status','route_verified_at'],
];
$failed=[];
foreach($checks as $file=>$needles){$text=@file_get_contents($root.'/'.$file)?:'';foreach($needles as $needle)if(strpos($text,$needle)===false)$failed[]="$file missing $needle";}
$m=@file_get_contents($root.'/db/mysql/032_authority_execution_readiness.sql')?:'';
foreach(["backlink_status='active'","outreach_status='published'","mention_approved=1","published_url='http"] as $forbidden)if(strpos($m,$forbidden)!==false)$failed[]="Phase 3 migration must not assert acquisition/publication: $forbidden";
foreach(['producthunt.com','crunchbase.com','startupblink.com','linkedin.com','g2.com','capterra.com','alternativeto.net','saashub.com','wamda.com'] as $domain)if(strpos($m,$domain)===false)$failed[]="Missing verified execution target: $domain";
foreach(['f6s.com','magnitt.com','entrepreneur.com'] as $domain){if(strpos($m,$domain)===false)$failed[]="Missing research-only target: $domain";}
if(strpos($m,"readiness_status='researching',route_verified_at=NULL")===false)$failed[]='Unverified routes must remain researching with no verification timestamp';
if($failed){fwrite(STDERR,"Authority execution readiness checks failed:\n- ".implode("\n- ",$failed)."\n");exit(1);}echo "Authority execution readiness checks passed.\n";
