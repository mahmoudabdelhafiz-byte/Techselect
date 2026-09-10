<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/Scoring.php';
require_once __DIR__.'/../app/lib/Security.php';
require_once __DIR__.'/../app/lib/CategoryGuard.php';
$config=require __DIR__.'/../app/config.php';
$pdo=Db::pdo();
Security::start();Security::sameOrigin($config);Security::rateLimit($pdo,'recommendations',20,60);if(Security::user())Security::requireCsrf();
$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';
function out($d,int $s=200){http_response_code($s);header('Content-Type: application/json; charset=utf-8');echo json_encode($d,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);exit;}
if(!preg_match('#^/api/consultations/([a-f0-9]+)/recommendations$#',$path,$m))out(['error'=>'not_found'],404);
$st=$pdo->prepare("SELECT * FROM consultations WHERE public_token=?");$st->execute([$m[1]]);$c=$st->fetch();if(!$c)out(['error'=>'not_found'],404);$cid=(int)$c['id'];

// Explicit category wording in the original request wins over an earlier AI guess.
$cats=$pdo->query("SELECT id,slug,name FROM categories WHERE is_active=1")->fetchAll();$allowed=array_column($cats,'slug');
$explicitSlug=CategoryGuard::detectExplicit([],trim((string)($c['original_user_request']??$c['business_problem']??'')),$allowed);
$categoryId=!empty($c['category_id'])?(int)$c['category_id']:0;$categorySlug=null;$categoryName=null;
if($explicitSlug){foreach($cats as $cat){if($cat['slug']===$explicitSlug){$categoryId=(int)$cat['id'];$categorySlug=$cat['slug'];$categoryName=$cat['name'];break;}}if($categoryId && (int)($c['category_id']??0)!==$categoryId)$pdo->prepare("UPDATE consultations SET category_id=? WHERE id=?")->execute([$categoryId,$cid]);}
if(!$categoryId){
  $q=$pdo->prepare("SELECT DISTINCT m.category_id FROM consultation_requirements cr JOIN capabilities cap ON cap.id=cr.capability_id JOIN modules m ON m.id=cap.module_id WHERE cr.consultation_id=? AND cr.user_confirmed=1");$q->execute([$cid]);$ids=array_values(array_unique(array_map('intval',array_column($q->fetchAll(),'category_id'))));if(count($ids)===1)$categoryId=$ids[0];
}
if(!$categoryId)out(['error'=>'category_required','message'=>'Confirm a software category before requesting recommendations.'],409);
if(!$categorySlug){foreach($cats as $cat){if((int)$cat['id']===$categoryId){$categorySlug=$cat['slug'];$categoryName=$cat['name'];break;}}}

// Only requirements belonging to the selected primary category may affect product fit.
$req=$pdo->prepare("SELECT cr.id,cr.capability_id,cr.requirement_text,cr.priority,cr.is_mandatory FROM consultation_requirements cr JOIN capabilities cap ON cap.id=cr.capability_id JOIN modules mo ON mo.id=cap.module_id WHERE cr.consultation_id=? AND cr.user_confirmed=1 AND mo.category_id=?");
$req->execute([$cid,$categoryId]);$requirements=$req->fetchAll();
if(!$requirements)out(['error'=>'category_requirements_required','category_slug'=>$categorySlug,'message'=>'Add and confirm at least one requirement for '.$categoryName.' before calculating a fit score. This prevents unrelated capabilities from producing misleading recommendations.'],409);

$ints=$pdo->prepare("SELECT integration_id,priority,is_mandatory FROM consultation_integrations WHERE consultation_id=?");$ints->execute([$cid]);$wantedInts=$ints->fetchAll();
$productsQ=$pdo->prepare("SELECT id,name,slug FROM products WHERE status='active' AND category_id=? ORDER BY name");$productsQ->execute([$categoryId]);$products=$productsQ->fetchAll();
if(!$products)out(['error'=>'insufficient_category_coverage','category_slug'=>$categorySlug,'message'=>'TechSelectAI does not yet have active products in this category.'],409);

