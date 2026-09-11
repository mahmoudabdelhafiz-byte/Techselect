<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/Security.php';
require_once __DIR__.'/../app/lib/SearchConsoleAnalytics.php';
$config=require __DIR__.'/../app/config.php';$pdo=Db::pdo();Security::start();$user=Security::requireRole(['reviewer','admin','super_admin']);
$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';$method=$_SERVER['REQUEST_METHOD']??'GET';
function sc_out($d,int $s=200){http_response_code($s);header('Content-Type: application/json; charset=utf-8');echo json_encode($d,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);exit;}
function sc_body(){return json_decode(file_get_contents('php://input'),true)?:[];}
if($method!=='GET'){Security::sameOrigin($config);Security::requireCsrf();Security::rateLimit($pdo,'search-console-write',30,60);}
if($path==='/api/search-console'&&$method==='GET'){
  $to=(string)($_GET['to']??date('Y-m-d'));$days=max(1,min(365,(int)($_GET['days']??28)));$from=(string)($_GET['from']??date('Y-m-d',strtotime($to.' -'.($days-1).' days')));
  try{$d=SearchConsoleAnalytics::dashboard($pdo,$from,$to);$d['csrf_token']=Security::csrf();sc_out($d);}catch(Throwable $e){sc_out(['error'=>$e instanceof InvalidArgumentException?$e->getMessage():'dashboard_failed'],422);}
}
if($path==='/api/search-console/import'&&$method==='POST'){
  $b=sc_body();$rows=$b['rows']??[];if(!is_array($rows)||count($rows)>50000)sc_out(['error'=>'invalid_rows'],422);
  try{$r=SearchConsoleAnalytics::importRows($pdo,$rows,$b,(int)$user['id']);Security::audit($pdo,(int)$user['id'],'SEARCH_CONSOLE_IMPORT','search_console_import',(string)$r['import_id'],null,['source_label'=>$b['source_label']??null,'date_from'=>$b['date_from']??null,'date_to'=>$b['date_to']??null,'rows_imported'=>$r['rows_imported']]);sc_out($r,201);}catch(Throwable $e){sc_out(['error'=>$e instanceof InvalidArgumentException?$e->getMessage():'import_failed'],422);}
}
sc_out(['error'=>'not_found'],404);