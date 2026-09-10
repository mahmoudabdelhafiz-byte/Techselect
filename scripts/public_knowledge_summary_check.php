<?php
$root=dirname(__DIR__);
$summary=file_get_contents($root.'/app/lib/PublicKnowledgeSummary.php');
$brand=file_get_contents($root.'/brand_page.php');
$checks=[
  'software summary path'=>strpos($summary,"^/software/")!==false,
  'comparison summary path'=>strpos($summary,"^/compare/")!==false,
  'unknown separated from unsupported'=>strpos($summary,'Unknown / not yet verified')!==false && strpos($summary,'Not supported')!==false,
  'visible factual summary anchor'=>strpos($summary,'id="factual-summary"')!==false,
  'structured data output'=>strpos($brand,'application/ld+json')!==false && strpos($brand,'PublicKnowledgeSummary::build')!==false,
  'no scoring changes in wrapper'=>strpos($brand,'ranking_score')===false && strpos($brand,'overall_score')===false,
  'best effort rendering'=>strpos($brand,'catch(Throwable $e){}')!==false,
];
$failed=[];foreach($checks as $name=>$ok){echo ($ok?'PASS':'FAIL')." - $name\n";if(!$ok)$failed[]=$name;}
if($failed){fwrite(STDERR,"Public knowledge summary validation failed: ".implode(', ',$failed)."\n");exit(1);}echo "Public knowledge summary validation passed.\n";
