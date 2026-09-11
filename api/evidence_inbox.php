<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/Security.php';
require_once __DIR__.'/../app/lib/EvidenceImpact.php';
$config=require __DIR__.'/../app/config.php';
$pdo=Db::pdo();Security::start();$user=Security::requireRole(['reviewer','admin','super_admin']);
$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';$method=$_SERVER['REQUEST_METHOD']??'GET';
function ei_out($d,int $s=200){http_response_code($s);header('Content-Type: application/json; charset=utf-8');echo json_encode($d,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);exit;}
function ei_body(){return json_decode(file_get_contents('php://input'),true)?:[];}

if($method!=='GET'){Security::sameOrigin($config);Security::requireCsrf();Security::rateLimit($pdo,'evidence-inbox-write',60,60);}

if($path==='/api/evidence-inbox'&&$method==='GET'){
  $status=trim((string)($_GET['status']??'all'));$allowed=['all','unverified','outdated','broken','disputed','superseded','placeholder','verified','stale','high_impact'];if(!in_array($status,$allowed,true))ei_out(['error'=>'invalid_status'],422);
  $sql="SELECT e.id,e.product_id,p.name product_name,p.slug product_slug,e.source_title,e.source_url,e.source_type,e.verification_status,e.confidence,e.checked_at,e.notes,e.publisher_name,e.vendor_owned FROM evidence_sources e JOIN products p ON p.id=e.product_id";
  $params=[];
  if(in_array($status,['unverified','outdated','broken','disputed','superseded','placeholder','verified'],true)){$sql.=' WHERE e.verification_status=?';$params[]=$status;}
  elseif($status==='stale'){$sql.=' WHERE e.checked_at IS NULL OR e.checked_at < DATE_SUB(NOW(), INTERVAL 180 DAY)';}
  $sql.=' ORDER BY CASE e.verification_status WHEN \'broken\' THEN 1 WHEN \'disputed\' THEN 2 WHEN \'outdated\' THEN 3 WHEN \'unverified\' THEN 4 WHEN \'placeholder\' THEN 5 WHEN \'superseded\' THEN 6 ELSE 7 END,e.checked_at ASC,e.id DESC LIMIT 250';
  $st=$pdo->prepare($sql);$st->execute($params);$rows=[];
  foreach($st->fetchAll(PDO::FETCH_ASSOC) as $r){$impact=EvidenceImpact::forEvidence($pdo,(int)$r['id']);$stale=EvidenceImpact::staleState($r['checked_at']??null);$r['impact']=$impact;$r['stale']=$stale;if($status==='high_impact'&&!($impact['high_impact']??false))continue;$rows[]=$r;}
  ei_out(['evidence'=>$rows,'csrf_token'=>Security::csrf(),'stale_threshold_days'=>180]);
}

if(preg_match('#^/api/evidence-inbox/(\d+)$#',$path,$m)&&$method==='GET'){
  $impact=EvidenceImpact::forEvidence($pdo,(int)$m[1]);if(!$impact)ei_out(['error'=>'not_found'],404);ei_out(['impact'=>$impact,'csrf_token'=>Security::csrf()]);
}

if(preg_match('#^/api/evidence-inbox/(\d+)$#',$path,$m)&&$method==='PATCH'){
  $id=(int)$m[1];$st=$pdo->prepare('SELECT * FROM evidence_sources WHERE id=? LIMIT 1');$st->execute([$id]);$old=$st->fetch(PDO::FETCH_ASSOC);if(!$old)ei_out(['error'=>'not_found'],404);
  $impact=EvidenceImpact::forEvidence($pdo,$id);$b=ei_body();$next=(string)($b['verification_status']??$old['verification_status']);
  $allowed=['verified','unverified','outdated','broken','disputed','superseded','placeholder'];if(!in_array($next,$allowed,true))ei_out(['error'=>'invalid_evidence_status'],422);
  $confidence=(string)($b['confidence']??$old['confidence']);if(!in_array($confidence,['low','medium','high'],true))ei_out(['error'=>'invalid_confidence'],422);
  $notes=array_key_exists('notes',$b)?trim((string)$b['notes']):($old['notes']??null);if($notes!==null&&mb_strlen($notes)>5000)ei_out(['error'=>'notes_too_long'],422);
  $material=in_array($next,['broken','disputed','outdated','superseded'],true)&&($impact['material_risk']??false);
  if($material&&!filter_var($b['confirm_material_impact']??false,FILTER_VALIDATE_BOOLEAN))ei_out(['error'=>'material_impact_confirmation_required','impact'=>$impact],409);
  $pdo->prepare('UPDATE evidence_sources SET verification_status=?,confidence=?,notes=?,checked_at=NOW() WHERE id=?')->execute([$next,$confidence,$notes,$id]);$st->execute([$id]);$new=$st->fetch(PDO::FETCH_ASSOC);
  Security::audit($pdo,(int)$user['id'],'EVIDENCE_INBOX_UPDATE','evidence',(string)$id,$old,['after'=>$new,'impact_at_change'=>$impact,'material_impact_confirmed'=>$material]);
  ei_out(['evidence'=>$new,'impact'=>$impact,'material_impact'=>$material]);
}

ei_out(['error'=>'not_found'],404);
