<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/Security.php';
$config=require __DIR__.'/../app/config.php';
$pdo=Db::pdo();Security::start();$u=Security::requireRole(['reviewer','admin','super_admin']);
$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';$method=$_SERVER['REQUEST_METHOD']??'GET';
function ci_out($d,int $s=200){http_response_code($s);header('Content-Type: application/json; charset=utf-8');echo json_encode($d,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);exit;}
function ci_body(){return json_decode(file_get_contents('php://input'),true)?:[];}
if($method!=='GET'){Security::sameOrigin($config);Security::requireCsrf();Security::rateLimit($pdo,'community-intelligence-admin',40,300);}

if($path==='/api/community-intelligence'&&$method==='GET'){
  $sql="SELECT pri.product_id,p.name product,p.slug,pri.score_5,pri.positive_sentiment_pct,pri.confidence_score,pri.confidence_label,pri.sources_analyzed,pri.source_type_count,pri.insufficient_data,pri.strengths_json,pri.concerns_json,pri.themes_json,pri.source_mix_json,pri.date_range_start,pri.date_range_end,pri.methodology_version,pri.last_analyzed_at,COALESCE(pri.review_status,'draft') review_status,pri.review_notes,pri.reviewed_at,pri.published_at,(SELECT COUNT(*) FROM public_review_sources s WHERE s.product_id=pri.product_id AND s.access_policy='pending_review') pending_policy_count,(SELECT COUNT(*) FROM public_review_signals sg JOIN public_review_sources s2 ON s2.id=sg.source_id WHERE s2.product_id=pri.product_id AND sg.exclusion_reason IS NOT NULL) excluded_signal_count FROM product_public_review_intelligence pri JOIN products p ON p.id=pri.product_id ORDER BY pri.last_analyzed_at DESC";
  $rows=$pdo->query($sql)->fetchAll();foreach($rows as &$r){foreach(['strengths_json'=>'strengths','concerns_json'=>'concerns','themes_json'=>'themes','source_mix_json'=>'source_mix'] as $col=>$out){$r[$out]=json_decode($r[$col]??'[]',true)?:[];unset($r[$col]);}}unset($r);ci_out(['items'=>$rows,'csrf_token'=>Security::csrf()]);
}
if(preg_match('#^/api/community-intelligence/(\d+)$#',$path,$m)&&$method==='GET'){
  $pid=(int)$m[1];$st=$pdo->prepare("SELECT pri.*,p.name product,p.slug FROM product_public_review_intelligence pri JOIN products p ON p.id=pri.product_id WHERE pri.product_id=? LIMIT 1");$st->execute([$pid]);$item=$st->fetch();if(!$item)ci_out(['error'=>'not_found'],404);
  foreach(['strengths_json'=>'strengths','concerns_json'=>'concerns','themes_json'=>'themes','source_mix_json'=>'source_mix'] as $col=>$out){$item[$out]=json_decode($item[$col]??'[]',true)?:[];unset($item[$col]);}
  $st=$pdo->prepare("SELECT s.id,s.source_url,s.source_type,s.source_name,s.source_published_at,s.access_policy,s.access_policy_notes,sg.sentiment_label,sg.source_confidence,sg.source_quality,sg.independence_score,sg.specificity_score,sg.exclusion_reason,sg.retrieved_at FROM public_review_sources s LEFT JOIN public_review_signals sg ON sg.id=(SELECT MAX(x.id) FROM public_review_signals x WHERE x.source_id=s.id) WHERE s.product_id=? ORDER BY s.created_at DESC");$st->execute([$pid]);ci_out(['item'=>$item,'sources'=>$st->fetchAll(),'csrf_token'=>Security::csrf()]);
}
if(preg_match('#^/api/community-intelligence/(\d+)/review$#',$path,$m)&&$method==='POST'){
  $pid=(int)$m[1];$b=ci_body();$action=(string)($b['action']??'');$notes=trim((string)($b['notes']??''));if(!in_array($action,['approve','reject','request_more_evidence'],true)||mb_strlen($notes)>4000)ci_out(['error'=>'invalid_action'],422);
  $st=$pdo->prepare("SELECT * FROM product_public_review_intelligence WHERE product_id=? LIMIT 1");$st->execute([$pid]);$old=$st->fetch();if(!$old)ci_out(['error'=>'not_found'],404);
  if($action==='approve'){
    if(!empty($old['insufficient_data']) || (int)$old['sources_analyzed']<3 || (int)$old['source_type_count']<2 || (float)$old['confidence_score']<0.65)ci_out(['error'=>'publication_threshold_not_met'],409);
    $status='published';$published='NOW()';
  } elseif($action==='reject'){$status='rejected';$published='NULL';} else {$status='needs_more_evidence';$published='NULL';}
  $pdo->beginTransaction();
  $snapshot=json_encode($old,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);
  $pdo->prepare("INSERT INTO community_intelligence_review_history(product_id,intelligence_id,action,notes,snapshot_json,reviewed_by_user_id) VALUES(?,?,?,?,?,?)")->execute([$pid,(int)($old['id']??0),$action,$notes!==''?$notes:null,$snapshot,(int)$u['id']]);
  $sql="UPDATE product_public_review_intelligence SET review_status=?,review_notes=?,reviewed_at=NOW(),reviewed_by_user_id=?,published_at={$published} WHERE product_id=?";$pdo->prepare($sql)->execute([$status,$notes!==''?$notes:null,(int)$u['id'],$pid]);$pdo->commit();
  Security::audit($pdo,(int)$u['id'],'COMMUNITY_INTELLIGENCE_REVIEW','product',(string)$pid,$old,['action'=>$action,'status'=>$status,'notes'=>$notes]);ci_out(['updated'=>true,'status'=>$status]);
}
ci_out(['error'=>'not_found'],404);
