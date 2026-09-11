<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/Security.php';
require_once __DIR__.'/../app/lib/IndexationHealth.php';
$config=require __DIR__.'/../app/config.php';
$pdo=Db::pdo();Security::start();$user=Security::requireRole(['reviewer','admin','super_admin']);
$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';$method=$_SERVER['REQUEST_METHOD']??'GET';
function ih_out($d,int $s=200){http_response_code($s);header('Content-Type: application/json; charset=utf-8');echo json_encode($d,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);exit;}
function ih_body(){return json_decode(file_get_contents('php://input'),true)?:[];}
function ih_sitemap_paths(string $siteUrl):array{
  $url=rtrim($siteUrl,'/').'/sitemap.xml';$ctx=stream_context_create(['http'=>['timeout'=>8,'user_agent'=>'TechSelectAI-IndexationHealth/1.0'],'ssl'=>['verify_peer'=>true,'verify_peer_name'=>true]]);$xml=@file_get_contents($url,false,$ctx);if($xml===false||trim($xml)==='')throw new RuntimeException('sitemap_unavailable');
  libxml_use_internal_errors(true);$sx=simplexml_load_string($xml);if(!$sx)throw new RuntimeException('invalid_sitemap');$paths=[];foreach($sx->url as $u){$loc=trim((string)$u->loc);$p=parse_url($loc,PHP_URL_PATH);if(is_string($p)&&$p!=='')$paths[]=$p;}return array_values(array_unique($paths));
}
if($method!=='GET'){Security::sameOrigin($config);Security::requireCsrf();Security::rateLimit($pdo,'indexation-health-write',20,300);}

if($path==='/api/indexation-health'&&$method==='GET')ih_out(IndexationHealth::dashboard($pdo)+['csrf_token'=>Security::csrf()]);

if($path==='/api/indexation-health/sync'&&$method==='POST'){
  try{$paths=ih_sitemap_paths((string)$config['site_url']);}catch(Throwable $e){ih_out(['error'=>$e->getMessage()],502);} $summary=IndexationHealth::syncExpected($pdo,(string)$config['site_url'],$paths);
  $pdo->prepare('INSERT INTO indexation_health_runs(source,total_known_urls,sitemap_urls,strategic_urls,issue_count,summary_json,created_by_user_id) VALUES(?,?,?,?,?,?,?)')->execute(['internal_audit',$summary['known'],count($paths),$summary['strategic'],$summary['issues'],json_encode($summary),(int)$user['id']]);
  Security::audit($pdo,(int)$user['id'],'INDEXATION_HEALTH_SYNC','seo_indexation','sitemap',null,$summary);ih_out(['synced'=>true,'sitemap_url_count'=>count($paths),'summary'=>$summary]);
}

if($path==='/api/indexation-health/import'&&$method==='POST'){
  $b=ih_body();$rows=is_array($b['rows']??null)?$b['rows']:[];$source=trim((string)($b['source']??'manual_import'));if(!$rows)ih_out(['error'=>'rows_required'],422);
  try{$count=IndexationHealth::importIndexStates($pdo,$rows,$source);}catch(InvalidArgumentException $e){ih_out(['error'=>$e->getMessage()],422);}Security::audit($pdo,(int)$user['id'],'INDEXATION_STATE_IMPORT','seo_indexation',$source,null,['rows'=>$count]);ih_out(['imported'=>$count]);
}

ih_out(['error'=>'not_found'],404);
