<?php
$root=dirname(__DIR__);$checks=[
'api/evidence_refresh_review.php'=>['evidence_change_candidates','pending_review','needs_fact_extraction','no_material_change','rejected','Security::requireRole','Security::requireCsrf','Security::sameOrigin','EVIDENCE_REFRESH_DISPOSITION'],
'evidence_refresh_review.php'=>['Evidence Refresh Review','/evidence_refresh_review.js','noindex,nofollow'],
'evidence_refresh_review.js'=>['/api/evidence-refresh/candidates','Escalate for fact extraction','No material fact change','Reject candidate'],
'.htaccess'=>['^evidence-refresh/?$ evidence_refresh_review.php','^api/evidence-refresh(?:/.*)?$ api/evidence_refresh_review.php'],
'frontend/src/accountNav.js'=>['/evidence-refresh','Evidence Refresh']];
$failed=[];foreach($checks as $file=>$needles){$text=@file_get_contents($root.'/'.$file)?:'';foreach($needles as $needle)if(strpos($text,$needle)===false)$failed[]="$file missing $needle";}
$api=@file_get_contents($root.'/api/evidence_refresh_review.php')?:'';foreach(['UPDATE product_capabilities','UPDATE product_pricing','UPDATE product_integrations','UPDATE product_deployment'] as $forbidden)if(strpos($api,$forbidden)!==false)$failed[]="review API must not alter canonical facts: $forbidden";
if($failed){fwrite(STDERR,"Evidence refresh review checks failed:\n- ".implode("\n- ",$failed)."\n");exit(1);}echo "Evidence refresh review checks passed.\n";