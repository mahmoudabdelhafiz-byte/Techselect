<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/Security.php';
require_once __DIR__.'/../app/lib/TaxonomyExpansionQueue.php';
$config=require __DIR__.'/../app/config.php';
$pdo=Db::pdo();Security::start();$u=Security::requireRole(['admin','data_editor','reviewer','super_admin']);
$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';$method=$_SERVER['REQUEST_METHOD']??'GET';
function tq_out($d,int $s=200){http_response_code($s);header('Content-Type: application/json; charset=utf-8');echo json_encode($d,JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES);exit;}
function tq_body(){return json_decode(file_get_contents('php://input'),true)?:[];}
if($method!=='GET'){Security::sameOrigin($config);Security::requireCsrf();Security::rateLimit($pdo,'taxonomy-admin-write',40,60);}
if($path==='/api/taxonomy/queue'&&$method==='GET'){try{tq_out(['items'=>TaxonomyExpansionQueue::list($pdo)]);}catch(Throwable $e){tq_out(['error'=>'taxonomy_queue_unavailable'],503);}}
if(preg_match('#^/api/taxonomy/queue/(\d+)$#',$path,$m)&&$method==='PATCH'){
  try{$id=(int)$m[1];$new=TaxonomyExpansionQueue::update($pdo,$id,tq_body());Security::audit($pdo,(int)$u['id'],'TAXONOMY_QUEUE_UPDATE','taxonomy_expansion_queue',(string)$id,null,$new);tq_out(['item'=>$new]);}catch(Throwable $e){$code=$e->getMessage()==='not_found'?404:422;tq_out(['error'=>$e->getMessage()],$code);}
}
tq_out(['error'=>'not_found'],404);
