<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/Scoring.php';
require_once __DIR__.'/../app/lib/AiExtraction.php';
$config=require __DIR__.'/../app/config.php';
$pdo=Db::pdo();
$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';
$method=$_SERVER['REQUEST_METHOD']??'GET';
function json_out($data,int $status=200){http_response_code($status);header('Content-Type: application/json; charset=utf-8');echo json_encode($data,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);exit;}
function body_json(){return json_decode(file_get_contents('php://input'),true)?:[];}
function token(){return bin2hex(random_bytes(24));}
function h($v){return htmlspecialchars((string)$v,ENT_QUOTES,'UTF-8');}
function consultation(PDO $pdo,string $public){$st=$pdo->prepare("SELECT * FROM consultations WHERE public_token=?");$st->execute([$public]);return $st->fetch()?:null;}

if($path==='/health') json_out(['status'=>'ok','stack'=>'php-mariadb']);
if($path==='/robots.txt'){
  header('Content-Type: text/plain; charset=utf-8');
  echo "User-agent: *\nAllow: /\nDisallow: /admin/\nDisallow: /account/\nDisallow: /api/\nDisallow: /advice/\nDisallow: /login\nDisallow: /register\nSitemap: {$config['site_url']}/sitemap.xml\n";exit;
}
if($path==='/sitemap.xml'){
  header('Content-Type: application/xml; charset=utf-8');
  $urls=[['/','weekly','1.0'],['/software','daily','0.9'],['/methodology','monthly','0.6']];
  foreach($pdo->query("SELECT slug,updated_at FROM products WHERE status='active'") as $r)$urls[]=['/software/'.$r['slug'],'weekly','0.8',$r['updated_at']];
  foreach($pdo->query("SELECT DISTINCT c.slug FROM capabilities c WHERE c.is_active=1") as $r)$urls[]=['/capabilities/'.$r['slug'],'weekly','0.7'];
  echo '<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">';
  foreach($urls as $u){echo '<url><loc>'.h($config['site_url'].$u[0]).'</loc><changefreq>'.$u[1].'</changefreq><priority>'.$u[2].'</priority>'.(!empty($u[3])?'<lastmod>'.date('c',strtotime($u[3])).'</lastmod>':'').'</url>';}
  echo '</urlset>';exit;
}

