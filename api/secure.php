<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/Security.php';
require_once __DIR__.'/../app/lib/UserConsultationHistory.php';
$config=require __DIR__.'/../app/config.php';
$pdo=Db::pdo();
Security::start();
$method=$_SERVER['REQUEST_METHOD']??'GET';
$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';
if(in_array($method,['POST','PUT','PATCH','DELETE'],true)){
  Security::sameOrigin($config);
  Security::rateLimit($pdo,'consultation-write',40,60);
  if(Security::user()) Security::requireCsrf();
}

if($path==='/api/consultations' && $method==='POST'){
  $body=json_decode(file_get_contents('php://input'),true)?:[];
  $problem=trim((string)($body['business_problem']??''));
  if(strlen($problem)<5){http_response_code(422);header('Content-Type: application/json; charset=utf-8');echo json_encode(['error'=>'business_problem_required']);exit;}
  try{$created=UserConsultationHistory::create($pdo,Security::user(),$problem,'ai_chat');}
  catch(Throwable $e){http_response_code(500);header('Content-Type: application/json; charset=utf-8');echo json_encode(['error'=>'consultation_create_failed']);exit;}
  http_response_code(201);header('Content-Type: application/json; charset=utf-8');echo json_encode($created,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);exit;
}

require __DIR__.'/index.php';
