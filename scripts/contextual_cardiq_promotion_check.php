<?php
$root=dirname(__DIR__);
$files=[
  'app/lib/CardIqPromotion.php',
  'api/promotion.php',
  'db/mysql/020_cardiq_contextual_promotion.sql',
  '.htaccess'
];
foreach($files as $f){if(!is_file($root.'/'.$f)){fwrite(STDERR,"Missing {$f}\n");exit(1);}}
$engine=file_get_contents($root.'/app/lib/CardIqPromotion.php');
$api=file_get_contents($root.'/api/promotion.php');
$route=file_get_contents($root.'/.htaccess');
$checks=[
  'organic #1 suppression'=>str_contains($engine,"==='cardiq'"),
  'max two impressions'=>str_contains($engine,'MAX_IMPRESSIONS_PER_SESSION=2'),
  'separate sponsored disclosure'=>str_contains($engine,'separate from TechSelectAI Fit Score'),
  'identity control positioning'=>str_contains($engine,'corporate identity control')||str_contains($engine,'Corporate Identity'),
  'no ranking mutation'=>!str_contains($engine,'UPDATE consultation_recommendations')&&!str_contains($engine,'overall_score='),
  'impression and click events'=>str_contains($api,'impression|click'),
  'promotion route before consultation fallback'=>strpos($route,'promotion(?:/(?:impression|click))')<strpos($route,'^api/consultations(?:/.*)?$')
];
$failed=[];foreach($checks as $name=>$ok){echo ($ok?'PASS ':'FAIL ').$name."\n";if(!$ok)$failed[]=$name;}
exit($failed?1:0);
