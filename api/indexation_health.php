<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/Security.php';
require_once __DIR__.'/../app/lib/IndexationHealth.php';
$config=require __DIR__.'/../app/config.php';
$pdo=Db::pdo();Security::start();$user=Security::requireRole(['reviewer','admin','super_admin']);
$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';$method=$_SERVER['REQUEST_METHOD']??'GET';
function ih_out($d,int $s=200){http_response_code($s);header('Content-Type: application/json; charset=utf-8');echo json_encode($d,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);exit;}
function ih_body(){return json_decode(file_get_contents('php://input'),true)?:[];}
function ih_sitemap_entries(string $siteUrl):array{
  $url=rtrim($siteUrl,'/').'/sitemap.xml';$ctx=stream_context_create(['http'=>['timeout'=>8,'follow_location'=>0,'user_agent'=>'TechSelectAI-IndexationHealth/2.0'],'ssl'=>['verify_peer'=>true,'verify_peer_name'=>true]]);$xml=@file_get_contents($url,false,$ctx);if($xml===false||trim($xml)==='')throw new RuntimeException('sitemap_unavailable');
  libxml_use_internal_errors(true);$sx=simplexml_load_string($xml);if(!$sx)throw new RuntimeException('invalid_sitemap');$entries=[];foreach($sx->url as $u){$loc=trim((string)$u->loc);$p=parse_url($loc,PHP_URL_PATH);if(is_string($p)&&$p!=='')$entries[$p]=['path'=>$p,'lastmod'=>trim((string)$u->lastmod)?:null];}return array_values($entries);
}
if($method!=='GET'){Security::sameOrigin($config);Security::requireCsrf();Security::rateLimit($pdo,'indexation-health-write',20,300);}

if($path==='/api/indexation-health'&&$method==='GET')ih_out(IndexationHealth::dashboard($pdo)+['csrf_token'=>Security::csrf()]);

if($path==='/api/indexation-health/sync'&&$method==='POST'){
  try{$entries=ih_sitemap_entries((string)$config['site_url']);}catch(Throwable $e){ih_out(['error'=>$e->getMessage()],502);} $summary=IndexationHealth::syncExpected($pdo,(string)$config['site_url'],$entries);
  try{$snapshot=IndexationHealth::recordDailySnapshot($pdo);}catch(Throwable $e){$snapshot=null;}
  $pdo->prepare('INSERT INTO indexation_health_runs(source,total_known_urls,sitemap_urls,strategic_urls,issue_count,summary_json,created_by_user_id) VALUES(?,?,?,?,?,?,?)')->execute(['internal_audit',$summary['known'],count($entries),$summary['strategic'],$summary['issues'],json_encode(['sync'=>$summary,'snapshot'=>$snapshot]),(int)$user['id']]);
  Security::audit($pdo,(int)$user['id'],'INDEXATION_HEALTH_SYNC','seo_indexation','sitemap',null,$summary);ih_out(['synced'=>true,'sitemap_url_count'=>count($entries),'summary'=>$summary,'snapshot'=>$snapshot]);
}

if($path==='/api/indexation-health/probe'&&$method==='POST'){
  $b=ih_body();$limit=(int)($b['limit']??75);try{$result=IndexationHealth::probeStrategic($pdo,(string)$config['site_url'],$limit);$snapshot=IndexationHealth::recordDailySnapshot($pdo);}catch(Throwable $e){ih_out(['error'=>$e->getMessage()],500);}Security::audit($pdo,(int)$user['id'],'INDEXATION_LIVE_PROBE','seo_indexation','strategic',null,$result);ih_out(['probed'=>true,'result'=>$result,'snapshot'=>$snapshot]);
}

if($path==='/api/indexation-health/snapshot'&&$method==='POST'){
  try{$snapshot=IndexationHealth::recordDailySnapshot($pdo);}catch(Throwable $e){ih_out(['error'=>$e->getMessage()],500);}Security::audit($pdo,(int)$user['id'],'INDEXATION_SNAPSHOT','seo_indexation',date('Y-m-d'),null,$snapshot);ih_out(['snapshot'=>$snapshot]);
}

if($path==='/api/indexation-health/import'&&$method==='POST'){
  $b=ih_body();$rows=is_array($b['rows']??null)?$b['rows']:[];$source=trim((string)($b['source']??'manual_import'));if(!$rows)ih_out(['error'=>'rows_required'],422);
  try{$count=IndexationHealth::importIndexStates($pdo,$rows,$source);$snapshot=IndexationHealth::recordDailySnapshot($pdo);}catch(InvalidArgumentException $e){ih_out(['error'=>$e->getMessage()],422);}Security::audit($pdo,(int)$user['id'],'INDEXATION_STATE_IMPORT','seo_indexation',$source,null,['rows'=>$count]);ih_out(['imported'=>$count,'snapshot'=>$snapshot]);
}

ih_out(['error'=>'not_found'],404);
