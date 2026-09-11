<?php
require_once __DIR__.'/../app/lib/Db.php';require_once __DIR__.'/../app/lib/Security.php';require_once __DIR__.'/../app/lib/AiVisibilityBenchmark.php';
$config=require __DIR__.'/../app/config.php';$pdo=Db::pdo();Security::start();$u=Security::requireRole(['reviewer','admin','super_admin']);$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';$method=$_SERVER['REQUEST_METHOD']??'GET';
function av_out($d,int $s=200){http_response_code($s);header('Content-Type: application/json; charset=utf-8');echo json_encode($d,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);exit;}function av_body(){return json_decode(file_get_contents('php://input'),true)?:[];}
if($method!=='GET'){Security::sameOrigin($config);Security::requireCsrf();Security::rateLimit($pdo,'ai-visibility-write',30,60);}
if($path==='/api/ai-visibility/prompts'&&$method==='GET')av_out(['prompts'=>AiVisibilityBenchmark::prompts($pdo),'csrf_token'=>Security::csrf()]);
if($path==='/api/ai-visibility/runs'&&$method==='GET')av_out(['runs'=>AiVisibilityBenchmark::runs($pdo),'csrf_token'=>Security::csrf()]);
if($path==='/api/ai-visibility/dashboard'&&$method==='GET')av_out(AiVisibilityBenchmark::dashboard($pdo,$_GET)+['csrf_token'=>Security::csrf()]);
if($path==='/api/ai-visibility/import'&&$method==='POST'){try{$b=av_body();$res=AiVisibilityBenchmark::importRun($pdo,$b,(int)$u['id']);Security::audit($pdo,(int)$u['id'],'AI_VISIBILITY_RUN_IMPORT','ai_visibility_run',(string)$res['run_id'],null,['provider'=>$b['provider']??null,'observations'=>$res['observations']]);av_out($res,201);}catch(Throwable $e){av_out(['error'=>$e->getMessage()],422);}}
av_out(['error'=>'not_found'],404);
