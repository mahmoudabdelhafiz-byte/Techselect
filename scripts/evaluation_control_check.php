<?php
$files=[
  __DIR__.'/../db/mysql/040_evaluation_control_center.sql'=>['evaluation_proposals','product_evaluation_history','revision_number'],
  __DIR__.'/../app/lib/EvaluationProposalService.php'=>['MIN_EVIDENCE','MIN_CONFIDENCE','proposed_change','publication_threshold_not_met','product_evaluation_history','OpenAI'],
  __DIR__.'/../api/evaluation_control.php'=>['EVALUATION_PROPOSAL_GENERATED','EVALUATION_PROPOSAL_REVIEW','requireRole'],
  __DIR__.'/../evaluation_control.php'=>['AI Evaluation Control Center','Only a reviewer can publish'],
  __DIR__.'/../evaluation_control.js'=>['Generate proposed evaluation','Approve & publish','Request more evidence','Reject'],
  __DIR__.'/../.htaccess'=>['evaluation-control','api/evaluation-control'],
];
$fail=[];foreach($files as $path=>$needles){$src=file_get_contents($path);if($src===false){$fail[]='Missing '.$path;continue;}foreach($needles as $n)if(strpos($src,$n)===false)$fail[]=$path.' missing '.$n;}
if($fail){fwrite(STDERR,implode("\n",$fail)."\n");exit(1);}echo "evaluation_control_check: OK\n";
