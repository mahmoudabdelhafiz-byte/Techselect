<?php
$path=__DIR__.'/../frontend/src/App.jsx';
$s=file_get_contents($path);
$errors=[];
if(strpos($s,'/extractions/${extraction.extraction_run_id}/confirm')===false)$errors[]='confirmation endpoint missing from consultation flow';
if(strpos($s,'/recommendations')===false)$errors[]='recommendation endpoint missing from consultation flow';
if(strpos($s,'Find best matches')!==false)$errors[]='legacy second-step Find best matches button still present';
if(strpos($s,'Requirements confirmed. Here are the best matches')===false)$errors[]='single-step confirmation completion message missing';
if(strpos($s,"setProcessingLabel('Evaluating products against your requirements')")===false)$errors[]='automatic evaluation transition missing';
if(strpos($s,">Confirm requirements<")===false)$errors[]='single Confirm requirements action missing';
if($errors){fwrite(STDERR,implode("\n",$errors)."\n");exit(1);}echo "Consultation single-confirm flow contract passed.\n";
