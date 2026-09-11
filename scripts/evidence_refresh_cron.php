<?php
if(PHP_SAPI!=='cli'){http_response_code(404);exit;}
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/EvidenceRefresh.php';
require_once __DIR__.'/../app/lib/EvidenceRefreshScheduler.php';

$interval=(int)(getenv('TECHSELECT_EVIDENCE_REFRESH_HOURS')?:168);
$limit=(int)(getenv('TECHSELECT_EVIDENCE_REFRESH_LIMIT')?:25);
foreach(array_slice($argv,1) as $arg){
  if(str_starts_with($arg,'--hours='))$interval=(int)substr($arg,8);
  elseif(str_starts_with($arg,'--limit='))$limit=(int)substr($arg,8);
}

try{
  $result=EvidenceRefreshScheduler::run(Db::pdo(),$interval,$limit);
  echo json_encode(['ok'=>true,'interval_hours'=>$interval,'batch_limit'=>$limit]+$result,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE).PHP_EOL;
  exit(0);
}catch(InvalidArgumentException $e){
  fwrite(STDERR,json_encode(['ok'=>false,'error'=>$e->getMessage()],JSON_UNESCAPED_SLASHES).PHP_EOL);exit(2);
}catch(RuntimeException $e){
  $code=$e->getMessage()==='scheduler_locked'?3:1;
  fwrite(STDERR,json_encode(['ok'=>false,'error'=>$e->getMessage()],JSON_UNESCAPED_SLASHES).PHP_EOL);exit($code);
}catch(Throwable $e){
  fwrite(STDERR,json_encode(['ok'=>false,'error'=>'scheduler_failed'],JSON_UNESCAPED_SLASHES).PHP_EOL);exit(1);
}
