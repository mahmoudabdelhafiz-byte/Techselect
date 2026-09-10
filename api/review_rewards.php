<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/Security.php';
require_once __DIR__.'/../app/lib/VerifiedReviewRewards.php';
$config=require __DIR__.'/../app/config.php';
$pdo=Db::pdo();Security::start();Security::requireRole(['reviewer','admin','super_admin']);
$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';$method=$_SERVER['REQUEST_METHOD']??'GET';
function rr_out($d,int $s=200){http_response_code($s);header('Content-Type: application/json; charset=utf-8');echo json_encode($d,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);exit;}
function rr_body(){return json_decode(file_get_contents('php://input'),true)?:[];}
try{
  if($path==='/api/review-rewards'&&$method==='GET'){rr_out(['rewards'=>VerifiedReviewRewards::list($pdo,(string)($_GET['status']??''))]);}
  if(preg_match('#^/api/review-rewards/(\d+)/(eligible|issue|status)$#',$path,$m)){
    if($method!=='POST')rr_out(['error'=>'method_not_allowed'],405);
    Security::sameOrigin($config);Security::requireCsrf();$b=rr_body();$id=(int)$m[1];$action=$m[2];
    if($action==='eligible'){
      VerifiedReviewRewards::setEligible($pdo,$id,(string)($b['reward_type']??''));
      Security::audit($pdo,(int)(Security::user()['id']??0),'REVIEW_REWARD_ELIGIBLE','software_review',(string)$id,null,['reward_type'=>$b['reward_type']??null]);
    }elseif($action==='issue'){
      VerifiedReviewRewards::issue($pdo,$id,(string)($b['reference']??''),isset($b['expires_at'])&&$b['expires_at']!==''?(string)$b['expires_at']:null);
      Security::audit($pdo,(int)(Security::user()['id']??0),'REVIEW_REWARD_ISSUE','software_review',(string)$id,null,['expires_at'=>$b['expires_at']??null]);
    }else{
      $status=(string)($b['status']??'');VerifiedReviewRewards::mark($pdo,$id,$status);
      Security::audit($pdo,(int)(Security::user()['id']??0),'REVIEW_REWARD_'.strtoupper($status),'software_review',(string)$id,null,null);
    }
    rr_out(['ok'=>true]);
  }
  rr_out(['error'=>'not_found'],404);
}catch(InvalidArgumentException|RuntimeException $e){rr_out(['error'=>$e->getMessage()],422);}catch(Throwable $e){rr_out(['error'=>'reward_workflow_unavailable'],503);}