if($path==='/api/software' && $method==='GET'){
  $q=$pdo->query("SELECT p.id,p.name,p.slug,p.short_description,p.status,v.name vendor,c.name category FROM products p LEFT JOIN vendors v ON v.id=p.vendor_id LEFT JOIN categories c ON c.id=p.category_id WHERE p.status='active' ORDER BY p.name");
  json_out(['products'=>$q->fetchAll()]);
}
if(preg_match('#^/api/software/([a-z0-9-]+)$#',$path,$m) && $method==='GET'){
  $st=$pdo->prepare("SELECT p.*,v.name vendor,c.name category FROM products p LEFT JOIN vendors v ON v.id=p.vendor_id LEFT JOIN categories c ON c.id=p.category_id WHERE p.slug=? AND p.status='active'");$st->execute([$m[1]]);$p=$st->fetch();if(!$p)json_out(['error'=>'not_found'],404);
  $st=$pdo->prepare("SELECT cap.name,cap.slug,mo.name AS module,pc.support_status,pc.limitations,pc.confidence_score,pc.last_verified_at FROM product_capabilities pc JOIN capabilities cap ON cap.id=pc.capability_id JOIN modules mo ON mo.id=cap.module_id WHERE pc.product_id=? AND pc.edition_id IS NULL ORDER BY mo.name,cap.name");$st->execute([$p['id']]);$p['capabilities']=$st->fetchAll();
  $st=$pdo->prepare("SELECT source_title,source_url,source_type,verification_status,confidence,checked_at FROM evidence_sources WHERE product_id=? ORDER BY checked_at DESC");$st->execute([$p['id']]);$p['evidence']=$st->fetchAll();json_out(['product'=>$p]);
}
if(preg_match('#^/api/capabilities/([a-z0-9-]+)$#',$path,$m) && $method==='GET'){
  $st=$pdo->prepare("SELECT c.id,c.name,c.slug,c.description,m.name module,cat.name category FROM capabilities c JOIN modules m ON m.id=c.module_id JOIN categories cat ON cat.id=m.category_id WHERE c.slug=? AND c.is_active=1 LIMIT 1");$st->execute([$m[1]]);$c=$st->fetch();if(!$c)json_out(['error'=>'not_found'],404);
  $st=$pdo->prepare("SELECT p.name,p.slug,pc.support_status,pc.confidence_score,pc.limitations FROM product_capabilities pc JOIN products p ON p.id=pc.product_id WHERE pc.capability_id=? AND pc.edition_id IS NULL AND p.status='active' ORDER BY pc.confidence_score DESC,p.name");$st->execute([$c['id']]);$c['products']=$st->fetchAll();json_out(['capability'=>$c]);
}
if(preg_match('#^/api/compare/([a-z0-9-]+)-vs-([a-z0-9-]+)$#',$path,$m) && $method==='GET'){
  $slugs=[$m[1],$m[2]];$canonical=$slugs;sort($canonical,SORT_STRING);$canonical=implode('-vs-',$canonical);
  $in=$pdo->prepare("SELECT id,name,slug FROM products WHERE slug IN (?,?) AND status='active'");$in->execute($slugs);$products=$in->fetchAll();if(count($products)!==2)json_out(['error'=>'not_found'],404);
  $ids=array_column($products,'id');$st=$pdo->prepare("SELECT pc.product_id,c.name,c.slug,m.name module,pc.support_status,pc.confidence_score FROM product_capabilities pc JOIN capabilities c ON c.id=pc.capability_id JOIN modules m ON m.id=c.module_id WHERE pc.product_id IN (?,?) AND pc.edition_id IS NULL ORDER BY m.name,c.name");$st->execute($ids);json_out(['canonical'=>$canonical,'products'=>$products,'facts'=>$st->fetchAll()]);
}

if($path==='/api/consultations' && $method==='POST'){
  $b=body_json();$problem=trim($b['business_problem']??'');if(strlen($problem)<5)json_out(['error'=>'business_problem_required'],422);
  $visitor=token();$hash=hash('sha256',$visitor,true);$pdo->beginTransaction();
  $st=$pdo->prepare("INSERT INTO visitor_sessions(session_token_hash) VALUES(?)");$st->execute([$hash]);$visitorId=(int)$pdo->lastInsertId();
  $st=$pdo->prepare("INSERT INTO consultations(public_token,visitor_session_id,business_problem,original_user_request,consultation_source,status) VALUES(?,?,?,?, 'ai_chat','in_progress')");$public=token();$st->execute([$public,$visitorId,$problem,$problem]);$id=(int)$pdo->lastInsertId();
  $pdo->prepare("INSERT INTO consultation_messages(consultation_id,sender_type,message_text,message_type) VALUES(?,'user',?,'normal')")->execute([$id,$problem]);
  $pdo->commit();json_out(['consultation_id'=>$id,'public_token'=>$public,'visitor_token'=>$visitor],201);
}

