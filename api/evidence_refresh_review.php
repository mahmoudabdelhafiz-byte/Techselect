<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/Security.php';
$config=require __DIR__.'/../app/config.php';
$pdo=Db::pdo();Security::start();$user=Security::requireRole(['admin','super_admin','data_editor']);
$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';$method=$_SERVER['REQUEST_METHOD']??'GET';
function er_out($d,int $s=200){http_response_code($s);header('Content-Type: application/json; charset=utf-8');echo json_encode($d,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);exit;}
function er_body(){return json_decode(file_get_contents('php://input'),true)?:[];}
function fp(?string $v):?string{return $v===null?null:bin2hex($v);}
if($path==='/api/evidence-refresh/candidates'&&$method==='GET'){
  $status=trim((string)($_GET['status']??'pending_review'));$allowed=['pending_review','no_material_change','rejected','needs_fact_extraction','all'];if(!in_array($status,$allowed,true))er_out(['error'=>'invalid_status'],422);
  $sql="SELECT c.id,c.status,c.detected_at,c.reviewed_at,c.review_notes,c.previous_fingerprint,c.current_fingerprint,c.evidence_source_id,es.source_url,es.source_title,es.source_type,es.checked_at,es.verification_status,p.id product_id,p.name product_name,p.slug product_slug,v.name vendor_name,u.full_name reviewer_name,(SELECT r.change_state FROM evidence_refresh_checks r WHERE r.evidence_source_id=c.evidence_source_id ORDER BY r.id DESC LIMIT 1) latest_refresh_state FROM evidence_change_candidates c JOIN evidence_sources es ON es.id=c.evidence_source_id JOIN products p ON p.id=es.product_id LEFT JOIN vendors v ON v.id=p.vendor_id LEFT JOIN users u ON u.id=c.reviewed_by_user_id";
  $params=[];if($status!=='all'){$sql.=' WHERE c.status=?';$params[]=$status;}$sql.=' ORDER BY c.detected_at DESC LIMIT 200';$st=$pdo->prepare($sql);$st->execute($params);$rows=[];foreach($st->fetchAll() as $r){$r['previous_fingerprint']=fp($r['previous_fingerprint']);$r['current_fingerprint']=fp($r['current_fingerprint']);$rows[]=$r;}er_out(['candidates'=>$rows,'csrf_token'=>Security::csrf()]);
}
if(preg_match('#^/api/evidence-refresh/candidates/(\d+)/disposition$#',$path,$m)&&$method==='PUT'){
  Security::sameOrigin($config);Security::rateLimit($pdo,'evidence-refresh-review',40,300);Security::requireCsrf();$id=(int)$m[1];$b=er_body();$next=(string)($b['status']??'');$notes=trim((string)($b['review_notes']??''));$allowed=['no_material_change','rejected','needs_fact_extraction'];if(!in_array($next,$allowed,true)||mb_strlen($notes)>4000)er_out(['error'=>'invalid_disposition'],422);
  $st=$pdo->prepare('SELECT id,status,review_notes FROM evidence_change_candidates WHERE id=? LIMIT 1');$st->execute([$id]);$before=$st->fetch();if(!$before)er_out(['error'=>'candidate_not_found'],404);if($before['status']!=='pending_review')er_out(['error'=>'candidate_already_dispositioned'],409);
  $pdo->prepare('UPDATE evidence_change_candidates SET status=?,reviewed_at=NOW(),reviewed_by_user_id=?,review_notes=? WHERE id=? AND status=\'pending_review\'')->execute([$next,(int)$user['id'],$notes!==''?$notes:null,$id]);Security::audit($pdo,(int)$user['id'],'EVIDENCE_REFRESH_DISPOSITION','evidence_change_candidate',(string)$id,$before,['status'=>$next,'review_notes'=>$notes]);er_out(['updated'=>true,'candidate_id'=>$id,'status'=>$next]);
}
er_out(['error'=>'not_found'],404);
