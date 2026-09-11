<?php
$root=dirname(__DIR__);
$checks=[
 'app/lib/EvidenceRefreshScheduler.php'=>['GET_LOCK','RELEASE_LOCK','EvidenceRefresh::check','p.status=\'active\'','TRIM(COALESCE(es.source_url,\'\'))<>\'\'','MAX(rc.checked_at)','DATE_SUB(NOW(),INTERVAL','scheduler_locked','MAX_LIMIT=100','candidates_created'],
 'scripts/evidence_refresh_cron.php'=>["PHP_SAPI!=='cli'",'TECHSELECT_EVIDENCE_REFRESH_HOURS','TECHSELECT_EVIDENCE_REFRESH_LIMIT','--hours=','--limit=','EvidenceRefreshScheduler::run','scheduler_locked','json_encode']
];
$failed=[];
foreach($checks as $file=>$needles){$text=@file_get_contents($root.'/'.$file)?:'';foreach($needles as $needle)if(strpos($text,$needle)===false)$failed[]="$file missing $needle";}
$scheduler=@file_get_contents($root.'/app/lib/EvidenceRefreshScheduler.php')?:'';
foreach(['EvidenceFactExtractor','EvidenceFactApplicator','UPDATE product_','INSERT INTO evidence_fact_proposals'] as $forbidden)if(strpos($scheduler,$forbidden)!==false)$failed[]="Scheduler must not automate review/application path: $forbidden";
if(strpos($scheduler,"'pending_review'")!==false)$failed[]='Scheduler should delegate candidate creation to EvidenceRefresh::check rather than writing candidates directly';
$cron=@file_get_contents($root.'/scripts/evidence_refresh_cron.php')?:'';
if(strpos($cron,"require_once __DIR__.'/../app/lib/EvidenceRefresh.php'")===false)$failed[]='Cron must load existing safe evidence checker';
if($failed){fwrite(STDERR,"Evidence refresh scheduler checks failed:\n- ".implode("\n- ",$failed)."\n");exit(1);}echo "Evidence refresh scheduler checks passed.\n";
