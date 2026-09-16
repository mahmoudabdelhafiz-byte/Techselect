<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/Security.php';
require_once __DIR__.'/../app/lib/ProductCommunity.php';
$config=require __DIR__.'/../app/config.php';
$pdo=Db::pdo();Security::start();
$method=$_SERVER['REQUEST_METHOD']??'GET';
function pc_out(array $data,int $status=200):void{http_response_code($status);header('Content-Type: application/json; charset=utf-8');echo json_encode($data,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);exit;}
function pc_body():array{return json_decode(file_get_contents('php://input'),true)?:[];}
$slug=trim((string)($_GET['slug']??''));
if(!preg_match('/^[a-z0-9-]{1,180}$/',$slug))pc_out(['error'=>'invalid_product'],422);
$st=$pdo->prepare("SELECT id,name FROM products WHERE slug=? AND status='active' LIMIT 1");$st->execute([$slug]);$product=$st->fetch(PDO::FETCH_ASSOC);if(!$product)pc_out(['error'=>'product_not_found'],404);
$productId=(int)$product['id'];$user=Security::user();$userId=$user?(int)$user['id']:null;

if($method==='GET'){
    $sort=($_GET['sort']??'recent')==='helpful'?'helpful':'recent';
    try{pc_out(['product'=>['id'=>$productId,'name'=>$product['name'],'slug'=>$slug],'authenticated'=>(bool)$user,'sort'=>$sort,'posts'=>ProductCommunity::list($pdo,$productId,$userId,$sort)]);}catch(Throwable $e){pc_out(['error'=>'community_unavailable'],503);}
}

if($method!=='POST')pc_out(['error'=>'method_not_allowed'],405);
if(!$user)pc_out(['error'=>'authentication_required'],401);
Security::sameOrigin($config);Security::requireCsrf();Security::rateLimit($pdo,'product-community-write',30,300);
$ust=$pdo->prepare("SELECT id,status,email_verified_at FROM users WHERE id=? LIMIT 1");$ust->execute([$userId]);$dbu=$ust->fetch(PDO::FETCH_ASSOC);
if(!$dbu||$dbu['status']!=='active'||empty($dbu['email_verified_at']))pc_out(['error'=>'verified_email_required'],403);
$b=pc_body();$action=(string)($b['action']??'post');
try{
    if($action==='post'){
        Security::rateLimit($pdo,'product-community-post-'.$userId,8,3600);
        $parent=isset($b['parent_id'])&&$b['parent_id']!==null?(int)$b['parent_id']:null;
        $id=ProductCommunity::createPost($pdo,$productId,$userId,(string)($b['type']??'discussion'),(string)($b['body']??''),$parent);
        Security::audit($pdo,$userId,'PRODUCT_COMMUNITY_POST','product_community_post',(string)$id,null,['product_id'=>$productId,'parent_id'=>$parent]);
        pc_out(['created'=>true,'post_id'=>$id],201);
    }
    if($action==='helpful'){
        Security::rateLimit($pdo,'product-community-helpful-'.$userId,60,3600);
        $postId=(int)($b['post_id']??0);if($postId<1)throw new InvalidArgumentException('post_not_found');
        $result=ProductCommunity::toggleHelpful($pdo,$productId,$postId,$userId);
        Security::audit($pdo,$userId,$result['helpful']?'PRODUCT_COMMUNITY_HELPFUL':'PRODUCT_COMMUNITY_UNHELPFUL','product_community_post',(string)$postId,null,['product_id'=>$productId]);
        pc_out($result);
    }
    if($action==='report'){
        Security::rateLimit($pdo,'product-community-report-'.$userId,12,3600);
        $postId=(int)($b['post_id']??0);if($postId<1)throw new InvalidArgumentException('post_not_found');
        ProductCommunity::report($pdo,$productId,$postId,$userId,(string)($b['reason']??'other'),(string)($b['details']??''));
        Security::audit($pdo,$userId,'PRODUCT_COMMUNITY_REPORT','product_community_post',(string)$postId,null,['product_id'=>$productId,'reason'=>(string)($b['reason']??'other')]);
        pc_out(['reported'=>true]);
    }
    pc_out(['error'=>'invalid_action'],422);
}catch(InvalidArgumentException $e){pc_out(['error'=>$e->getMessage()],422);}catch(PDOException $e){pc_out(['error'=>'community_write_failed'],500);}catch(Throwable $e){pc_out(['error'=>'community_write_failed'],500);}
