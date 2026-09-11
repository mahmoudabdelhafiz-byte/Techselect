<?php
require_once __DIR__.'/../app/lib/ProductEvaluation.php';

$weights=[
  'usability'=>12,
  'implementation_complexity'=>10,
  'integration_depth'=>15,
  'administration_overhead'=>8,
  'value'=>10,
  'support_community'=>10,
  'security_compliance'=>15,
  'enterprise_suitability'=>10,
  'smb_suitability'=>5,
  'product_maturity'=>5,
];

$fail=[];
if(array_sum($weights)!==100)$fail[]='Methodology weights must total 100.';
if(count(array_diff_key($weights,ProductEvaluation::DIMENSIONS))>0)$fail[]='All weighted dimensions must be declared by ProductEvaluation.';
if(ProductEvaluation::weightedScore(['usability'=>8,'integration_depth'=>10],['usability'=>50,'integration_depth'=>50])!==9.0)$fail[]='Weighted score calculation failed.';
if(ProductEvaluation::weightedScore([],[])!==null)$fail[]='Empty evaluation must not produce a score.';
if(ProductEvaluation::confidenceLabel(.86)!=='High' || ProductEvaluation::confidenceLabel(.60)!=='Limited')$fail[]='Confidence labels failed.';

$migration=file_get_contents(__DIR__.'/../db/mysql/038_product_evaluations.sql');
foreach(['evaluation_methodologies','product_evaluations','product_evaluation_dimensions','product_evaluation_evidence','product-v1.0'] as $needle){
  if(strpos($migration,$needle)===false)$fail[]='Migration missing '.$needle;
}

if($fail){fwrite(STDERR,implode("\n",$fail)."\n");exit(1);}
echo "product evaluation foundation: OK\n";
