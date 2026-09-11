<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/Security.php';
require_once __DIR__.'/../app/lib/CommunitySourceCollectors.php';
$config=require __DIR__.'/../app/config.php';$pdo=Db::pdo();Security::start();$u=Security::requireRole(['reviewer','admin','super_admin']);$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';$method=$_SERVER['REQUEST_METHOD']??'GET';
function cc_out($d,int $s=200){http_response_code($s);header('Content-Type: application/json; charset=utf-8');echo json_encode($d,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);exit;}
function cc_body(){return json_decode(file_get_contents('php://input'),true)?:[];}
function cc_write_guard(PDO $pdo,array $config){Security::sameOrigin($config);Security::requireCsrf();Security::rateLimit($pdo,'community-collectors-write',30,60);}
try{
 if($path==='/api/community-collectors'&&$method==='GET'){
  $products=$pdo->query("SELECT id,name,slug FROM products WHERE status='active' ORDER BY name")->fetchAll(PDO::FETCH_ASSOC);
  cc_out(['connectors'=>CommunitySourceCollectors::list($pdo),'products'=>$products,'csrf_token'=>Security::csrf()]);
 }
 if($path==='/api/community-collectors'&&$method==='POST'){
  cc_write_guard($pdo,$config);$b=cc_body();$row=CommunitySourceCollectors::create($pdo,$b,(int)$u['id']);Security::audit($pdo,(int)$u['id'],'COMMUNITY_CONNECTOR_CREATE','public_review_connector',(string)$row['id'],null,$row);cc_out(['connector'=>$row]);
 }
 if(preg_match('#^/api/community-collectors/(\d+)/policy$#',$path,$m)&&$method==='POST'){
  cc_write_guard($pdo,$config);$id=(int)$m[1];$before=CommunitySourceCollectors::get($pdo,$id);$b=cc_body();$after=CommunitySourceCollectors::setPolicy($pdo,$id,(string)($b['policy']??''),isset($b['notes'])?(string)$b['notes']:null);Security::audit($pdo,(int)$u['id'],'COMMUNITY_CONNECTOR_POLICY','public_review_connector',(string)$id,$before,$after);cc_out(['connector'=>$after]);
 }
 if(preg_match('#^/api/community-collectors/(\d+)/run$#',$path,$m)&&$method==='POST'){
  cc_write_guard($pdo,$config);$id=(int)$m[1];$result=CommunitySourceCollectors::run($pdo,$id);Security::audit($pdo,(int)$u['id'],'COMMUNITY_CONNECTOR_RUN','public_review_connector',(string)$id,null,$result);cc_out(['result'=>$result]);
 }
 if(preg_match('#^/api/community-collectors/product/(\d+)/analyze$#',$path,$m)&&$method==='POST'){
  cc_write_guard($pdo,$config);$pid=(int)$m[1];$b=cc_body();$result=CommunitySourceCollectors::analyzePending($pdo,$pid,(int)($b['limit']??25));Security::audit($pdo,(int)$u['id'],'COMMUNITY_COLLECTED_ANALYZE','product',(string)$pid,null,['processed'=>$result['processed']??0,'analysis_run_id'=>$result['analysis_run_id']??null]);cc_out(['result'=>$result]);
 }
 cc_out(['error'=>'not_found'],404);
}catch(InvalidArgumentException $e){cc_out(['error'=>$e->getMessage()],422);}catch(Throwable $e){cc_out(['error'=>$e->getMessage()],409);}
