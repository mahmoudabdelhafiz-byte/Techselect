<?php
$root=dirname(__DIR__);
$brand=(string)@file_get_contents($root.'/brand_page.php');
$checks=[
  'public knowledge gate'=>strpos($brand,'$isPublicKnowledge')!==false,
  'llms alternate link'=>strpos($brand,'href="/llms.txt"')!==false,
  'overview anchor'=>strpos($brand,'id="overview" data-citation-section="overview"')!==false,
  'product support anchor'=>strpos($brand,"'Product support'=>'product-support'")!==false,
  'capability comparison anchor'=>strpos($brand,"'Capability comparison'=>'capability-comparison'")!==false,
  'integration comparison anchor'=>strpos($brand,"'Integration comparison'=>'integration-comparison'")!==false,
  'deployment comparison anchor'=>strpos($brand,"'Deployment comparison'=>'deployment-comparison'")!==false,
  'evidence anchor'=>strpos($brand,"'Evidence sources'=>'evidence'")!==false,
  'verified reviews anchor'=>strpos($brand,'id="verified-reviews"')!==false,
  'no crawler conditional'=>strpos($brand,'HTTP_USER_AGENT')===false && strpos($brand,'OAI-SearchBot')===false,
];
$failed=[];foreach($checks as $label=>$ok){echo ($ok?'PASS':'FAIL').' '.$label.PHP_EOL;if(!$ok)$failed[]=$label;}
if($failed){fwrite(STDERR,"AI citation anchor checks failed:\n- ".implode("\n- ",$failed)."\n");exit(1);}echo "AI citation anchor checks passed.\n";