if(preg_match('#^/api/consultations/([a-f0-9]+)/messages$#',$path,$m) && $method==='POST'){
  $c=consultation($pdo,$m[1]);if(!$c)json_out(['error'=>'not_found'],404);$b=body_json();$message=trim($b['message']??'');if($message==='')json_out(['error'=>'message_required'],422);
  $pdo->prepare("INSERT INTO consultation_messages(consultation_id,sender_type,message_text,message_type) VALUES(?,'user',?,'normal')")->execute([$c['id'],$message]);
  $ctx=$pdo->prepare("SELECT sender_type,message_text FROM consultation_messages WHERE consultation_id=? ORDER BY created_at DESC,id DESC LIMIT 10");$ctx->execute([$c['id']]);$context=array_reverse($ctx->fetchAll());
  try{$ex=AiExtraction::extract($pdo,$config,$message,$context);}catch(Throwable $e){json_out(['error'=>'ai_extraction_failed','message'=>$e->getMessage()],502);}
  $pdo->beginTransaction();
  $st=$pdo->prepare("INSERT INTO ai_extraction_runs(consultation_id,model_provider,model_name,prompt_version,status,raw_output) VALUES(?,'openai',?,'php-v1','pending',?)");$st->execute([$c['id'],$config['openai_model'],json_encode($ex,JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES)]);$run=(int)$pdo->lastInsertId();
  $field=$pdo->prepare("INSERT INTO ai_extracted_fields(extraction_run_id,field_kind,field_key,normalized_value,source_text,confidence_score,requires_confirmation) VALUES(?,?,?,?,?,?,?)");
  if(!empty($ex['category_slug']))$field->execute([$run,'category','category_slug',json_encode($ex['category_slug']),$message,1,1]);
  foreach(($ex['requirements']??[]) as $i=>$r)$field->execute([$run,'capability','requirement_'.$i,json_encode($r,JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES),$r['text']??$message,$r['confidence']??null,1]);
  if(!empty($ex['budget']))$field->execute([$run,'budget','budget',json_encode($ex['budget']),$message,1,1]);
  $q=$pdo->prepare("INSERT INTO ai_follow_up_questions(consultation_id,extraction_run_id,question_key,question_text,reason,field_kind,priority,status) VALUES(?,?,?,?,?,'free_text',?,'open')");
  foreach(array_slice($ex['follow_up_questions']??[],0,3) as $i=>$question)$q->execute([$c['id'],$run,'run-'.$run.'-'.$i,$question,'Missing information could materially change the recommendation',10+$i]);
  $pdo->prepare("INSERT INTO consultation_messages(consultation_id,sender_type,message_text,message_type) VALUES(?,'assistant',?,'question')")->execute([$c['id'],$ex['assistant_message']??'Please review the extracted requirements.']);
  $pdo->commit();json_out(['message'=>$ex['assistant_message']??'Please review the extracted requirements.','extraction_run_id'=>$run,'extraction'=>$ex]);
}

