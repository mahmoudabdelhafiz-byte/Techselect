<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/Security.php';
require_once __DIR__.'/../app/lib/VerifiedReviewRating.php';
$config=require __DIR__.'/../app/config.php';
$pdo=Db::pdo();Security::start();
$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';$method=$_SERVER['REQUEST_METHOD']??'GET';
function out($d,int $s=200){http_response_code($s);header('Content-Type: application/json; charset=utf-8');echo json_encode($d,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);exit;}
function body(){return json_decode(file_get_contents('php://input'),true)?:[];}
function opt_rating($v){if($v===null||$v==='')return null;$n=(int)$v;if($n<1||$n>5)throw new InvalidArgumentException('invalid_rating');return $n;}
if($path==='/api/reviews'&&$method==='POST'){
  Security::sameOrigin($config);Security::requireCsrf();Security::rateLimit($pdo,'review-submit',6,3600);
  $u=Security::user();if(!$u)out(['error'=>'authentication_required'],401);
  $ust=$pdo->prepare("SELECT id,email,status,email_verified_at FROM users WHERE id=? LIMIT 1");$ust->execute([(int)$u['id']]);$dbu=$ust->fetch();
  if(!$dbu||$dbu['status']!=='active'||!$dbu['email_verified_at'])out(['error'=>'verified_email_required'],403);
  $b=body();$productId=(int)($b['product_id']??0);$overall=(int)($b['overall_rating']??0);if($productId<1||$overall<1||$overall>5)out(['error'=>'invalid_review'],422);
  $pst=$pdo->prepare("SELECT id FROM products WHERE id=? AND status='active'");$pst->execute([$productId]);if(!$pst->fetch())out(['error'=>'product_not_found'],404);
  $ratingFields=['ease_of_use_rating','implementation_rating','administration_rating','support_rating','value_for_money_rating','feature_depth_rating','integration_quality_rating','reliability_rating'];
  try{$ratings=[];foreach($ratingFields as $f)$ratings[$f]=opt_rating($b[$f]??null);}catch(Throwable $e){out(['error'=>'invalid_rating'],422);}
  $bool=function($v){return $v===null||$v===''?null:((int)$v===1?1:0);};
  $txt=function($v,$max){$s=trim((string)($v??''));if($s==='')return null;return mb_substr($s,0,$max);};
  $publicMode=in_array(($b['public_identity_mode']??''),['anonymous_verified','context_only'],true)?$b['public_identity_mode']:'anonymous_verified';
  try{
    $pdo->beginTransaction();
    $sql="INSERT INTO software_reviews(product_id,user_id,overall_rating,ease_of_use_rating,implementation_rating,administration_rating,support_rating,value_for_money_rating,feature_depth_rating,integration_quality_rating,reliability_rating,would_recommend,would_choose_again,pros,cons,improvements,reviewer_role,reviewer_industry,reviewer_country,company_size_band,usage_duration_band,deployment_model,implementation_duration_band,budget_outcome_band,implementation_difficulty,migration_complexity,public_identity_mode,moderation_status) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,'pending')";
    $st=$pdo->prepare($sql);$st->execute([$productId,(int)$u['id'],$overall,$ratings['ease_of_use_rating'],$ratings['implementation_rating'],$ratings['administration_rating'],$ratings['support_rating'],$ratings['value_for_money_rating'],$ratings['feature_depth_rating'],$ratings['integration_quality_rating'],$ratings['reliability_rating'],$bool($b['would_recommend']??null),$bool($b['would_choose_again']??null),$txt($b['pros']??'',4000),$txt($b['cons']??'',4000),$txt($b['improvements']??'',4000),$txt($b['reviewer_role']??'',120),$txt($b['reviewer_industry']??'',120),$txt($b['reviewer_country']??'',80),$txt($b['company_size_band']??'',50),$txt($b['usage_duration_band']??'',50),$txt($b['deployment_model']??'',80),$txt($b['implementation_duration_band']??'',50),$txt($b['budget_outcome_band']??'',50),$txt($b['implementation_difficulty']??'',32),$txt($b['migration_complexity']??'',32),$publicMode]);
    $rid=(int)$pdo->lastInsertId();
    $pdo->prepare("INSERT INTO software_review_verifications(review_id,verification_level,verification_status,verification_reference_hash,verified_at) VALUES(?, 'email_verified','verified',?,NOW())")->execute([$rid,hash('sha256',strtolower($dbu['email']),true)]);
    $riskHash=hash('sha256',strtolower($dbu['email']).'|'.$productId,true);
    $pdo->prepare("UPDATE software_review_verifications SET verification_reference_hash=? WHERE review_id=? AND verification_level='email_verified'")->execute([$riskHash,$rid]);
    $pdo->commit();
    Security::audit($pdo,(int)$u['id'],'SOFTWARE_REVIEW_SUBMIT','software_review',(string)$rid,null,['product_id'=>$productId,'moderation_status'=>'pending']);
    out(['submitted'=>true,'review_id'=>$rid,'moderation_status'=>'pending','verification_level'=>'email_verified'],201);
  }catch(PDOException $e){if($pdo->inTransaction())$pdo->rollBack();if(($e->errorInfo[1]??null)==1062)out(['error'=>'review_already_exists'],409);out(['error'=>'review_submission_failed'],500);}
}
if($path==='/api/reviews/mine'&&$method==='GET'){
  $u=Security::user();if(!$u)out(['error'=>'authentication_required'],401);
  try{
    $st=$pdo->prepare("SELECT r.id,r.product_id,p.name product,p.slug product_slug,r.overall_rating,r.moderation_status,r.submitted_at,r.updated_at,r.published_at,(SELECT v.verification_level FROM software_review_verifications v WHERE v.review_id=r.id AND v.verification_status='verified' ORDER BY FIELD(v.verification_level,'admin_verified','proof_of_use_verified','business_domain_verified','email_verified') LIMIT 1) verification_level,(SELECT rw.reward_type FROM software_review_rewards rw WHERE rw.review_id=r.id LIMIT 1) reward_type,(SELECT rw.eligibility_status FROM software_review_rewards rw WHERE rw.review_id=r.id LIMIT 1) reward_eligibility_status,(SELECT rw.issuance_status FROM software_review_rewards rw WHERE rw.review_id=r.id LIMIT 1) reward_status,(SELECT rw.issued_at FROM software_review_rewards rw WHERE rw.review_id=r.id LIMIT 1) reward_issued_at,(SELECT rw.redeemed_at FROM software_review_rewards rw WHERE rw.review_id=r.id LIMIT 1) reward_redeemed_at,(SELECT rw.expires_at FROM software_review_rewards rw WHERE rw.review_id=r.id LIMIT 1) reward_expires_at FROM software_reviews r JOIN products p ON p.id=r.product_id WHERE r.user_id=? ORDER BY r.submitted_at DESC");
    $st->execute([(int)$u['id']]);out(['reviews'=>$st->fetchAll()]);
  }catch(Throwable $e){out(['error'=>'review_status_unavailable'],503);}
}
out(['error'=>'not_found'],404);
