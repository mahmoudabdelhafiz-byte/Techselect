<?php
$api=file_get_contents(__DIR__.'/../api/recommend.php');
$app=file_get_contents(__DIR__.'/../frontend/src/App.jsx');
$audit=file_get_contents(__DIR__.'/catalog_quality_audit.php');

$checks=[
  'API exposes evidence coverage' => str_contains($api,"'evidence_coverage'=>"),
  'API exposes known fact count' => str_contains($api,"'known_fact_count'=>"),
  'API exposes requirement count' => str_contains($api,"'requirement_count'=>"),
  'API warns on limited coverage' => str_contains($api,'Limited evidence coverage:'),
  'API preserves unknown != unsupported wording' => str_contains($api,'Unknown does not mean unsupported.'),
  'UI renders evidence coverage' => str_contains($app,'Known evidence ${known}/${total} requested criteria'),
  'UI renders evidence warning' => str_contains($app,'r.evidence_warning'),
  'UI uses singular mandatory gap copy' => str_contains($app,"1 mandatory gap requires review."),
  'UI removed gap(s) placeholder' => !str_contains($app,'gap(s)'),
  'Audit measures full product capability matrix' => str_contains($audit,'recorded_matrix='),
  'Audit includes product evidence coverage' => str_contains($audit,'[Product evidence coverage]'),
];

$failed=0;
foreach($checks as $name=>$ok){
  echo ($ok?'PASS':'FAIL')."  $name\n";
  if(!$ok)$failed++;
}
exit($failed?1:0);
