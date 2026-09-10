<?php
$root=dirname(__DIR__);
$files=[
  'builder'=>(string)@file_get_contents($root.'/app/lib/AiFactualSummary.php'),
  'wrapper'=>(string)@file_get_contents($root.'/knowledge_page.php'),
  'routes'=>(string)@file_get_contents($root.'/.htaccess'),
];
$checks=[
  'software summary builder'=>strpos($files['builder'],'private static function software')!==false,
  'comparison summary builder'=>strpos($files['builder'],'private static function comparison')!==false,
  'unknown stays distinct'=>strpos($files['builder'],'not yet verified')!==false && strpos($files['builder'],'not supported')!==false,
  'visible factual summary'=>strpos($files['builder'],'data-citation-section="factual-summary"')!==false,
  'structured data'=>strpos($files['wrapper'],'application/ld+json')!==false,
  'software route'=>strpos($files['routes'],'^software/[a-z0-9-]+/?$ knowledge_page.php')!==false,
  'comparison route'=>strpos($files['routes'],'^compare/[a-z0-9-]+-vs-[a-z0-9-]+/?$ knowledge_page.php')!==false,
  'no scoring mutation'=>strpos($files['builder'],'Scoring::')===false && strpos($files['builder'],'UPDATE consultation_product_scores')===false,
];
$failed=[];foreach($checks as $label=>$ok){echo ($ok?'PASS':'FAIL').' '.$label.PHP_EOL;if(!$ok)$failed[]=$label;}
if($failed){fwrite(STDERR,"AI factual summary checks failed:\n- ".implode("\n- ",$failed)."\n");exit(1);}echo "AI factual summary checks passed.\n";
