<?php
$root=dirname(__DIR__);
$checks=[
 'db/mysql/023_evidence_fact_proposals.sql'=>['CREATE TABLE IF NOT EXISTS evidence_fact_proposals','approved_for_application','candidate_id'],
 'app/lib/EvidenceRefresh.php'=>['fetchForReview','MAX_BYTES','validateUrl'],
 'app/lib/EvidenceFactExtractor.php'=>['Evidence Fact Extraction','not_yet_verified','not_supported','json_schema','proposals'],
 'api/evidence_refresh_review.php'=>['/extract','/proposals','approved_for_application','EVIDENCE_FACT_PROPOSAL_DISPOSITION'],
 'evidence_refresh_review.js'=>['Generate fact proposals','Approve for application','data-proposal-act']
];
$failed=[];foreach($checks as $file=>$needles){$path=$root.'/'.$file;$text=is_file($path)?file_get_contents($path):'';foreach($needles as $needle)if(strpos($text,$needle)===false)$failed[]="$file missing $needle";}
if($failed){fwrite(STDERR,"Evidence fact proposal check failed:\n- ".implode("\n- ",$failed)."\n");exit(1);}echo "Evidence fact proposal check passed.\n";
