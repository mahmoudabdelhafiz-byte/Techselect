<?php
require_once __DIR__.'/../app/lib/Db.php';require_once __DIR__.'/../app/lib/Security.php';require_once __DIR__.'/../app/lib/Entitlements.php';require_once __DIR__.'/../app/lib/DecisionPack.php';
$pdo=Db::pdo();Security::start();$u=Security::user();header('Content-Type: application/json; charset=utf-8');if(!$u){http_response_code(401);echo json_encode(['error'=>'authentication_required']);exit;}
$method=$_SERVER['REQUEST_METHOD']??'GET';$projectId=(int)($_GET['project_id']??0);
if(!$projectId){http_response_code(400);echo json_encode(['error'=>'project_id_required']);exit;}
if($method==='GET'){
  $preview=!Entitlements::has($pdo,$u,'decision_pack');
  $pack=DecisionPack::build($pdo,$projectId,(int)$u['id']);
  if($preview){$pack['preview']=true;$pack['sections']=array_intersect_key($pack['sections'],array_flip(['executive_summary','business_need','requirements','decision_matrix','recommendation','provenance']));}
  echo json_encode(['decision_pack'=>$pack],JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);exit;
}
Security::sameOrigin(require __DIR__.'/../app/config.php');Security::requireCsrf();Security::rateLimit($pdo,'decision_pack',20,60);Entitlements::requireFeature($pdo,$u,'decision_pack');
$input=json_decode(file_get_contents('php://input'),true)?:[];$narrative=is_array($input['narrative']??null)?$input['narrative']:[];$pack=DecisionPack::build($pdo,$projectId,(int)$u['id'],$narrative);
$st=$pdo->prepare("INSERT INTO decision_packs(user_id,selection_project_id,title,status,narrative_json,snapshot_json,methodology_version,generated_at) VALUES(?,?,?,?,?,?,?,NOW()) ON DUPLICATE KEY UPDATE title=VALUES(title),status='draft',narrative_json=VALUES(narrative_json),snapshot_json=VALUES(snapshot_json),methodology_version=VALUES(methodology_version),generated_at=NOW()");
$title=trim((string)($input['title']??''))?:'Software Decision Pack';$st->execute([(int)$u['id'],$projectId,$title,'draft',json_encode($narrative),json_encode($pack),DecisionPack::VERSION]);
Security::audit($pdo,(int)$u['id'],'generate','decision_pack',(string)$projectId,null,['version'=>DecisionPack::VERSION]);echo json_encode(['ok'=>true,'decision_pack'=>$pack],JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);
