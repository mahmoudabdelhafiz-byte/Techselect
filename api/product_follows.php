<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/Security.php';
require_once __DIR__.'/../app/lib/ProductFollows.php';
$config=require __DIR__.'/../app/config.php';$pdo=Db::pdo();Security::start();$method=$_SERVER['REQUEST_METHOD']??'GET';
function pf_out($data,int $status=200):void{http_response_code($status);header('Content-Type: application/json; charset=utf-8');echo json_encode($data,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);exit;}
function pf_body():array{return json_decode(file_get_contents('php://input'),true)?:[];}
$slug=strtolower(trim((string)($_GET['slug']??'')));if(!preg_match('/^[a-z0-9-]+$/',$slug))pf_out(['error'=>'not_found'],404);
$product=ProductFollows::productBySlug($pdo,$slug);if(!$product)pf_out(['error'=>'product_not_found'],404);$user=Security::user();
if($method==='GET'){
    if(!$user)pf_out(['authenticated'=>false,'followed'=>false,'community_notifications'=>false,'product'=>['slug'=>$product['slug'],'name'=>$product['name']]]);
    Security::csrf();$state=ProductFollows::state($pdo,(int)$user['id'],(int)$product['id']);
    pf_out(['authenticated'=>true,'followed'=>$state['followed'],'community_notifications'=>$state['community_notifications'],'product'=>['slug'=>$product['slug'],'name'=>$product['name']]]);
}
if(!$user)pf_out(['error'=>'authentication_required'],401);Security::sameOrigin($config);Security::rateLimit($pdo,'product-follow-write',30,300);Security::requireCsrf();
if($method==='POST'){$state=ProductFollows::follow($pdo,(int)$user['id'],(int)$product['id']);Security::audit($pdo,(int)$user['id'],'PRODUCT_FOLLOW','product',(string)$product['id'],null,['slug'=>$product['slug']]);pf_out(['followed'=>$state['followed'],'community_notifications'=>$state['community_notifications']],201);}
if($method==='PATCH'){
    $b=pf_body();if(!array_key_exists('community_notifications',$b))pf_out(['error'=>'invalid_preference'],422);
    try{$state=ProductFollows::setCommunityNotifications($pdo,(int)$user['id'],(int)$product['id'],(bool)$b['community_notifications']);}
    catch(LogicException $e){pf_out(['error'=>$e->getMessage()],409);}
    Security::audit($pdo,(int)$user['id'],'PRODUCT_FOLLOW_COMMUNITY_NOTIFICATIONS','product',(string)$product['id'],null,['slug'=>$product['slug'],'enabled'=>$state['community_notifications']]);
    pf_out(['followed'=>$state['followed'],'community_notifications'=>$state['community_notifications']]);
}
if($method==='DELETE'){$state=ProductFollows::unfollow($pdo,(int)$user['id'],(int)$product['id']);Security::audit($pdo,(int)$user['id'],'PRODUCT_UNFOLLOW','product',(string)$product['id'],null,['slug'=>$product['slug']]);pf_out(['followed'=>$state['followed'],'community_notifications'=>$state['community_notifications']]);}
pf_out(['error'=>'method_not_allowed'],405);
