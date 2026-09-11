<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/Security.php';
require_once __DIR__.'/../app/lib/VendorRelationshipClaim.php';
$config=require __DIR__.'/../app/config.php';$pdo=Db::pdo();Security::start();$user=Security::requireRole(['reviewer','admin','super_admin']);
$method=$_SERVER['REQUEST_METHOD']??'GET';$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';
function vrca_out($d,int $s=200){http_response_code($s);header('Content-Type: application/json; charset=utf-8');echo json_encode($d,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);exit;}
function vrca_claim(PDO $pdo,int $id){$st=$pdo->prepare("SELECT c.*,v.name vendor_name,p.name product_name FROM vendor_relationship_claims c JOIN vendors v ON v.id=c.vendor_id JOIN products p ON p.id=c.product_id WHERE c.id=? LIMIT 1");$st->execute([$id]);return $st->fetch(PDO::FETCH_ASSOC)?:null;}
if($method==='GET'){
  if(preg_match('#/api/vendor-relationship-claims-admin/(\d+)$#',$path,$m)){$c=vrca_claim($pdo,(int)$m[1]);if(!$c)vrca_out(['error'=>'not_found'],404);$h=$pdo->prepare("SELECT h.*,u.full_name actor_name FROM vendor_relationship_claim_history h LEFT JOIN users u ON u.id=h.actor_user_id WHERE h.claim_id=? ORDER BY h.id DESC");$h->execute([$c['id']]);$c['history']=$h->fetchAll(PDO::FETCH_ASSOC);vrca_out($c);}
  $status=trim((string)($_GET['status']??''));$q=trim((string)($_GET['q']??''));$where=[];$args=[];
  if($status!==''){$where[]='c.status=?';$args[]=$status;}if($q!==''){$where[]='(v.name LIKE ? OR p.name LIKE ? OR c.submitter_email LIKE ?)';$args[]='%'.$q.'%';$args[]='%'.$q.'%';$args[]='%'.$q.'%';}
  $sql="SELECT c.id,c.relationship_type,c.status,c.evidence_type,c.valid_until,c.created_at,v.name vendor_name,p.name product_name,c.submitter_email FROM vendor_relationship_claims c JOIN vendors v ON v.id=c.vendor_id JOIN products p ON p.id=c.product_id".($where?' WHERE '.implode(' AND ',$where):'')." ORDER BY FIELD(c.status,'pending','under_review','needs_information','verified','rejected','revoked'),c.created_at ASC LIMIT 200";
  $st=$pdo->prepare($sql);$st->execute($args);vrca_out(['items'=>$st->fetchAll(PDO::FETCH_ASSOC)]);
}
if($method==='POST'&&preg_match('#/api/vendor-relationship-claims-admin/(\d+)/action$#',$path,$m)){
  Security::sameOrigin($config);Security::requireCsrf();Security::rateLimit($pdo,'vendor-relationship-claim-review',30,300);$id=(int)$m[1];$c=vrca_claim($pdo,$id);if(!$c)vrca_out(['error'=>'not_found'],404);
  $b=json_decode(file_get_contents('php://input'),true)?:[];$action=(string)($b['action']??'');$note=trim((string)($b['note']??''));$from=$c['status'];$to=$from;$relationshipId=$c['relationship_id']? (int)$c['relationship_id']:null;
  if($action==='start_review'){$to='under_review';}
  elseif($action==='request_information'){if($note==='')vrca_out(['error'=>'note_required'],422);$to='needs_information';}
  elseif($action==='reject'){if($note==='')vrca_out(['error'=>'rejection_reason_required'],422);$to='rejected';}
  elseif($action==='approve'){$relationshipId=VendorRelationshipClaim::approve($pdo,$c,(int)$user['id'],$note);$to='verified';}
  elseif($action==='revoke'){
    if(!$relationshipId)vrca_out(['error'=>'relationship_not_created'],409);if($note==='')vrca_out(['error'=>'revocation_reason_required'],422);
    $pdo->beginTransaction();try{$pdo->prepare("UPDATE vendor_product_relationships SET status='revoked',verification_status='revoked' WHERE id=?")->execute([$relationshipId]);$pdo->prepare("UPDATE vendor_relationship_claims SET status='revoked',reviewer_notes=?,reviewed_by_user_id=?,reviewed_at=NOW() WHERE id=?")->execute([$note,$user['id'],$id]);$pdo->commit();$to='revoked';}catch(Throwable $e){if($pdo->inTransaction())$pdo->rollBack();throw $e;}
  } else vrca_out(['error'=>'invalid_action'],422);
  if($action!=='approve'&&$action!=='revoke')$pdo->prepare("UPDATE vendor_relationship_claims SET status=?,reviewer_notes=?,reviewed_by_user_id=?,reviewed_at=NOW() WHERE id=?")->execute([$to,$note?:null,$user['id'],$id]);
  $snap=vrca_claim($pdo,$id);$pdo->prepare("INSERT INTO vendor_relationship_claim_history(claim_id,actor_user_id,action,from_status,to_status,note,snapshot_json) VALUES(?,?,?,?,?,?,?)")->execute([$id,$user['id'],$action,$from,$to,$note?:null,json_encode($snap)]);
  Security::audit($pdo,(int)$user['id'],'VENDOR_RELATIONSHIP_CLAIM_'.strtoupper($action),'vendor_relationship_claim',(string)$id,['status'=>$from],['status'=>$to,'relationship_id'=>$relationshipId,'note'=>$note]);
  vrca_out(['updated'=>true,'status'=>$to,'relationship_id'=>$relationshipId]);
}
vrca_out(['error'=>'not_found'],404);
