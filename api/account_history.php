<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/Security.php';
require_once __DIR__.'/../app/lib/UserConsultationHistory.php';
$config=require __DIR__.'/../app/config.php';
$pdo=Db::pdo();Security::start();
$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';$method=$_SERVER['REQUEST_METHOD']??'GET';
function ah_out($d,int $s=200){http_response_code($s);header('Content-Type: application/json; charset=utf-8');echo json_encode($d,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);exit;}
$user=Security::user();if(!$user)ah_out(['error'=>'authentication_required'],401);
if($path==='/api/account/consultations'&&$method==='GET'){
  $limit=(int)($_GET['limit']??50);ah_out(['consultations'=>UserConsultationHistory::listForUser($pdo,(int)$user['id'],$limit)]);
}
if($path==='/api/account/claim-consultation'&&$method==='POST'){
  Security::sameOrigin($config);Security::rateLimit($pdo,'claim-consultation',20,300);Security::requireCsrf();
  $b=json_decode(file_get_contents('php://input'),true)?:[];$token=strtolower(trim((string)($b['visitor_token']??'')));
  if(!preg_match('/^[a-f0-9]{48}$/',$token))ah_out(['error'=>'invalid_visitor_token'],422);
  $claimed=UserConsultationHistory::claim($pdo,(int)$user['id'],$token);
  if($claimed>0)Security::audit($pdo,(int)$user['id'],'CLAIM_CONSULTATION','visitor_session',null,null,['claimed'=>$claimed]);
  ah_out(['claimed'=>$claimed]);
}
ah_out(['error'=>'not_found'],404);
