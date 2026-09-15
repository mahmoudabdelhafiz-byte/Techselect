<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/Security.php';
require_once __DIR__.'/../app/lib/ProductFollows.php';
$config=require __DIR__.'/../app/config.php';
$pdo=Db::pdo();
Security::start();
$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';
$method=$_SERVER['REQUEST_METHOD']??'GET';

function pf_out($data,int $status=200): void {
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode($data,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);
    exit;
}

if(!preg_match('#^/api/product-follows/([a-z0-9-]+)$#',$path,$m)) pf_out(['error'=>'not_found'],404);
$product=ProductFollows::productBySlug($pdo,$m[1]);
if(!$product) pf_out(['error'=>'product_not_found'],404);
$user=Security::user();

if($method==='GET'){
    if(!$user) pf_out(['authenticated'=>false,'followed'=>false,'product'=>['slug'=>$product['slug'],'name'=>$product['name']]]);
    $state=ProductFollows::state($pdo,(int)$user['id'],(int)$product['id']);
    pf_out(['authenticated'=>true,'followed'=>$state['followed'],'product'=>['slug'=>$product['slug'],'name'=>$product['name']]]);
}

if(!$user) pf_out(['error'=>'authentication_required'],401);
Security::sameOrigin($config);
Security::rateLimit($pdo,'product-follow-write',30,300);
Security::requireCsrf();

if($method==='POST'){
    $state=ProductFollows::follow($pdo,(int)$user['id'],(int)$product['id']);
    Security::audit($pdo,(int)$user['id'],'PRODUCT_FOLLOW','product',(string)$product['id'],null,['slug'=>$product['slug']]);
    pf_out(['followed'=>$state['followed'],'product'=>['slug'=>$product['slug'],'name'=>$product['name']]],201);
}
if($method==='DELETE'){
    $state=ProductFollows::unfollow($pdo,(int)$user['id'],(int)$product['id']);
    Security::audit($pdo,(int)$user['id'],'PRODUCT_UNFOLLOW','product',(string)$product['id'],null,['slug'=>$product['slug']]);
    pf_out(['followed'=>$state['followed'],'product'=>['slug'=>$product['slug'],'name'=>$product['name']]]);
}
pf_out(['error'=>'method_not_allowed'],405);
