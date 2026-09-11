<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/Security.php';
require_once __DIR__.'/../app/lib/CustomerOutcomes.php';
$config=require __DIR__.'/../app/config.php';$pdo=Db::pdo();Security::start();
$u=Security::requireRole(['reviewer','admin','super_admin']);
$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';$method=$_SERVER['REQUEST_METHOD']??'GET';
function out($d,int $s=200){http_response_code($s);header('Content-Type: application/json; charset=utf-8');echo json_encode($d,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);exit;}
function body(){return json_decode(file_get_contents('php://input'),true)?:[];}
if($method!=='GET'){Security::sameOrigin($config);Security::requireCsrf();Security::rateLimit($pdo,'customer-outcomes-write',40,60);}
try{
  if($path==='/api/customer-outcomes'&&$method==='GET'){Security::rateLimit($pdo,'customer-outcomes-read',120,60);out(['outcomes'=>CustomerOutcomes::listAdmin($pdo)]);}
  if($path==='/api/customer-outcomes'&&$method==='POST'){$b=body();$r=CustomerOutcomes::save($pdo,$b,(int)$u['id']);Security::audit($pdo,(int)$u['id'],'CUSTOMER_OUTCOME_CREATE','customer_outcome',(string)$r['id'],null,['verification_status'=>$r['verification_status'],'publication_status'=>$r['publication_status']]);out(['outcome'=>$r],201);}
  if(preg_match('#^/api/customer-outcomes/(\d+)$#',$path,$m)&&$method==='GET'){out(['outcome'=>CustomerOutcomes::get($pdo,(int)$m[1])]);}
  if(preg_match('#^/api/customer-outcomes/(\d+)$#',$path,$m)&&in_array($method,['PUT','PATCH'],true)){$id=(int)$m[1];$old=CustomerOutcomes::get($pdo,$id);$r=CustomerOutcomes::save($pdo,body(),(int)$u['id'],$id);Security::audit($pdo,(int)$u['id'],'CUSTOMER_OUTCOME_UPDATE','customer_outcome',(string)$id,['verification_status'=>$old['verification_status'],'publication_status'=>$old['publication_status']],['verification_status'=>$r['verification_status'],'publication_status'=>$r['publication_status']]);out(['outcome'=>$r]);}
}catch(Throwable $e){$code=$e instanceof InvalidArgumentException?422:400;out(['error'=>$e->getMessage()],$code);}
out(['error'=>'not_found'],404);
