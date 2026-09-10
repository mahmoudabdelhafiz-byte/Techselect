<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/Security.php';
require_once __DIR__.'/../app/lib/VerifiedReviewModeration.php';
$config=require __DIR__.'/../app/config.php';$pdo=Db::pdo();Security::start();
$u=Security::requireRole(['reviewer','admin','super_admin']);$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';$method=$_SERVER['REQUEST_METHOD']??'GET';
function out($d,int $s=200){http_response_code($s);header('Content-Type: application/json; charset=utf-8');echo json_encode($d,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);exit;}
function body(){return json_decode(file_get_contents('php://input'),true)?:[];}
if($method!=='GET'){Security::sameOrigin($config);Security::requireCsrf();Security::rateLimit($pdo,'review-moderation',60,60);}
try{
  if($path==='/api/review-admin/reviews'&&$method==='GET'){out(['reviews'=>VerifiedReviewModeration::list($pdo,isset($_GET['status'])?(string)$_GET['status']:null)]);}
  if(preg_match('#^/api/review-admin/reviews/(\d+)$#',$path,$m)&&$method==='GET'){out(['review'=>VerifiedReviewModeration::get($pdo,(int)$m[1])]);}
  if(preg_match('#^/api/review-admin/reviews/(\d+)/moderate$#',$path,$m)&&$method==='PATCH'){$id=(int)$m[1];$old=VerifiedReviewModeration::get($pdo,$id);$b=body();$new=VerifiedReviewModeration::moderate($pdo,$id,(string)($b['status']??''),isset($b['notes'])?(string)$b['notes']:null);Security::audit($pdo,(int)$u['id'],'REVIEW_MODERATION','software_review',(string)$id,['status'=>$old['moderation_status']],['status'=>$new['moderation_status']]);out(['review'=>$new]);}
  if(preg_match('#^/api/review-admin/reviews/(\d+)/verification$#',$path,$m)&&$method==='PUT'){$id=(int)$m[1];$b=body();$new=VerifiedReviewModeration::setVerification($pdo,$id,(string)($b['level']??''),(string)($b['status']??''));Security::audit($pdo,(int)$u['id'],'REVIEW_VERIFICATION_UPDATE','software_review',(string)$id,null,['level'=>$b['level']??null,'status'=>$b['status']??null]);out(['review'=>$new]);}
  if(preg_match('#^/api/review-admin/reviews/(\d+)/risk-flags$#',$path,$m)&&$method==='POST'){$id=(int)$m[1];$b=body();$new=VerifiedReviewModeration::addRiskFlag($pdo,$id,(string)($b['flag_type']??''),(string)($b['severity']??'medium'),isset($b['details'])&&is_array($b['details'])?$b['details']:null);Security::audit($pdo,(int)$u['id'],'REVIEW_RISK_FLAG_ADD','software_review',(string)$id,null,['flag_type'=>$b['flag_type']??null,'severity'=>$b['severity']??null]);out(['review'=>$new],201);}
}catch(Throwable $e){$code=$e instanceof InvalidArgumentException?422:400;out(['error'=>$e->getMessage()],$code);}
out(['error'=>'not_found'],404);
