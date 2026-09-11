<?php
$api=file_get_contents(__DIR__.'/../api/evidence_inbox.php');
$ui=file_get_contents(__DIR__.'/../evidence_inbox.php');
$js=file_get_contents(__DIR__.'/../evidence_inbox.js');
$impact=file_get_contents(__DIR__.'/../app/lib/EvidenceImpact.php');
$ht=file_get_contents(__DIR__.'/../.htaccess');
$fail=[];
foreach(['stale','high_impact','material_impact_confirmation_required','EVIDENCE_INBOX_UPDATE'] as $n)if(strpos($api,$n)===false)$fail[]='API missing '.$n;
foreach(['published_evaluations','recommendation_runs','capabilities','material_risk'] as $n)if(strpos($impact,$n)===false)$fail[]='Impact tracing missing '.$n;
foreach(['Evidence Inbox','High impact','Source change review'] as $n)if(strpos($ui,$n)===false)$fail[]='UI missing '.$n;
foreach(['confirm_material_impact','/api/evidence-inbox','Open source'] as $n)if(strpos($js,$n)===false)$fail[]='JS missing '.$n;
foreach(['^evidence-inbox/?$','^api/evidence-inbox(?:/.*)?$'] as $n)if(strpos($ht,$n)===false)$fail[]='Route missing '.$n;
if($fail){fwrite(STDERR,implode("\n",$fail)."\n");exit(1);}echo "evidence_inbox_check: OK\n";
