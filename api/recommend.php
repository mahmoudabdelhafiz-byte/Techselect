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
$st=$pdo->prepare("SELECT c.*,vs.country_code session_country_code FROM consultations c LEFT JOIN visitor_sessions vs ON vs.id=c.visitor_session_id WHERE c.public_token=?");$st->execute([$m[1]]);$c=$st->fetch();if(!$c)out(['error'=>'not_found'],404);$cid=(int)$c['id'];

// Explicit category wording in the original request wins over an earlier AI guess.
$cats=$pdo->query("SELECT id,slug,name FROM categories WHERE is_active=1")->fetchAll();$allowed=array_column($cats,'slug');
$explicitSlug=CategoryGuard::detectExplicit([],trim((string)($c['original_user_request']??$c['business_problem']??'')),$allowed);
$categoryId=!empty($c['category_id'])?(int)$c['category_id']:0;$categorySlug=null;$categoryName=null;
if($explicitSlug){foreach($cats as $cat){if($cat['slug']===$explicitSlug){$categoryId=(int)$cat['id'];$categorySlug=$cat['slug'];$categoryName=$cat['name'];break;}}if($categoryId && (int)($c['category_id']??0)!==$categoryId)$pdo->prepare("UPDATE consultations SET category_id=? WHERE id=?")->execute([$categoryId,$cid]);}
if(!$categoryId){$q=$pdo->prepare("SELECT DISTINCT m.category_id FROM consultation_requirements cr JOIN capabilities cap ON cap.id=cr.capability_id JOIN modules m ON m.id=cap.module_id WHERE cr.consultation_id=? AND cr.user_confirmed=1");$q->execute([$cid]);$ids=array_values(array_unique(array_map('intval',array_column($q->fetchAll(),'category_id'))));if(count($ids)===1)$categoryId=$ids[0];}
if(!$categoryId)out(['error'=>'category_required','message'=>'Confirm a software category before requesting recommendations.'],409);
if(!$categorySlug){foreach($cats as $cat){if((int)$cat['id']===$categoryId){$categorySlug=$cat['slug'];$categoryName=$cat['name'];break;}}}

// Only requirements belonging to the selected primary category may affect product fit.
$req=$pdo->prepare("SELECT cr.id,cr.capability_id,cr.requirement_text,cr.priority,cr.is_mandatory FROM consultation_requirements cr JOIN capabilities cap ON cap.id=cr.capability_id JOIN modules mo ON mo.id=cap.module_id WHERE cr.consultation_id=? AND cr.user_confirmed=1 AND mo.category_id=?");
$req->execute([$cid,$categoryId]);$requirements=$req->fetchAll();
if(!$requirements)out(['error'=>'category_requirements_required','category_slug'=>$categorySlug,'message'=>'Add and confirm at least one requirement for '.$categoryName.' before calculating a fit score. This prevents unrelated capabilities from producing misleading recommendations.'],409);

$ints=$pdo->prepare("SELECT integration_id,priority,is_mandatory FROM consultation_integrations WHERE consultation_id=?");$ints->execute([$cid]);$wantedInts=$ints->fetchAll();
$productsQ=$pdo->prepare("SELECT id,name,slug FROM products WHERE status='active' AND category_id=? ORDER BY name");$productsQ->execute([$categoryId]);$products=$productsQ->fetchAll();
if(!$products)out(['error'=>'insufficient_category_coverage','category_slug'=>$categorySlug,'message'=>'TechSelectAI does not yet have active products in this category.'],409);

// Security/compliance is buyer-relevant only when a canonical standard/regulation is explicitly named.
$buyerText=mb_strtolower(trim((string)($c['original_user_request']??'').' '.(string)($c['business_problem']??'').' '.implode(' ',array_column($requirements,'requirement_text'))));
$aliases=[
  'iso-27001'=>['iso 27001','iso/iec 27001','iso27001'],
  'soc-2'=>['soc 2','soc2'],
  'gdpr'=>['gdpr','general data protection regulation'],
  'hipaa'=>['hipaa'],
  'pci-dss'=>['pci dss','pci-dss'],
  'saudi-nca-ecc'=>['nca ecc','saudi nca','essential cybersecurity controls'],
  'sama-cybersecurity-framework'=>['sama cybersecurity','sama cyber security','sama csf'],
];
$standards=$pdo->query("SELECT id,name,slug FROM compliance_standards WHERE is_active=1 ORDER BY id")->fetchAll();$requestedStandards=[];
foreach($standards as $s){$terms=$aliases[$s['slug']]??[mb_strtolower($s['name'])];foreach($terms as $term){if($term!==''&&mb_stripos($buyerText,$term)!==false){$requestedStandards[]=$s;break;}}}
$countryCode=strtoupper(trim((string)($c['session_country_code']??'')));if(!preg_match('/^[A-Z]{2}$/',$countryCode))$countryCode='';