if(preg_match('#^/api/consultations/([a-f0-9]+)/extractions/(\d+)/confirm$#',$path,$m) && $method==='POST'){
  $c=consultation($pdo,$m[1]);if(!$c)json_out(['error'=>'not_found'],404);$run=(int)$m[2];$b=body_json();$accept=$b['accept_field_ids']??[];$reject=$b['reject_field_ids']??[];
  $st=$pdo->prepare("SELECT f.* FROM ai_extracted_fields f JOIN ai_extraction_runs r ON r.id=f.extraction_run_id WHERE f.extraction_run_id=? AND r.consultation_id=?");$st->execute([$run,$c['id']]);$fields=$st->fetchAll();$pdo->beginTransaction();
  foreach($fields as $f){$id=(int)$f['id'];if(in_array($id,$reject,true)){$pdo->prepare("UPDATE ai_extracted_fields SET rejected_at=NOW() WHERE id=?")->execute([$id]);continue;}if($accept && !in_array($id,$accept,true))continue;$value=json_decode($f['normalized_value'],true);
    if($f['field_kind']==='category' && is_string($value)){$x=$pdo->prepare("SELECT id FROM categories WHERE slug=?");$x->execute([$value]);if($row=$x->fetch())$pdo->prepare("UPDATE consultations SET category_id=? WHERE id=?")->execute([$row['id'],$c['id']]);}
    if($f['field_kind']==='budget' && is_array($value)){$pdo->prepare("UPDATE consultations SET budget_min=?,budget_max=?,budget_currency=?,budget_period=? WHERE id=?")->execute([$value['min']??null,$value['max']??null,$value['currency']??null,$value['period']??null,$c['id']]);}
    if($f['field_kind']==='capability' && is_array($value) && !empty($value['capability_slug'])){$x=$pdo->prepare("SELECT id FROM capabilities WHERE slug=? LIMIT 1");$x->execute([$value['capability_slug']]);if($cap=$x->fetch()){$exists=$pdo->prepare("SELECT id FROM consultation_requirements WHERE consultation_id=? AND capability_id=? LIMIT 1");$exists->execute([$c['id'],$cap['id']]);$priority=$value['priority']??'important';$mandatory=!empty($value['mandatory'])||$priority==='must_have'?1:0;if($old=$exists->fetch())$pdo->prepare("UPDATE consultation_requirements SET requirement_text=?,priority=?,is_mandatory=?,source='ai_extracted',confidence_score=?,user_confirmed=1 WHERE id=?")->execute([$value['text']??'Confirmed requirement',$priority,$mandatory,$value['confidence']??null,$old['id']]);else $pdo->prepare("INSERT INTO consultation_requirements(consultation_id,capability_id,requirement_text,priority,is_mandatory,source,confidence_score,user_confirmed) VALUES(?,?,?,?,?,'ai_extracted',?,1)")->execute([$c['id'],$cap['id'],$value['text']??'Confirmed requirement',$priority,$mandatory,$value['confidence']??null]);}}
    $pdo->prepare("UPDATE ai_extracted_fields SET accepted_at=NOW() WHERE id=?")->execute([$id]);
  }
  $pdo->prepare("UPDATE ai_extraction_runs SET status='accepted',reviewed_at=NOW() WHERE id=? AND consultation_id=?")->execute([$run,$c['id']]);$pdo->prepare("UPDATE consultations SET status='requirements_review' WHERE id=?")->execute([$c['id']]);$pdo->commit();json_out(['confirmed'=>true]);
}

if(preg_match('#^/api/consultations/([a-f0-9]+)/requirements$#',$path,$m) && $method==='PUT'){
  $b=body_json();$c=consultation($pdo,$m[1]);if(!$c)json_out(['error'=>'not_found'],404);$cid=(int)$c['id'];$pdo->beginTransaction();$pdo->prepare("DELETE FROM consultation_requirements WHERE consultation_id=?")->execute([$cid]);
  $ins=$pdo->prepare("INSERT INTO consultation_requirements(consultation_id,capability_id,requirement_text,priority,is_mandatory,source,user_confirmed) VALUES(?,?,?,?,?,'user_added',1)");foreach(($b['requirements']??[]) as $r)$ins->execute([$cid,$r['capability_id'],$r['text']??'Confirmed requirement',$r['priority']??'important',!empty($r['mandatory'])?1:0]);$pdo->commit();json_out(['saved'=>true]);
}

