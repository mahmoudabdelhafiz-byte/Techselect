<?php
$root=dirname(__DIR__);$fail=[];
$need=[
 'db/mysql/035_project_decision_matrix.sql'=>['selection_project_matrix_runs','selection_project_shortlist','baseline_evaluation_score'],
 'app/lib/ProjectDecisionMatrix.php'=>['project-fit-v1.0','mandatoryGaps','weightedOverall','not_available_in_current_model'],
 'api/project_matrix.php'=>['basic_decision_matrix','weighted_decision_matrix','rich_exports','PROJECT_MATRIX_GENERATE','PROJECT_SHORTLIST_STATE'],
 'project_decision_matrix.php'=>['Project-specific fit','baseline TechSelectAI evaluation','Sensitivity'],
 '.htaccess'=>['decision-matrix','api/project_matrix.php'],
];
foreach($need as $file=>$tokens){$p=$root.'/'.$file;if(!is_file($p)){$fail[]="missing $file";continue;}$c=file_get_contents($p);foreach($tokens as $t)if(strpos($c,$t)===false)$fail[]="$file missing $t";}
$c=file_get_contents($root.'/app/lib/ProjectDecisionMatrix.php');
if(strpos($c,"'not_yet_verified'=>")!==false)$fail[]='duplicate support map must not be introduced; reuse Scoring';
if(strpos($c,"baseline_evaluation_score'=>null")===false)$fail[]='baseline evaluation must remain separate rather than synthesized';
if(strpos($c,"partner_options'=>[]")===false)$fail[]='unverified partner coverage must not be fabricated';
if($fail){fwrite(STDERR,"FAIL\n- ".implode("\n- ",$fail)."\n");exit(1);}echo "OK project decision matrix regression checks\n";