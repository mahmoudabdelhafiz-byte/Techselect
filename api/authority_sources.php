<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/Security.php';
require_once __DIR__.'/../app/lib/AuthoritySources.php';
$config=require __DIR__.'/../app/config.php';$pdo=Db::pdo();Security::start();
$u=Security::requireRole(['reviewer','admin','super_admin']);
$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';$method=$_SERVER['REQUEST_METHOD']??'GET';
function out($d,int $s=200){http_response_code($s);header('Content-Type: application/json; charset=utf-8');echo json_encode($d,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);exit;}
function body(){return json_decode(file_get_contents('php://input'),true)?:[];}
if($method!=='GET'){Security::sameOrigin($config);Security::requireCsrf();Security::rateLimit($pdo,'authority-sources-write',40,60);}
try{
  if($path==='/api/authority-sources'&&$method==='GET'){Security::rateLimit($pdo,'authority-sources-read',120,60);out(['summary'=>AuthoritySources::summary($pdo),'sources'=>AuthoritySources::list($pdo)]);}
  if($path==='/api/authority-sources'&&$method==='POST'){$r=AuthoritySources::save($pdo,body(),(int)$u['id']);Security::audit($pdo,(int)$u['id'],'AUTHORITY_SOURCE_CREATE','authority_source',(string)$r['id'],null,['domain'=>$r['domain'],'outreach_status'=>$r['outreach_status'],'backlink_status'=>$r['backlink_status']]);out(['source'=>$r],201);}
  if(preg_match('#^/api/authority-sources/(\d+)$#',$path,$m)&&in_array($method,['PUT','PATCH'],true)){$id=(int)$m[1];$before=AuthoritySources::get($pdo,$id);$r=AuthoritySources::save($pdo,body(),(int)$u['id'],$id);Security::audit($pdo,(int)$u['id'],'AUTHORITY_SOURCE_UPDATE','authority_source',(string)$id,['outreach_status'=>$before['outreach_status'],'backlink_status'=>$before['backlink_status'],'published_url'=>$before['published_url']],['outreach_status'=>$r['outreach_status'],'backlink_status'=>$r['backlink_status'],'published_url'=>$r['published_url']]);out(['source'=>$r]);}
}catch(Throwable $e){$code=$e instanceof InvalidArgumentException?422:400;out(['error'=>$e->getMessage()],$code);}
out(['error'=>'not_found'],404);
