<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/Security.php';
require_once __DIR__.'/../app/lib/EvaluationProposalService.php';
$config=require __DIR__.'/../app/config.php';$pdo=Db::pdo();Security::start();$u=Security::requireRole(['reviewer','admin','super_admin']);$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';$method=$_SERVER['REQUEST_METHOD']??'GET';
function ec_out($d,int $s=200){http_response_code($s);header('Content-Type: application/json; charset=utf-8');echo json_encode($d,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);exit;}
function ec_body(){return json_decode(file_get_contents('php://input'),true)?:[];}
if($method!=='GET'){Security::sameOrigin($config);Security::requireCsrf();Security::rateLimit($pdo,'evaluation-control',30,300);}
if($path==='/api/evaluation-control/queue'&&$method==='GET'){ec_out(['items'=>EvaluationProposalService::queue($pdo),'csrf_token'=>Security::csrf()]);}
if(preg_match('#^/api/evaluation-control/products/(\d+)/generate$#',$path,$m)&&$method==='POST'){
  try{$proposal=EvaluationProposalService::generate($pdo,$config,(int)$m[1]);Security::audit($pdo,(int)$u['id'],'EVALUATION_PROPOSAL_GENERATED','product',(string)$m[1],null,['proposal_id'=>$proposal['id'],'overall_score'=>$proposal['proposed_overall_score'],'confidence_score'=>$proposal['proposed_confidence_score']]);ec_out(['proposal'=>$proposal],201);}catch(Throwable $e){ec_out(['error'=>$e->getMessage()],422);}
}
if(preg_match('#^/api/evaluation-control/proposals/(\d+)$#',$path,$m)&&$method==='GET'){try{ec_out(['proposal'=>EvaluationProposalService::getProposal($pdo,(int)$m[1]),'csrf_token'=>Security::csrf()]);}catch(Throwable $e){ec_out(['error'=>$e->getMessage()],404);}}
if(preg_match('#^/api/evaluation-control/proposals/(\d+)/review$#',$path,$m)&&$method==='POST'){
  $b=ec_body();$action=(string)($b['action']??'');$notes=trim((string)($b['notes']??''));if(mb_strlen($notes)>4000)ec_out(['error'=>'notes_too_long'],422);
  try{$before=EvaluationProposalService::getProposal($pdo,(int)$m[1]);$result=EvaluationProposalService::review($pdo,(int)$m[1],$action,(int)$u['id'],$notes);Security::audit($pdo,(int)$u['id'],'EVALUATION_PROPOSAL_REVIEW','evaluation_proposal',(string)$m[1],$before,['action'=>$action,'notes'=>$notes,'result'=>$result]);ec_out(['result'=>$result]);}catch(Throwable $e){$code=$e->getMessage()==='publication_threshold_not_met'?409:422;ec_out(['error'=>$e->getMessage()],$code);}
}
ec_out(['error'=>'not_found'],404);
