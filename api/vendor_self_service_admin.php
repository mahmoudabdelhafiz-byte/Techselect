<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/Security.php';
require_once __DIR__.'/../app/lib/VendorSelfService.php';
$config=require __DIR__.'/../app/config.php';$pdo=Db::pdo();Security::start();$reviewer=Security::requireRole(['reviewer','admin','super_admin']);$rid=(int)$reviewer['id'];$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';$method=$_SERVER['REQUEST_METHOD']??'GET';
function vsa_out($d,int $s=200){http_response_code($s);header('Content-Type: application/json; charset=utf-8');echo json_encode($d,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);exit;}
function vsa_body(){return json_decode(file_get_contents('php://input'),true)?:[];}
if($path==='/api/vendor-self-service-admin'&&$method==='GET'){
 $claims=$pdo->query("SELECT c.*,v.name vendor_name,u.email user_email FROM vendor_profile_claims c JOIN vendors v ON v.id=c.vendor_id JOIN users u ON u.id=c.user_id WHERE c.status IN ('pending_review','under_review') ORDER BY c.created_at ASC")->fetchAll(PDO::FETCH_ASSOC);
 $updates=$pdo->query("SELECT r.*,v.name vendor_name,p.name product_name,u.email user_email FROM vendor_update_requests r JOIN vendors v ON v.id=r.vendor_id LEFT JOIN products p ON p.id=r.product_id JOIN users u ON u.id=r.requested_by_user_id WHERE r.status IN ('pending_review','under_review') ORDER BY r.created_at ASC")->fetchAll(PDO::FETCH_ASSOC);vsa_out(['claims'=>$claims,'updates'=>$updates]);
}
if(preg_match('#^/api/vendor-self-service-admin/claims/(\d+)/(verify|reject)$#',$path,$m)&&$method==='POST'){
 Security::sameOrigin($config);Security::requireCsrf();$id=(int)$m[1];$action=$m[2];$st=$pdo->prepare('SELECT * FROM vendor_profile_claims WHERE id=?');$st->execute([$id]);$c=$st->fetch(PDO::FETCH_ASSOC);if(!$c)vsa_out(['error'=>'not_found'],404);$b=vsa_body();
 if($action==='verify'){VendorSelfService::approveClaim($pdo,$c,$rid);Security::audit($pdo,$rid,'VENDOR_PROFILE_CLAIM_VERIFY','vendor_profile_claim',(string)$id,$c,['status'=>'verified']);vsa_out(['verified'=>true]);}
 $reason=trim((string)($b['reason']??''));if($reason==='')vsa_out(['error'=>'reason_required'],422);$pdo->prepare("UPDATE vendor_profile_claims SET status='rejected',reviewer_notes=?,reviewed_by_user_id=?,reviewed_at=NOW() WHERE id=?")->execute([$reason,$rid,$id]);Security::audit($pdo,$rid,'VENDOR_PROFILE_CLAIM_REJECT','vendor_profile_claim',(string)$id,$c,['status'=>'rejected','reason'=>$reason]);vsa_out(['rejected'=>true]);
}
if(preg_match('#^/api/vendor-self-service-admin/updates/(\d+)/(approve|reject)$#',$path,$m)&&$method==='POST'){
 Security::sameOrigin($config);Security::requireCsrf();$id=(int)$m[1];$action=$m[2];$st=$pdo->prepare('SELECT * FROM vendor_update_requests WHERE id=?');$st->execute([$id]);$r=$st->fetch(PDO::FETCH_ASSOC);if(!$r)vsa_out(['error'=>'not_found'],404);$b=vsa_body();$note=trim((string)($b['note']??''));
 if($action==='reject'&&$note==='')vsa_out(['error'=>'reason_required'],422);
 $status=$action==='approve'?'approved':'rejected';$pdo->prepare('UPDATE vendor_update_requests SET status=?,reviewer_notes=?,reviewed_by_user_id=?,reviewed_at=NOW() WHERE id=?')->execute([$status,$note?:null,$rid,$id]);Security::audit($pdo,$rid,'VENDOR_UPDATE_'.strtoupper($action),'vendor_update_request',(string)$id,$r,['status'=>$status,'note'=>$note]);vsa_out([$status=>true,'application_note'=>'Approval records the reviewed fact request; applying it to canonical catalog fields remains an editorial/admin action.']);
}
vsa_out(['error'=>'not_found'],404);
