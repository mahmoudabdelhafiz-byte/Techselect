<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/Security.php';
require_once __DIR__.'/../app/lib/PublicConversionAnalytics.php';
$config=require __DIR__.'/../app/config.php';Security::start();$pdo=Db::pdo();
header('Content-Type: application/json; charset=utf-8');
if(($_SERVER['REQUEST_METHOD']??'GET')!=='POST'){http_response_code(405);echo json_encode(['error'=>'method_not_allowed']);exit;}
try{
  Security::sameOrigin($config);Security::rateLimit($pdo,'public_conversion',120,60);
  $b=json_decode(file_get_contents('php://input'),true)?:[];
  PublicConversionAnalytics::record($pdo,$b);
  echo json_encode(['ok'=>true]);
}catch(Throwable $e){http_response_code($e instanceof InvalidArgumentException?422:400);echo json_encode(['error'=>$e->getMessage()]);}
