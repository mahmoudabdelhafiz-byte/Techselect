<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/Security.php';
require_once __DIR__.'/../app/lib/SoftwareSubmission.php';
$config=require __DIR__.'/../app/config.php';
$pdo=Db::pdo();Security::start();
$method=$_SERVER['REQUEST_METHOD']??'GET';
function ss_out($d,int $s=200){http_response_code($s);header('Content-Type: application/json; charset=utf-8');echo json_encode($d,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);exit;}
if($method==='GET'){
  $name=trim((string)($_GET['name']??''));$website=trim((string)($_GET['website']??''));
  if($name==='')ss_out(['duplicate'=>null]);
  $dup=SoftwareSubmission::findDuplicate($pdo,$name,$website?:null);
  ss_out(['duplicate'=>$dup]);
}
if($method==='POST'){
  Security::sameOrigin($config);Security::requireCsrf();Security::rateLimit($pdo,'software-submission',6,300);
  $body=json_decode(file_get_contents('php://input'),true)?:[];
  try{$created=SoftwareSubmission::create($pdo,$body);}catch(InvalidArgumentException $e){ss_out(['error'=>$e->getMessage()],422);}catch(Throwable $e){ss_out(['error'=>'submission_failed'],500);}
  Security::audit($pdo,null,'SOFTWARE_SUBMISSION_CREATE','software_submission',(string)$created['id'],null,['status'=>$created['status'],'submission_type'=>$body['submission_type']??'user_suggestion']);
  ss_out(['submitted'=>true]+$created,201);
}
ss_out(['error'=>'method_not_allowed'],405);
