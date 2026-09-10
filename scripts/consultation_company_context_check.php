<?php
$root=dirname(__DIR__);
$checks=[
  'secure api route'=>['api/secure.php','/context'],
  'context fields'=>['api/secure.php','company_size_band'],
  'industry validation'=>['api/secure.php','SELECT id FROM industries'],
  'frontend module'=>['frontend/src/consultationContext.js','Company context'],
  'frontend entry import'=>['frontend/src/main.jsx','consultationContext.js'],
  'optional copy'=>['frontend/src/consultationContext.js','None of these fields is required']
];
$ok=true;
foreach($checks as $name=>$c){[$file,$needle]=$c;$text=@file_get_contents($root.'/'.$file);$pass=$text!==false&&str_contains($text,$needle);echo ($pass?'PASS':'FAIL')." - $name\n";$ok=$ok&&$pass;}
exit($ok?0:1);