if(preg_match('#^/api/consultations/([a-f0-9]+)/recommendations$#',$path,$m) && $method==='POST'){
  $c=consultation($pdo,$m[1]);if(!$c)json_out(['error'=>'not_found'],404);$cid=(int)$c['id'];
  $req=$pdo->prepare("SELECT id,capability_id,requirement_text,priority,is_mandatory FROM consultation_requirements WHERE consultation_id=? AND user_confirmed=1");$req->execute([$cid]);$requirements=$req->fetchAll();if(!$requirements)json_out(['error'=>'confirmed_requirements_required'],409);
  $products=$pdo->query("SELECT id,name,slug FROM products WHERE status='active'")->fetchAll();$results=[];$fact=$pdo->prepare("SELECT support_status,confidence_score FROM product_capabilities WHERE product_id=? AND capability_id=? AND edition_id IS NULL LIMIT 1");
  foreach($products as $p){$rows=[];$evidence=[];foreach($requirements as $r){$fact->execute([$p['id'],$r['capability_id']]);$f=$fact->fetch();$status=$f['support_status']??'not_yet_verified';$rows[]=['requirement_id'=>$r['id'],'priority'=>$r['priority'],'is_mandatory'=>$r['is_mandatory'],'support_status'=>$status];$evidence[]=(float)($f['confidence_score']??0);}
    $functional=Scoring::weighted($rows);$mandatory=Scoring::mustHave($rows);$gaps=Scoring::mandatoryGaps($rows);$evidenceScore=$evidence?round(array_sum($evidence)/count($evidence)*100,2):0;$dims=['functional'=>$functional,'mandatory'=>$mandatory,'integration'=>100,'deployment'=>100,'budget'=>100,'regional'=>100,'security'=>100];$overall=Scoring::overall($dims);$results[]=['product'=>$p,'overall'=>$overall,'functional'=>$functional,'mandatory'=>$mandatory,'evidence'=>$evidenceScore,'mandatory_gaps'=>$gaps,'rows'=>$rows,'status'=>$gaps?'conditional':($overall>=90?'strong_match':($overall>=75?'recommended':($overall>=55?'possible_match':'excluded')))];}
  usort($results,function($a,$b){if($a['mandatory_gaps']!==$b['mandatory_gaps'])return $a['mandatory_gaps']<=>$b['mandatory_gaps'];if($a['overall']!==$b['overall'])return $b['overall']<=>$a['overall'];return $b['evidence']<=>$a['evidence'];});
  $inputSnapshot=['consultation_id'=>$cid,'category_id'=>$c['category_id'],'budget'=>['min'=>$c['budget_min'],'max'=>$c['budget_max'],'currency'=>$c['budget_currency'],'period'=>$c['budget_period']],'requirements'=>$requirements];$pdo->beginTransaction();$st=$pdo->prepare("INSERT INTO recommendation_runs(consultation_id,scoring_version,input_snapshot) VALUES(?,'php-v1',?)");$st->execute([$cid,json_encode($inputSnapshot,JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES)]);$run=(int)$pdo->lastInsertId();
  $rec=$pdo->prepare("INSERT INTO consultation_recommendations(consultation_id,product_id,recommendation_run_id,recommendation_rank,overall_score,functional_score,mandatory_score,integration_score,deployment_score,budget_score,regional_score,security_score,evidence_score,mandatory_gap_count,important_gap_count,recommendation_status,scoring_version,snapshot_json) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");$gapIns=$pdo->prepare("INSERT INTO recommendation_gaps(recommendation_id,consultation_requirement_id,gap_type,severity,explanation) VALUES(?,?,?,?,?)");
  foreach($results as $i=>&$r){$snap=json_encode($r,JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES);$rec->execute([$cid,$r['product']['id'],$run,$i+1,$r['overall'],$r['functional'],$r['mandatory'],100,100,100,100,100,$r['evidence'],$r['mandatory_gaps'],0,$r['status'],'php-v1',$snap]);$recId=(int)$pdo->lastInsertId();$r['rank']=$i+1;$r['recommendation_id']=$recId;foreach($r['rows'] as $rr){if(!empty($rr['is_mandatory']) && $rr['support_status']!=='supported'){$type=$rr['support_status']==='not_supported'?'unsupported':'unknown';$explanation=$rr['support_status']==='not_supported'?'The product is explicitly recorded as not supporting this mandatory requirement.':'Support for this mandatory requirement is not fully verified; do not treat unknown as unsupported.';$gapIns->execute([$recId,$rr['requirement_id'],$type,'critical',$explanation]);}}unset($r['rows']);}
  $pdo->prepare("UPDATE consultations SET status='analysis' WHERE id=?")->execute([$cid]);$pdo->commit();json_out(['scoring_version'=>'php-v1','recommendation_run_id'=>$run,'recommendations'=>$results]);
}
json_out(['error'=>'not_found'],404);