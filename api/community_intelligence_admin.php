<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/Security.php';
require_once __DIR__.'/../app/lib/CommunityIntelligenceAutoPublisher.php';
require_once __DIR__.'/../app/lib/PublicReviewAdminService.php';
$config=require __DIR__.'/../app/config.php';
$pdo=Db::pdo();Security::start();$u=Security::requireRole(['reviewer','admin','super_admin']);
$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';$method=$_SERVER['REQUEST_METHOD']??'GET';
function ci_out($d,int $s=200){http_response_code($s);header('Content-Type: application/json; charset=utf-8');echo json_encode($d,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);exit;}
function ci_body(){return json_decode(file_get_contents('php://input'),true)?:[];}
function ci_pipeline_health(PDO $pdo):array{
  $health=['available'=>true,'analyzer_configured'=>(trim((string)getenv('OPENAI_API_KEY'))!==''&&trim((string)getenv('TECHSELECT_PRI_MODEL'))!==''),'active_permitted_connectors'=>0,'connectors_with_errors'=>0,'last_connector_run_at'=>null,'pending_analysis_items'=>0,'analyzed_items'=>0,'expired_unanalyzed_items'=>0,'products_with_intelligence'=>0,'published_products'=>0,'diagnostics'=>[]];
  try{
    $r=$pdo->query("SELECT SUM(status='active' AND policy_status='permitted') active_permitted,SUM(last_error IS NOT NULL AND last_error<>'') with_errors,MAX(last_run_at) last_run FROM public_review_connectors")->fetch(PDO::FETCH_ASSOC)?:[];
    $health['active_permitted_connectors']=(int)($r['active_permitted']??0);$health['connectors_with_errors']=(int)($r['with_errors']??0);$health['last_connector_run_at']=$r['last_run']??null;
    $r=$pdo->query("SELECT SUM(processing_status='pending_analysis') pending_analysis,SUM(processing_status='analyzed') analyzed,SUM(processing_status='expired_unanalyzed') expired_unanalyzed FROM public_review_collected_items")->fetch(PDO::FETCH_ASSOC)?:[];
    $health['pending_analysis_items']=(int)($r['pending_analysis']??0);$health['analyzed_items']=(int)($r['analyzed']??0);$health['expired_unanalyzed_items']=(int)($r['expired_unanalyzed']??0);
    $r=$pdo->query("SELECT COUNT(*) total,SUM(review_status='published' AND published_at IS NOT NULL) published FROM product_public_review_intelligence")->fetch(PDO::FETCH_ASSOC)?:[];
    $health['products_with_intelligence']=(int)($r['total']??0);$health['published_products']=(int)($r['published']??0);
    if(!$health['analyzer_configured'])$health['diagnostics'][]='PRI analyzer is not configured: OPENAI_API_KEY and TECHSELECT_PRI_MODEL are required.';
    if($health['active_permitted_connectors']===0)$health['diagnostics'][]='No active permitted public-review connectors are available.';
    if($health['last_connector_run_at']===null)$health['diagnostics'][]='No connector run is recorded yet; verify scripts/community_review_automation.php is scheduled.';
    if($health['connectors_with_errors']>0)$health['diagnostics'][]=$health['connectors_with_errors'].' connector(s) currently report collection errors.';
    if($health['pending_analysis_items']>0&&!$health['analyzer_configured'])$health['diagnostics'][]='Collected items are waiting for analysis but the PRI analyzer is not configured.';
    if($health['expired_unanalyzed_items']>0)$health['diagnostics'][]=$health['expired_unanalyzed_items'].' item(s) expired before analysis and should be investigated.';
  }catch(Throwable $e){$health['available']=false;$health['diagnostics'][]='Pipeline health unavailable: required public-review migrations may not be applied.';}
  return $health;
}
if($method!=='GET'){Security::sameOrigin($config);Security::requireCsrf();Security::rateLimit($pdo,'community-intelligence-admin',40,300);}

