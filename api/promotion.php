<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/Security.php';
require_once __DIR__.'/../app/lib/CardIqPromotion.php';
$config=require __DIR__.'/../app/config.php';
$pdo=Db::pdo();
Security::start();
Security::sameOrigin($config);
$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';
$method=$_SERVER['REQUEST_METHOD']??'GET';
function promo_out($d,int $s=200){http_response_code($s);header('Content-Type: application/json; charset=utf-8');echo json_encode($d,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);exit;}
if(!preg_match('#^/api/consultations/([a-f0-9]{48})/promotion(?:/(impression|click))?$#',$path,$m))promo_out(['error'=>'not_found'],404);
$st=$pdo->prepare("SELECT c.* FROM consultations c WHERE c.public_token=? LIMIT 1");$st->execute([$m[1]]);$c=$st->fetch();if(!$c)promo_out(['error'=>'not_found'],404);
if(!empty($c['user_id'])){$u=Security::user();if(!$u || (int)$u['id']!==(int)$c['user_id'])promo_out(['error'=>'forbidden'],403);}
if($method==='GET' && empty($m[2])){Security::rateLimit($pdo,'promotion-evaluate',30,60);promo_out(['promotion'=>CardIqPromotion::evaluate($pdo,$c)]);}
if($method==='POST' && !empty($m[2])){Security::rateLimit($pdo,'promotion-event',30,60);if(Security::user())Security::requireCsrf();$b=json_decode(file_get_contents('php://input'),true)?:[];CardIqPromotion::recordEvent($pdo,$c,$m[2],(string)($b['trigger_group']??'unknown'),(int)($b['relevance_score']??0));promo_out(['recorded'=>true]);}
promo_out(['error'=>'method_not_allowed'],405);
