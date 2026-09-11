<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/Security.php';
require_once __DIR__.'/../app/lib/VendorSelfService.php';
$config=require __DIR__.'/../app/config.php';$pdo=Db::pdo();Security::start();$user=Security::user();$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';$method=$_SERVER['REQUEST_METHOD']??'GET';
function vs_out($d,int $s=200){http_response_code($s);header('Content-Type: application/json; charset=utf-8');echo json_encode($d,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);exit;}
function vs_body(){return json_decode(file_get_contents('php://input'),true)?:[];}
if(!$user)vs_out(['error'=>'authentication_required'],401);$uid=(int)$user['id'];
if($path==='/api/vendor-self-service'&&$method==='GET'){
  $members=VendorSelfService::memberships($pdo,$uid);$claims=$pdo->prepare('SELECT c.*,v.name vendor_name,v.slug vendor_slug FROM vendor_profile_claims c JOIN vendors v ON v.id=c.vendor_id WHERE c.user_id=? ORDER BY c.created_at DESC');$claims->execute([$uid]);$updates=$pdo->prepare('SELECT r.*,v.name vendor_name,p.name product_name FROM vendor_update_requests r JOIN vendors v ON v.id=r.vendor_id LEFT JOIN products p ON p.id=r.product_id WHERE r.requested_by_user_id=? ORDER BY r.created_at DESC LIMIT 100');$updates->execute([$uid]);vs_out(['memberships'=>$members,'claims'=>$claims->fetchAll(PDO::FETCH_ASSOC),'updates'=>$updates->fetchAll(PDO::FETCH_ASSOC)]);
}
if($path==='/api/vendor-self-service/claim'&&$method==='POST'){
  Security::sameOrigin($config);Security::requireCsrf();Security::rateLimit($pdo,'vendor-profile-claim',5,300);try{$id=VendorSelfService::claim($pdo,$uid,vs_body());Security::audit($pdo,$uid,'VENDOR_PROFILE_CLAIM','vendor_profile_claim',(string)$id,null,['status'=>'pending_review']);vs_out(['created'=>true,'claim_id'=>$id],201);}catch(Throwable $e){vs_out(['error'=>$e->getMessage()],422);}
}
if($path==='/api/vendor-self-service/update'&&$method==='POST'){
  Security::sameOrigin($config);Security::requireCsrf();Security::rateLimit($pdo,'vendor-update-request',15,300);try{$id=VendorSelfService::requestUpdate($pdo,$uid,vs_body());Security::audit($pdo,$uid,'VENDOR_UPDATE_SUBMIT','vendor_update_request',(string)$id,null,['status'=>'pending_review']);vs_out(['created'=>true,'request_id'=>$id],201);}catch(Throwable $e){vs_out(['error'=>$e->getMessage()],422);}
}
vs_out(['error'=>'not_found'],404);