$fact=$pdo->prepare("SELECT support_status,confidence_score FROM product_capabilities WHERE product_id=? AND capability_id=? AND edition_id IS NULL LIMIT 1");
$intFact=$pdo->prepare("SELECT support_status,confidence_score FROM product_integrations WHERE product_id=? AND integration_id=? LIMIT 1");
$depFact=$pdo->prepare("SELECT support_status,confidence_score FROM product_deployments WHERE product_id=? AND deployment_model_id=? LIMIT 1");
$price=$pdo->prepare("SELECT amount_min,amount_max,currency,billing_period FROM product_pricing WHERE product_id=? ORDER BY COALESCE(amount_min,999999999) ASC LIMIT 1");
$results=[];
foreach($products as $p){
  $rows=[];$evidence=[];
  foreach($requirements as $r){$fact->execute([$p['id'],$r['capability_id']]);$f=$fact->fetch();$status=$f['support_status']??'not_yet_verified';$rows[]=['requirement_id'=>$r['id'],'priority'=>$r['priority'],'is_mandatory'=>$r['is_mandatory'],'support_status'=>$status];$evidence[]=(float)($f['confidence_score']??0);}
  $functional=Scoring::weighted($rows);$mandatory=Scoring::mustHave($rows);$gaps=Scoring::mandatoryGaps($rows);$dims=['functional'=>$functional,'mandatory'=>$mandatory];
  if($wantedInts){$vals=[];foreach($wantedInts as $wi){$intFact->execute([$p['id'],$wi['integration_id']]);$f=$intFact->fetch();$vals[]=Scoring::support($f['support_status']??'not_yet_verified')*100;}$dims['integration']=round(array_sum($vals)/count($vals),2);}
  if(!empty($c['deployment_model_id'])){$depFact->execute([$p['id'],$c['deployment_model_id']]);$f=$depFact->fetch();$dims['deployment']=round(Scoring::support($f['support_status']??'not_yet_verified')*100,2);}
  if(!empty($c['budget_max'])){$price->execute([$p['id']]);$pr=$price->fetch();if($pr&&$pr['amount_min']!==null){$ratio=(float)$pr['amount_min']/(float)$c['budget_max'];$dims['commercial']=$ratio<=.8?100:($ratio<=1?90:($ratio<=1.2?65:($ratio<=1.5?35:10)));}else{$dims['commercial']=40;}}
  $overall=Scoring::overall($dims);$evidenceScore=$evidence?round(array_sum($evidence)/count($evidence)*100,2):0;
  $status=$gaps?'conditional':($overall>=90?'strong_match':($overall>=75?'recommended':($overall>=55?'possible_match':'excluded')));
  $results[]=['product'=>$p,'category_slug'=>$categorySlug,'overall'=>$overall,'functional'=>$functional,'mandatory'=>$mandatory,'integration'=>$dims['integration']??null,'deployment'=>$dims['deployment']??null,'commercial'=>$dims['commercial']??null,'evidence'=>$evidenceScore,'mandatory_gaps'=>$gaps,'rows'=>$rows,'status'=>$status];
}
usort($results,function($a,$b){if($a['mandatory_gaps']!==$b['mandatory_gaps'])return $a['mandatory_gaps']<=>$b['mandatory_gaps'];if($a['mandatory']!==$b['mandatory'])return $b['mandatory']<=>$a['mandatory'];if($a['overall']!==$b['overall'])return $b['overall']<=>$a['overall'];return $b['evidence']<=>$a['evidence'];});
$input=['consultation_id'=>$cid,'category_id'=>$categoryId,'category_slug'=>$categorySlug,'requirements'=>$requirements,'integrations'=>$wantedInts,'deployment_model_id'=>$c['deployment_model_id'],'budget_max'=>$c['budget_max'],'budget_currency'=>$c['budget_currency']];
$pdo->beginTransaction();$pdo->prepare("INSERT INTO recommendation_runs(consultation_id,scoring_version,input_snapshot) VALUES(?,'php-v1.2-category-guard',?)")->execute([$cid,json_encode($input,JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES)]);$run=(int)$pdo->lastInsertId();
$rec=$pdo->prepare("INSERT INTO consultation_recommendations(consultation_id,product_id,recommendation_run_id,recommendation_rank,overall_score,functional_score,mandatory_score,integration_score,deployment_score,budget_score,regional_score,security_score,evidence_score,mandatory_gap_count,important_gap_count,recommendation_status,scoring_version,snapshot_json) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
$gap=$pdo->prepare("INSERT INTO recommendation_gaps(recommendation_id,consultation_requirement_id,gap_type,severity,explanation) VALUES(?,?,?,?,?)");
foreach($results as $i=>&$r){$rec->execute([$cid,$r['product']['id'],$run,$i+1,$r['overall'],$r['functional'],$r['mandatory'],$r['integration']??100,$r['deployment']??100,$r['commercial']??100,100,100,$r['evidence'],$r['mandatory_gaps'],0,$r['status'],'php-v1.2-category-guard',json_encode($r)]);$rid=(int)$pdo->lastInsertId();$r['rank']=$i+1;$r['recommendation_id']=$rid;foreach($r['rows'] as $rr){if(!empty($rr['is_mandatory'])&&$rr['support_status']!=='supported'){$gap->execute([$rid,$rr['requirement_id'],$rr['support_status']==='not_supported'?'unsupported':'unknown','critical',$rr['support_status']==='not_supported'?'Explicitly recorded as not supported.':'Not fully verified; unknown is not treated as unsupported.']);}}unset($r['rows']);}
$pdo->prepare("UPDATE consultations SET status='analysis' WHERE id=?")->execute([$cid]);$pdo->commit();
out(['scoring_version'=>'php-v1.2-category-guard','category_slug'=>$categorySlug,'recommendation_run_id'=>$run,'recommendations'=>$results]);
