<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/Security.php';
require_once __DIR__.'/../app/lib/UserConsultationHistory.php';
$config=require __DIR__.'/../app/config.php';
$pdo=Db::pdo();Security::start();
$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';$method=$_SERVER['REQUEST_METHOD']??'GET';
function ah_out($d,int $s=200){http_response_code($s);header('Content-Type: application/json; charset=utf-8');echo json_encode($d,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);exit;}
function ah_body(){return json_decode(file_get_contents('php://input'),true)?:[];}
$user=Security::user();if(!$user)ah_out(['error'=>'authentication_required'],401);
if($path==='/api/account/consultations'&&$method==='GET'){
  $limit=(int)($_GET['limit']??50);ah_out(['consultations'=>UserConsultationHistory::listForUser($pdo,(int)$user['id'],$limit)]);
}
if($path==='/api/account/settings'&&$method==='GET'){
  $st=$pdo->prepare("SELECT id,email,full_name,email_verified_at,last_login_at,created_at FROM users WHERE id=? AND status='active' LIMIT 1");$st->execute([(int)$user['id']]);$row=$st->fetch();if(!$row)ah_out(['error'=>'account_unavailable'],404);
  ah_out(['account'=>['email'=>$row['email'],'name'=>$row['full_name'],'email_verified'=>(bool)$row['email_verified_at'],'last_login_at'=>$row['last_login_at'],'created_at'=>$row['created_at']],'csrf_token'=>Security::csrf()]);
}
if($path==='/api/account/settings'&&$method==='PUT'){
  Security::sameOrigin($config);Security::rateLimit($pdo,'account-settings',20,300);Security::requireCsrf();$b=ah_body();$name=trim((string)($b['name']??''));
  if($name===''||mb_strlen($name)>120)ah_out(['error'=>'invalid_name'],422);
  $pdo->prepare("UPDATE users SET full_name=?,updated_at=NOW() WHERE id=? AND status='active'")->execute([$name,(int)$user['id']]);$_SESSION['user']['name']=$name;Security::audit($pdo,(int)$user['id'],'UPDATE_PROFILE','user',(string)$user['id']);ah_out(['updated'=>true,'user'=>$_SESSION['user']]);
}
if($path==='/api/account/password'&&$method==='PUT'){
  Security::sameOrigin($config);Security::rateLimit($pdo,'account-password',8,600);Security::requireCsrf();$b=ah_body();$current=(string)($b['current_password']??'');$next=(string)($b['new_password']??'');
  if(strlen($next)<10)ah_out(['error'=>'weak_password'],422);
  $st=$pdo->prepare("SELECT password_hash FROM users WHERE id=? AND status='active' LIMIT 1");$st->execute([(int)$user['id']]);$hash=(string)$st->fetchColumn();if($hash===''||!password_verify($current,$hash))ah_out(['error'=>'current_password_invalid'],422);
  if(password_verify($next,$hash))ah_out(['error'=>'new_password_must_differ'],422);
  $pdo->prepare("UPDATE users SET password_hash=?,updated_at=NOW() WHERE id=?")->execute([password_hash($next,PASSWORD_DEFAULT),(int)$user['id']]);Security::audit($pdo,(int)$user['id'],'CHANGE_PASSWORD','user',(string)$user['id']);ah_out(['updated'=>true]);
}
if($path==='/api/account/claim-consultation'&&$method==='POST'){
  Security::sameOrigin($config);Security::rateLimit($pdo,'claim-consultation',20,300);Security::requireCsrf();
  $b=ah_body();$token=strtolower(trim((string)($b['visitor_token']??'')));
  if(!preg_match('/^[a-f0-9]{48}$/',$token))ah_out(['error'=>'invalid_visitor_token'],422);
  $claimed=UserConsultationHistory::claim($pdo,(int)$user['id'],$token);
  if($claimed>0)Security::audit($pdo,(int)$user['id'],'CLAIM_CONSULTATION','visitor_session',null,null,['claimed'=>$claimed]);
  ah_out(['claimed'=>$claimed]);
}
ah_out(['error'=>'not_found'],404);
