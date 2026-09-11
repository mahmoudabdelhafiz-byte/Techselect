<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/Security.php';
require_once __DIR__.'/../app/lib/AuthorityCampaigns.php';
$config=require __DIR__.'/../app/config.php';$pdo=Db::pdo();Security::start();$u=Security::requireRole(['reviewer','admin','super_admin']);
$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';$method=$_SERVER['REQUEST_METHOD']??'GET';
function ac_out($d,int $s=200){http_response_code($s);header('Content-Type: application/json; charset=utf-8');echo json_encode($d,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);exit;}
function ac_body(){return json_decode(file_get_contents('php://input'),true)?:[];}
if($method!=='GET'){Security::sameOrigin($config);Security::requireCsrf();Security::rateLimit($pdo,'authority-campaign-write',50,60);}
try{
 if($path==='/api/authority-campaigns'&&$method==='GET'){ac_out(['campaigns'=>AuthorityCampaigns::list($pdo)]);}
 if($path==='/api/authority-campaigns'&&$method==='POST'){$b=ac_body();$r=AuthorityCampaigns::create($pdo,$b,(int)$u['id']);Security::audit($pdo,(int)$u['id'],'AUTHORITY_CAMPAIGN_CREATE','authority_campaign',(string)$r['id'],null,['name'=>$r['name'],'asset_path'=>$r['asset_path']]);ac_out(['campaign'=>$r],201);}
 if(preg_match('#^/api/authority-campaigns/(\d+)$#',$path,$m)&&$method==='GET'){ac_out(['campaign'=>AuthorityCampaigns::get($pdo,(int)$m[1])]);}
 if(preg_match('#^/api/authority-campaigns/(\d+)/targets$#',$path,$m)&&$method==='POST'){$b=ac_body();$r=AuthorityCampaigns::addTarget($pdo,(int)$m[1],(int)($b['authority_source_id']??0),$b['angle']??null,$b['next_action_at']??null);Security::audit($pdo,(int)$u['id'],'AUTHORITY_CAMPAIGN_TARGET_ADD','authority_campaign',(string)$m[1],null,['authority_source_id'=>(int)($b['authority_source_id']??0)]);ac_out(['campaign'=>$r],201);}
 if(preg_match('#^/api/authority-campaign-targets/(\d+)/events$#',$path,$m)&&$method==='POST'){$b=ac_body();$r=AuthorityCampaigns::recordEvent($pdo,(int)$m[1],$b,(int)$u['id']);Security::audit($pdo,(int)$u['id'],'AUTHORITY_OUTREACH_EVENT','authority_campaign_target',(string)$m[1],null,['event_type'=>$b['event_type']??'note','channel'=>$b['channel']??null]);ac_out(['target'=>$r],201);}
}catch(Throwable $e){ac_out(['error'=>$e->getMessage()],$e instanceof InvalidArgumentException?422:400);}
ac_out(['error'=>'not_found'],404);