if($path==='/api/community-intelligence/auto-publish-settings'&&$method==='GET'){ci_out(['settings'=>CommunityIntelligenceAutoPublisher::settings($pdo),'csrf_token'=>Security::csrf()]);}
if($path==='/api/community-intelligence/auto-publish-settings'&&$method==='POST'){
  if(!in_array($u['role']??'', ['admin','super_admin'],true))ci_out(['error'=>'admin_required'],403);$before=CommunityIntelligenceAutoPublisher::settings($pdo);try{$settings=CommunityIntelligenceAutoPublisher::updateSettings($pdo,ci_body(),(int)$u['id']);}catch(Throwable $e){ci_out(['error'=>$e->getMessage()],422);}Security::audit($pdo,(int)$u['id'],'COMMUNITY_INTELLIGENCE_AUTO_POLICY_UPDATE','community_intelligence','1',$before,$settings);ci_out(['settings'=>$settings]);
}
if($path==='/api/community-intelligence'&&$method==='GET'){
  $sql="SELECT pri.product_id,p.name product,p.slug,pri.score_5,pri.positive_sentiment_pct,pri.confidence_score,pri.confidence_label,pri.sources_analyzed,pri.source_type_count,pri.insufficient_data,pri.strengths_json,pri.concerns_json,pri.themes_json,pri.source_mix_json,pri.date_range_start,pri.date_range_end,pri.methodology_version,pri.last_analyzed_at,COALESCE(pri.review_status,'draft') review_status,pri.review_notes,pri.reviewed_at,pri.published_at,pri.publication_mode,pri.auto_publish_checked_at,pri.auto_publish_hold_reason,pri.auto_publish_manual_hold_reason,pri.auto_publish_decision_json,(pri.auto_publish_candidate_json IS NOT NULL) has_held_candidate,(SELECT COUNT(*) FROM public_review_sources s WHERE s.product_id=pri.product_id AND s.access_policy='pending_review') pending_policy_count,(SELECT COUNT(*) FROM public_review_signals sg JOIN public_review_sources s2 ON s2.id=sg.source_id WHERE s2.product_id=pri.product_id AND sg.exclusion_reason IS NOT NULL) excluded_signal_count FROM product_public_review_intelligence pri JOIN products p ON p.id=pri.product_id ORDER BY pri.last_analyzed_at DESC";$rows=$pdo->query($sql)->fetchAll();foreach($rows as &$r){foreach(['strengths_json'=>'strengths','concerns_json'=>'concerns','themes_json'=>'themes','source_mix_json'=>'source_mix','auto_publish_decision_json'=>'auto_publish_decision'] as $col=>$out){$r[$out]=json_decode($r[$col]??'[]',true)?:[];unset($r[$col]);}}unset($r);ci_out(['items'=>$rows,'pipeline_health'=>ci_pipeline_health($pdo),'auto_publish_settings'=>CommunityIntelligenceAutoPublisher::settings($pdo),'csrf_token'=>Security::csrf()]);
}
if(preg_match('#^/api/community-intelligence/(\d+)$#',$path,$m)&&$method==='GET'){
  $pid=(int)$m[1];$st=$pdo->prepare("SELECT pri.*,p.name product,p.slug FROM product_public_review_intelligence pri JOIN products p ON p.id=pri.product_id WHERE pri.product_id=? LIMIT 1");$st->execute([$pid]);$item=$st->fetch();if(!$item)ci_out(['error'=>'not_found'],404);foreach(['strengths_json'=>'strengths','concerns_json'=>'concerns','themes_json'=>'themes','source_mix_json'=>'source_mix','auto_publish_decision_json'=>'auto_publish_decision','auto_publish_candidate_json'=>'held_candidate'] as $col=>$out){$item[$out]=json_decode($item[$col]??'[]',true)?:[];unset($item[$col]);}$st=$pdo->prepare("SELECT s.id,s.source_url,s.source_type,s.source_name,s.source_published_at,s.access_policy,s.access_policy_notes,sg.sentiment_label,sg.source_confidence,sg.source_quality,sg.independence_score,sg.specificity_score,sg.exclusion_reason,sg.retrieved_at FROM public_review_sources s LEFT JOIN public_review_signals sg ON sg.id=(SELECT MAX(x.id) FROM public_review_signals x WHERE x.source_id=s.id) WHERE s.product_id=? ORDER BY s.created_at DESC");$st->execute([$pid]);ci_out(['item'=>$item,'sources'=>$st->fetchAll(),'auto_publish_settings'=>CommunityIntelligenceAutoPublisher::settings($pdo),'csrf_token'=>Security::csrf()]);
}
if(preg_match('#^/api/community-intelligence/(\d+)/auto-hold$#',$path,$m)&&$method==='POST'){
  $pid=(int)$m[1];$b=ci_body();$reason=trim((string)($b['reason']??''));try{CommunityIntelligenceAutoPublisher::setManualHold($pdo,$pid,$reason);}catch(Throwable $e){ci_out(['error'=>$e->getMessage()],422);}Security::audit($pdo,(int)$u['id'],'COMMUNITY_INTELLIGENCE_AUTO_HOLD','product',(string)$pid,null,['reason'=>$reason]);ci_out(['updated'=>true,'manual_hold_reason'=>$reason?:null]);
}
if(preg_match('#^/api/community-intelligence/(\d+)/auto-evaluate$#',$path,$m)&&$method==='POST'){
  $pid=(int)$m[1];try{$decision=CommunityIntelligenceAutoPublisher::evaluateExisting($pdo,$pid);}catch(Throwable $e){ci_out(['error'=>$e->getMessage()],422);}Security::audit($pdo,(int)$u['id'],'COMMUNITY_INTELLIGENCE_AUTO_EVALUATE','product',(string)$pid,null,['decision'=>$decision['decision'],'failed_gates'=>$decision['failed_gates']]);ci_out(['decision'=>$decision]);
}
if(preg_match('#^/api/community-intelligence/(\d+)/review$#',$path,$m)&&$method==='POST'){
  $pid=(int)$m[1];$b=ci_body();$action=(string)($b['action']??'');$notes=trim((string)($b['notes']??''));if(!in_array($action,['approve','reject','request_more_evidence'],true)||mb_strlen($notes)>4000)ci_out(['error'=>'invalid_action'],422);$st=$pdo->prepare("SELECT * FROM product_public_review_intelligence WHERE product_id=? LIMIT 1");$st->execute([$pid]);$old=$st->fetch();if(!$old)ci_out(['error'=>'not_found'],404);$candidate=!empty($old['auto_publish_candidate_json'])?json_decode((string)$old['auto_publish_candidate_json'],true):null;$threshold=$candidate?:$old;$heldAgainstPublished=is_array($candidate)&&$candidate&&($old['review_status']??'')==='published'&&!empty($old['published_at']);
  if($action==='approve'){if(!empty($threshold['insufficient_data'])||(int)($threshold['sources_analyzed']??0)<3||(int)($threshold['source_type_count']??0)<2||(float)($threshold['confidence_score']??0)<0.65)ci_out(['error'=>'publication_threshold_not_met'],409);$status='published';$published='NOW()';$mode='manual';}
  elseif($heldAgainstPublished){$status='published';$published='published_at';$mode=$old['publication_mode']??null;}
  elseif($action==='reject'){$status='rejected';$published='NULL';$mode=null;}
  else{$status='needs_more_evidence';$published='NULL';$mode=null;}
  try{$pdo->beginTransaction();$snapshot=json_encode($old,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);$pdo->prepare("INSERT INTO community_intelligence_review_history(product_id,intelligence_id,action,notes,snapshot_json,reviewed_by_user_id) VALUES(?,?,?,?,?,?)")->execute([$pid,(int)($old['id']??0),$action,$notes!==''?$notes:null,$snapshot,(int)$u['id']]);if($action==='approve'&&$candidate)PublicReviewAdminService::publishHeldCandidate($pdo,$pid);$sql="UPDATE product_public_review_intelligence SET review_status=?,review_notes=?,reviewed_at=NOW(),reviewed_by_user_id=?,published_at={$published},publication_mode=?,auto_publish_hold_reason=NULL,auto_publish_candidate_json=NULL WHERE product_id=?";$pdo->prepare($sql)->execute([$status,$notes!==''?$notes:null,(int)$u['id'],$mode,$pid]);$pdo->commit();}catch(Throwable $e){if($pdo->inTransaction())$pdo->rollBack();ci_out(['error'=>$e->getMessage()],422);}
  Security::audit($pdo,(int)$u['id'],'COMMUNITY_INTELLIGENCE_REVIEW','product',(string)$pid,$old,['action'=>$action,'status'=>$status,'notes'=>$notes,'held_candidate_applied'=>(bool)($action==='approve'&&$candidate),'prior_publication_preserved'=>(bool)($heldAgainstPublished&&$action!=='approve')]);ci_out(['updated'=>true,'status'=>$status]);
}
ci_out(['error'=>'not_found'],404);
