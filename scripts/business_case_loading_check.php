<?php
$path=__DIR__.'/../business_case_builder.php';
$src=file_get_contents($path);
$checks=[
  'loads saved case before csrf'=>strpos($src,"const d=await req('/api/business-cases/'+id)")!==false && strpos($src,"const d=await req('/api/business-cases/'+id)") < strpos($src,"const auth=await req('/api/auth/csrf')"),
  'draft renders without generated output'=>strpos($src,'Saved draft.')!==false,
  'requests time out instead of spinning forever'=>strpos($src,'AbortController')!==false && strpos($src,'request timed out')!==false,
  'csrf still protects save'=>strpos($src,"'X-CSRF-Token':csrf")!==false,
  'clear load failure state'=>strpos($src,'Unable to load this business case.')!==false,
];
$failed=[];foreach($checks as $name=>$ok){echo ($ok?'PASS ':'FAIL ').$name.PHP_EOL;if(!$ok)$failed[]=$name;}
exit($failed?1:0);
