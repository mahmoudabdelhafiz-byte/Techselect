<?php
$root=dirname(__DIR__);
$files=['software_page.php','capability_page.php','integration_page.php','comparison_page.php'];
$required=['id="overview"','data-citation-section'];
$failed=[];
foreach($files as $file){
  $c=(string)@file_get_contents($root.'/'.$file);
  foreach($required as $needle){if(strpos($c,$needle)===false)$failed[]=$file.' missing '.$needle;}
}
$checks=[
  'software capabilities anchor'=>strpos((string)@file_get_contents($root.'/software_page.php'),'id="capabilities"')!==false,
  'capability support anchor'=>strpos((string)@file_get_contents($root.'/capability_page.php'),'id="product-support"')!==false,
  'integration support anchor'=>strpos((string)@file_get_contents($root.'/integration_page.php'),'id="product-support"')!==false,
  'comparison capabilities anchor'=>strpos((string)@file_get_contents($root.'/comparison_page.php'),'id="capability-comparison"')!==false,
  'comparison integrations anchor'=>strpos((string)@file_get_contents($root.'/comparison_page.php'),'id="integration-comparison"')!==false,
];
foreach($checks as $label=>$ok){if(!$ok)$failed[]=$label;}
if($failed){foreach($failed as $f)fwrite(STDERR,"FAIL $f\n");exit(1);}echo "AI citation anchor checks passed.\n";
