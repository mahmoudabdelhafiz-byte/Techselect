<?php
/** Static migration integrity checks for known high-risk failure modes. */
$root=dirname(__DIR__);
$files=glob($root.'/db/mysql/*.sql')?:[];
sort($files,SORT_NATURAL);
$errors=[];$constraints=[];
foreach($files as $file){
  $src=file_get_contents($file)?:'';$name=basename($file);
  if($name==='036_rfp_documents.sql'){
    if(str_contains($src,'REFERENCES project_matrix_runs'))$errors[]="$name references obsolete project_matrix_runs";
    if(!str_contains($src,'REFERENCES selection_project_matrix_runs'))$errors[]="$name missing selection_project_matrix_runs reference";
  }
  if(preg_match_all('/\bCONSTRAINT\s+([A-Za-z0-9_]+)/i',$src,$m)){
    foreach($m[1] as $c){$k=strtolower($c);if(isset($constraints[$k]))$errors[]="duplicate explicit constraint name $c in $name and {$constraints[$k]}";else $constraints[$k]=$name;}
  }
}
$buyer=file_get_contents($root.'/db/mysql/019_buyer_intent_analytics.sql')?:'';
if(!str_contains($buyer,'information_schema.KEY_COLUMN_USAGE'))$errors[]='019 buyer-intent FK is not guarded for partial/rerun installs';
if(!str_contains($buyer,"fk_ts_consultations_industry_019"))$errors[]='019 missing schema-unique consultation industry FK name';
if($errors){fwrite(STDERR,"Migration integrity check failed:\n- ".implode("\n- ",$errors)."\n");exit(1);}echo "Migration integrity check passed across ".count($files)." migrations.\n";