$fact=$pdo->prepare("SELECT support_status,confidence_score FROM product_capabilities WHERE product_id=? AND capability_id=? AND edition_id IS NULL LIMIT 1");
$intFact=$pdo->prepare("SELECT support_status,confidence_score FROM product_integrations WHERE product_id=? AND integration_id=? LIMIT 1");
$depFact=$pdo->prepare("SELECT support_status,confidence_score FROM product_deployments WHERE product_id=? AND deployment_model_id=? LIMIT 1");
$price=$pdo->prepare("SELECT amount_min,amount_max,currency,billing_period FROM product_pricing WHERE product_id=? ORDER BY COALESCE(amount_min,999999999) ASC LIMIT 1");
$regionalFact=$pdo->prepare("SELECT pra.availability_status,pra.confidence_score FROM product_regional_availability pra JOIN countries co ON co.id=pra.country_id WHERE pra.product_id=? AND co.code=? LIMIT 1");
$complianceFact=$pdo->prepare("SELECT support_status,confidence_score FROM product_compliance WHERE product_id=? AND compliance_standard_id=? LIMIT 1");
$results=[];$requirementCount=count($requirements);
foreach($products as $p){
  $rows=[];$evidence=[];$recordedFacts=0;$knownFacts=0;$unknownFacts=0;
  foreach($requirements as $r){
    $fact->execute([$p['id'],$r['capability_id']]);$f=$fact->fetch();$status=$f['support_status']??'not_yet_verified';if($f)$recordedFacts++;if($f&&!in_array($status,['unknown','not_yet_verified'],true))$knownFacts++;else$unknownFacts++;
    $rows[]=['requirement_id'=>$r['id'],'priority'=>$r['priority'],'is_mandatory'=>$r['is_mandatory'],'support_status'=>$status];$evidence[]=(float)($f['confidence_score']??0);
  }
  $functional=Scoring::weighted($rows);$mandatory=Scoring::mustHave($rows);$gaps=Scoring::mandatoryGaps($rows);$dims=['functional'=>$functional,'mandatory'=>$mandatory];
  if($wantedInts){$vals=[];foreach($wantedInts as $wi){$intFact->execute([$p['id'],$wi['integration_id']]);$f=$intFact->fetch();$vals[]=Scoring::support($f['support_status']??'not_yet_verified')*100;}$dims['integration']=round(array_sum($vals)/count($vals),2);}
  if(!empty($c['deployment_model_id'])){$depFact->execute([$p['id'],$c['deployment_model_id']]);$f=$depFact->fetch();$dims['deployment']=round(Scoring::support($f['support_status']??'not_yet_verified')*100,2);}
  if(!empty($c['budget_max'])){$price->execute([$p['id']]);$pr=$price->fetch();if($pr&&$pr['amount_min']!==null){$ratio=(float)$pr['amount_min']/(float)$c['budget_max'];$dims['commercial']=$ratio<=.8?100:($ratio<=1?90:($ratio<=1.2?65:($ratio<=1.5?35:10)));}else{$dims['commercial']=40;}}
  $regionalStatus=null;if($countryCode!==''){$regionalFact->execute([$p['id'],$countryCode]);$rf=$regionalFact->fetch();$regionalStatus=$rf['availability_status']??'not_yet_verified';$dims['regional']=round(Scoring::regional($regionalStatus)*100,2);$evidence[]=(float)($rf['confidence_score']??0);}
  $complianceRows=[];if($requestedStandards){$vals=[];foreach($requestedStandards as $standard){$complianceFact->execute([$p['id'],$standard['id']]);$cf=$complianceFact->fetch();$cs=$cf['support_status']??'not_yet_verified';$vals[]=Scoring::support($cs)*100;$evidence[]=(float)($cf['confidence_score']??0);$complianceRows[]=['slug'=>$standard['slug'],'name'=>$standard['name'],'support_status'=>$cs];}$dims['security']=round(array_sum($vals)/count($vals),2);}
  $overall=Scoring::overall($dims);$evidenceScore=$evidence?round(array_sum($evidence)/count($evidence)*100,2):0;
  $knownCoverage=$requirementCount?round($knownFacts/$requirementCount*100,2):0;$recordedCoverage=$requirementCount?round($recordedFacts/$requirementCount*100,2):0;$coverageLabel=$knownCoverage>=80?'high':($knownCoverage>=60?'moderate':'limited');
  $status=$gaps?'conditional':($overall>=90?'strong_match':($overall>=75?'recommended':($overall>=55?'possible_match':'excluded')));
  $results[]=['product'=>$p,'category_slug'=>$categorySlug,'overall'=>$overall,'functional'=>$functional,'mandatory'=>$mandatory,'integration'=>$dims['integration']??null,'deployment'=>$dims['deployment']??null,'commercial'=>$dims['commercial']??null,'regional'=>$dims['regional']??null,'regional_country_code'=>$countryCode!==''?$countryCode:null,'regional_status'=>$regionalStatus,'security'=>$dims['security']??null,'requested_compliance'=>$complianceRows,'evidence'=>$evidenceScore,'evidence_coverage'=>$knownCoverage,'recorded_coverage'=>$recordedCoverage,'evidence_coverage_label'=>$coverageLabel,'known_fact_count'=>$knownFacts,'recorded_fact_count'=>$recordedFacts,'unknown_requirement_count'=>$unknownFacts,'requirement_count'=>$requirementCount,'mandatory_gaps'=>$gaps,'rows'=>$rows,'status'=>$status];
}
usort($results,function($a,$b){if($a['mandatory_gaps']!==$b['mandatory_gaps'])return $a['mandatory_gaps']<=>$b['mandatory_gaps'];if($a['mandatory']!==$b['mandatory'])return $b['mandatory']<=>$a['mandatory'];if($a['overall']!==$b['overall'])return $b['overall']<=>$a['overall'];return $b['evidence']<=>$a['evidence'];});
$bestCoverage=$results?max(array_column($results,'evidence_coverage')):0;
foreach($results as &$r){$coverageGap=round($bestCoverage-$r['evidence_coverage'],2);$r['evidence_coverage_gap_to_best']=$coverageGap;$r['evidence_warning']=$r['evidence_coverage']<60?'Limited evidence coverage: several requested capabilities are not yet verified. Unknown does not mean unsupported.':($coverageGap>=25?'Evidence coverage is materially lower than the best-researched product in this comparison. Interpret fit scores with additional caution.':null);}
unset($r);
$input=['consultation_id'=>$cid,'category_id'=>$categoryId,'category_slug'=>$categorySlug,'requirements'=>$requirements,'integrations'=>$wantedInts,'deployment_model_id'=>$c['deployment_model_id'],'budget_max'=>$c['budget_max'],'budget_currency'=>$c['budget_currency'],'country_code'=>$countryCode!==''?$countryCode:null,'requested_compliance_slugs'=>array_column($requestedStandards,'slug')];
$scoringVersion='php-v1.3-verified-compliance-regional';
$pdo->beginTransaction();$pdo->prepare("INSERT INTO recommendation_runs(consultation_id,scoring_version,input_snapshot) VALUES(?,?,?)")->execute([$cid,$scoringVersion,json_encode($input,JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES)]);$run=(int)$pdo->lastInsertId();
$rec=$pdo->prepare("INSERT INTO consultation_recommendations(consultation_id,product_id,recommendation_run_id,recommendation_rank,overall_score,functional_score,mandatory_score,integration_score,deployment_score,budget_score,regional_score,security_score,evidence_score,mandatory_gap_count,important_gap_count,recommendation_status,scoring_version,snapshot_json) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
$gap=$pdo->prepare("INSERT INTO recommendation_gaps(recommendation_id,consultation_requirement_id,gap_type,severity,explanation) VALUES(?,?,?,?,?)");
foreach($results as $i=>&$r){$storedRegional=$r['regional']??40;$storedSecurity=$r['security']??40;$rec->execute([$cid,$r['product']['id'],$run,$i+1,$r['overall'],$r['functional'],$r['mandatory'],$r['integration']??100,$r['deployment']??100,$r['commercial']??100,$storedRegional,$storedSecurity,$r['evidence'],$r['mandatory_gaps'],0,$r['status'],$scoringVersion,json_encode($r)]);$rid=(int)$pdo->lastInsertId();$r['rank']=$i+1;$r['recommendation_id']=$rid;foreach($r['rows'] as $rr){if(!empty($rr['is_mandatory'])&&$rr['support_status']!=='supported'){$gap->execute([$rid,$rr['requirement_id'],$rr['support_status']==='not_supported'?'unsupported':'unknown','critical',$rr['support_status']==='not_supported'?'Explicitly recorded as not supported.':'Not fully verified; unknown is not treated as unsupported.']);}}unset($r['rows']);}
unset($r);
$pdo->prepare("UPDATE consultations SET status='analysis' WHERE id=?")->execute([$cid]);$pdo->commit();
out(['scoring_version'=>$scoringVersion,'category_slug'=>$categorySlug,'recommendation_run_id'=>$run,'scoring_context'=>['country_code'=>$countryCode!==''?$countryCode:null,'requested_compliance'=>array_column($requestedStandards,'slug')],'recommendations'=>$results]);
