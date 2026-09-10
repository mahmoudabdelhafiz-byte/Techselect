<?php
$root=dirname(__DIR__);
$ui=file_get_contents($root.'/frontend/src/consultationPromotion.js');
$main=file_get_contents($root.'/frontend/src/main.jsx');
$checks=[
  'promotion GET'=>str_contains($ui,'/promotion`'),
  'impression tracking'=>str_contains($ui,"record(token,'impression'"),
  'click tracking'=>str_contains($ui,"record(token,'click'"),
  'separate from ranking'=>str_contains($ui,'Related solution — shown separately from your ranked software recommendations.'),
  'sponsored disclosure'=>str_contains($ui,'Sponsored · Barmageyat product'),
  'organic backend respected'=>!str_contains($ui,'relevance_score>=')&&!str_contains($ui,'product.slug'),
  'module loaded'=>str_contains($main,"import'./consultationPromotion.js'"),
];
$failed=[];foreach($checks as $name=>$ok){echo ($ok?'PASS':'FAIL')." - $name\n";if(!$ok)$failed[]=$name;}
exit($failed?1:0);
