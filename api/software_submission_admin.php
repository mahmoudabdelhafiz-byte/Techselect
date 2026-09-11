<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/Security.php';
require_once __DIR__.'/../app/lib/SoftwareSubmission.php';
$config=require __DIR__.'/../app/config.php';$pdo=Db::pdo();Security::start();$user=Security::requireRole(['reviewer','admin','super_admin']);$uid=(int)$user['id'];$method=$_SERVER['REQUEST_METHOD']??'GET';$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';
function sa_out($d,int $s=200){http_response_code($s);header('Content-Type: application/json; charset=utf-8');echo json_encode($d,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);exit;}
function sa_body(){return json_decode(file_get_contents('php://input'),true)?:[];}
function sa_get(PDO $pdo,int $id){$q=$pdo->prepare('SELECT s.*,c.name category_name,p.name existing_product_name,p.slug existing_product_slug,cp.name created_product_name,cp.slug created_product_slug FROM software_submissions s LEFT JOIN categories c ON c.id=s.category_id LEFT JOIN products p ON p.id=s.existing_product_id LEFT JOIN products cp ON cp.id=s.created_product_id WHERE s.id=?');$q->execute([$id]);return $q->fetch(PDO::FETCH_ASSOC)?:null;}

if($method==='GET' && $path==='/api/software-submission-admin'){
  $status=trim((string)($_GET['status']??''));$q=trim((string)($_GET['q']??''));$sql='SELECT s.id,s.submission_type,s.product_name,s.vendor_name,s.submitter_email,s.status,s.duplicate_reason,s.created_at,c.name category_name,p.name existing_product_name FROM software_submissions s LEFT JOIN categories c ON c.id=s.category_id LEFT JOIN products p ON p.id=s.existing_product_id WHERE 1=1';$args=[];
  if($status!==''){$sql.=' AND s.status=?';$args[]=$status;}if($q!==''){$sql.=' AND (s.product_name LIKE ? OR s.vendor_name LIKE ? OR s.submitter_email LIKE ?)';$like='%'.$q.'%';array_push($args,$like,$like,$like);}$sql.=' ORDER BY s.created_at DESC LIMIT 250';$st=$pdo->prepare($sql);$st->execute($args);sa_out(['items'=>$st->fetchAll(PDO::FETCH_ASSOC)]);
}
if($method==='GET' && preg_match('#^/api/software-submission-admin/(\d+)$#',$path,$m)){
  $row=sa_get($pdo,(int)$m[1]);if(!$row)sa_out(['error'=>'not_found'],404);$h=$pdo->prepare('SELECT r.*,u.full_name reviewer_name,p.name linked_product_name FROM software_submission_reviews r LEFT JOIN users u ON u.id=r.reviewer_user_id LEFT JOIN products p ON p.id=r.linked_product_id WHERE r.submission_id=? ORDER BY r.created_at DESC');$h->execute([(int)$m[1]]);sa_out(['submission'=>$row,'history'=>$h->fetchAll(PDO::FETCH_ASSOC)]);
}
if($method==='POST' && preg_match('#^/api/software-submission-admin/(\d+)/action$#',$path,$m)){
  Security::sameOrigin($config);Security::requireCsrf();Security::rateLimit($pdo,'submission-admin',60,60);$id=(int)$m[1];$row=sa_get($pdo,$id);if(!$row)sa_out(['error'=>'not_found'],404);$b=sa_body();$action=(string)($b['action']??'');$notes=trim((string)($b['notes']??''));$allowed=['start_review','request_information','approve_for_draft','reject','link_existing'];if(!in_array($action,$allowed,true))sa_out(['error'=>'invalid_action'],422);
  $to=match($action){'start_review'=>'under_review','request_information'=>'needs_information','approve_for_draft'=>'approved_for_draft','reject'=>'rejected','link_existing'=>'approved_for_draft'};
  $linked=null;if($action==='link_existing'){$linked=(int)($b['product_id']??0);if($linked<1)sa_out(['error'=>'product_id_required'],422);$chk=$pdo->prepare('SELECT id FROM products WHERE id=? LIMIT 1');$chk->execute([$linked]);if(!$chk->fetchColumn())sa_out(['error'=>'product_not_found'],404);}
  if($action==='reject' && $notes==='')sa_out(['error'=>'rejection_reason_required'],422);
  $pdo->beginTransaction();
  $pdo->prepare('UPDATE software_submissions SET status=?,reviewer_notes=?,reviewed_by_user_id=?,reviewed_at=NOW(),existing_product_id=COALESCE(?,existing_product_id) WHERE id=?')->execute([$to,$notes?:null,$uid,$linked?:null,$id]);
  $updated=sa_get($pdo,$id);$created=null;if($action==='approve_for_draft' && empty($updated['existing_product_id'])){$created=SoftwareSubmission::createDraftProduct($pdo,$updated);$updated=sa_get($pdo,$id);} 
  $snap=['submission_type'=>$updated['submission_type'],'product_name'=>$updated['product_name'],'vendor_name'=>$updated['vendor_name'],'existing_product_id'=>$updated['existing_product_id'],'created_product_id'=>$updated['created_product_id'],'duplicate_reason'=>$updated['duplicate_reason']];
  $pdo->prepare('INSERT INTO software_submission_reviews(submission_id,reviewer_user_id,action,from_status,to_status,notes,linked_product_id,snapshot_json) VALUES(?,?,?,?,?,?,?,?)')->execute([$id,$uid,$action,$row['status'],$to,$notes?:null,$linked?:($updated['created_product_id']?:null),json_encode($snap)]);
  Security::audit($pdo,$uid,'SOFTWARE_SUBMISSION_'.strtoupper($action),'software_submission',(string)$id,['status'=>$row['status']],['status'=>$to,'linked_product_id'=>$linked,'created_product_id'=>$created]);$pdo->commit();sa_out(['updated'=>true,'submission'=>$updated],200);
}
sa_out(['error'=>'not_found'],404);
