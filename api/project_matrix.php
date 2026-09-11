<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/Security.php';
require_once __DIR__.'/../app/lib/Entitlements.php';
require_once __DIR__.'/../app/lib/ProjectDecisionMatrix.php';
$config=require __DIR__.'/../app/config.php';$pdo=Db::pdo();Security::start();$user=Security::user();Entitlements::requireFeature($pdo,$user,'basic_decision_matrix');$uid=(int)$user['id'];
$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';$method=$_SERVER['REQUEST_METHOD']??'GET';
function mx_out($d,int $s=200){http_response_code($s);header('Content-Type: application/json; charset=utf-8');echo json_encode($d,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);exit;}
function mx_body(){return json_decode(file_get_contents('php://input'),true)?:[];}
function mx_project(PDO $pdo,int $id,int $uid){$st=$pdo->prepare('SELECT * FROM selection_projects WHERE id=? AND user_id=? LIMIT 1');$st->execute([$id,$uid]);return $st->fetch()?:null;}
function mx_pro(PDO $pdo,array $u):bool{return Entitlements::has($pdo,$u,'weighted_decision_matrix');}

if(preg_match('#^/api/selection-projects/(\d+)/matrix$#',$path,$m)){
  $pid=(int)$m[1];$project=mx_project($pdo,$pid,$uid);if(!$project)mx_out(['error'=>'not_found'],404);
  if($method==='GET'){
    $run=$pdo->prepare('SELECT id,scoring_version,weights_json,input_snapshot,created_at FROM selection_project_matrix_runs WHERE project_id=? ORDER BY id DESC LIMIT 1');$run->execute([$pid]);$r=$run->fetch();
    $q=$pdo->prepare("SELECT s.*,p.name product_name,p.slug product_slug,v.name vendor_name FROM selection_project_shortlist s JOIN products p ON p.id=s.product_id LEFT JOIN vendors v ON v.id=p.vendor_id WHERE s.project_id=? ORDER BY s.mandatory_gap_count,s.project_fit_score DESC,p.name");$q->execute([$pid]);$items=$q->fetchAll();foreach($items as &$it){$it['score_breakdown']=json_decode((string)($it['score_breakdown_json']??'{}'),true);$it['rationale']=json_decode((string)($it['rationale_json']??'{}'),true);unset($it['score_breakdown_json'],$it['rationale_json']);}unset($it);if($r){$r['weights']=json_decode($r['weights_json'],true);$r['input_snapshot']=json_decode($r['input_snapshot'],true);unset($r['weights_json']);}mx_out(['project_id'=>$pid,'matrix_run'=>$r?:null,'shortlist'=>$items,'pro'=>mx_pro($pdo,$user)]);
  }
  if($method==='POST'){
    Security::sameOrigin($config);Security::requireCsrf();Security::rateLimit($pdo,'project-matrix-generate',12,300);$b=mx_body();$pro=mx_pro($pdo,$user);$requested=is_array($b['weights']??null)?$b['weights']:[];$weights=ProjectDecisionMatrix::normalizeWeights($requested,$pro);
    if(!$pro&&$requested&&$weights!==$requested){} // registered users always use approved defaults
    try{$matrix=ProjectDecisionMatrix::generate($pdo,$project,$weights);}catch(RuntimeException $e){mx_out(['error'=>$e->getMessage()],409);}
    $snapshot=['project_id'=>$pid,'project_version'=>(int)$project['version'],'category_id'=>$matrix['category_id'],'weights'=>$weights];
    $pdo->beginTransaction();$ins=$pdo->prepare('INSERT INTO selection_project_matrix_runs(project_id,user_id,scoring_version,weights_json,input_snapshot) VALUES(?,?,?,?,?)');$ins->execute([$pid,$uid,$matrix['scoring_version'],json_encode($weights),json_encode($snapshot)]);$runId=(int)$pdo->lastInsertId();
    $up=$pdo->prepare("INSERT INTO selection_project_shortlist(project_id,product_id,matrix_run_id,project_fit_score,baseline_evaluation_score,mandatory_gap_count,score_breakdown_json,rationale_json) VALUES(?,?,?,?,?,?,?,?) ON DUPLICATE KEY UPDATE matrix_run_id=VALUES(matrix_run_id),project_fit_score=VALUES(project_fit_score),baseline_evaluation_score=VALUES(baseline_evaluation_score),mandatory_gap_count=VALUES(mandatory_gap_count),score_breakdown_json=VALUES(score_breakdown_json),rationale_json=VALUES(rationale_json)");
    foreach($matrix['results'] as $r){$break=['dimensions'=>$r['dimensions'],'contributions'=>$r['contributions'],'weights'=>$weights];$rat=['tradeoffs'=>$r['tradeoffs'],'requirements'=>$r['requirements'],'partner_options'=>$r['partner_options'],'partner_note'=>$r['partner_note'],'baseline_evaluation_status'=>$r['baseline_evaluation_status']];$up->execute([$pid,$r['product']['id'],$runId,$r['project_fit_score'],$r['baseline_evaluation_score'],$r['mandatory_gap_count'],json_encode($break),json_encode($rat)]);}
    Security::audit($pdo,$uid,'PROJECT_MATRIX_GENERATE','selection_project',(string)$pid,null,['run_id'=>$runId,'scoring_version'=>$matrix['scoring_version'],'weights'=>$weights]);$pdo->commit();
    $sensitivity=null;if($pro&&!empty($b['sensitivity'])){$sensitivity=[];foreach($weights as $criterion=>$w){if($w<=0)continue;$alt=$weights;$alt[$criterion]=$w*1.2;$scenario=[];foreach($matrix['results'] as $r)$scenario[]=['product_id'=>$r['product']['id'],'name'=>$r['product']['name'],'score'=>ProjectDecisionMatrix::weightedOverall($r['dimensions'],$alt),'mandatory_gap_count'=>$r['mandatory_gap_count']];usort($scenario,fn($a,$b)=>$a['mandatory_gap_count']<=>$b['mandatory_gap_count'] ?: $b['score']<=>$a['score']);$sensitivity[$criterion]=array_slice($scenario,0,3);}}
    mx_out(['generated'=>true,'run_id'=>$runId,'matrix'=>$matrix,'sensitivity'=>$sensitivity,'weight_override_allowed'=>$pro],201);
  }
}
if(preg_match('#^/api/selection-projects/(\d+)/shortlist/(\d+)$#',$path,$m)&&$method==='PUT'){
  Security::sameOrigin($config);Security::requireCsrf();$pid=(int)$m[1];$productId=(int)$m[2];if(!mx_project($pdo,$pid,$uid))mx_out(['error'=>'not_found'],404);$state=(string)(mx_body()['state']??'');if(!in_array($state,ProjectDecisionMatrix::states(),true))mx_out(['error'=>'invalid_state'],422);$st=$pdo->prepare('UPDATE selection_project_shortlist SET shortlist_state=? WHERE project_id=? AND product_id=?');$st->execute([$state,$pid,$productId]);if(!$st->rowCount())mx_out(['error'=>'shortlist_item_not_found'],404);Security::audit($pdo,$uid,'PROJECT_SHORTLIST_STATE','selection_project',(string)$pid,null,['product_id'=>$productId,'state'=>$state]);mx_out(['updated'=>true,'state'=>$state]);
}
if(preg_match('#^/api/selection-projects/(\d+)/matrix-export$#',$path,$m)&&$method==='GET'){
  $pid=(int)$m[1];if(!mx_project($pdo,$pid,$uid))mx_out(['error'=>'not_found'],404);Entitlements::requireFeature($pdo,$user,'rich_exports');$q=$pdo->prepare("SELECT p.name,p.slug,s.shortlist_state,s.project_fit_score,s.baseline_evaluation_score,s.mandatory_gap_count,s.score_breakdown_json,s.rationale_json FROM selection_project_shortlist s JOIN products p ON p.id=s.product_id WHERE s.project_id=? ORDER BY s.mandatory_gap_count,s.project_fit_score DESC");$q->execute([$pid]);mx_out(['project_id'=>$pid,'export_type'=>'decision_matrix_json','generated_at'=>gmdate('c'),'items'=>$q->fetchAll()]);
}
mx_out(['error'=>'not_found'],404);
