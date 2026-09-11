<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/Security.php';
require_once __DIR__.'/../app/lib/UserConsultationHistory.php';
$config=require __DIR__.'/../app/config.php';
$pdo=Db::pdo();
Security::start();
$method=$_SERVER['REQUEST_METHOD']??'GET';
$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';
if(in_array($method,['POST','PUT','PATCH','DELETE'],true)){
  Security::sameOrigin($config);
  Security::rateLimit($pdo,'consultation-write',40,60);
  if(Security::user()) Security::requireCsrf();
}

function consultation_context_out(array $data,int $status=200): void {
  http_response_code($status);
  header('Content-Type: application/json; charset=utf-8');
  echo json_encode($data,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);
  exit;
}
function consultation_context_record(PDO $pdo,string $token): ?array {
  $st=$pdo->prepare("SELECT id,user_id,country_code,industry_id,company_size_band,expected_users FROM consultations WHERE public_token=? LIMIT 1");
  $st->execute([$token]);
  return $st->fetch()?:null;
}
function consultation_context_authorize(array $c): void {
  if(empty($c['user_id'])) return;
  $u=Security::user();
  if(!$u || (int)$u['id']!==(int)$c['user_id']) consultation_context_out(['error'=>'forbidden'],403);
}

if($path==='/api/consultations' && $method==='POST'){
  $body=json_decode(file_get_contents('php://input'),true)?:[];
  $problem=trim((string)($body['business_problem']??''));
  if(strlen($problem)<5){http_response_code(422);header('Content-Type: application/json; charset=utf-8');echo json_encode(['error'=>'business_problem_required']);exit;}
  try{$created=UserConsultationHistory::create($pdo,Security::user(),$problem,'ai_chat');}
  catch(Throwable $e){http_response_code(500);header('Content-Type: application/json; charset=utf-8');echo json_encode(['error'=>'consultation_create_failed']);exit;}
  http_response_code(201);header('Content-Type: application/json; charset=utf-8');echo json_encode($created,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);exit;
}

if(preg_match('#^/api/consultations/([a-f0-9]{48})/context/?$#',$path,$m)){
  $c=consultation_context_record($pdo,$m[1]);
  if(!$c) consultation_context_out(['error'=>'not_found'],404);
  consultation_context_authorize($c);

  if($method==='GET'){
    $industries=[];
    try{$industries=$pdo->query("SELECT id,name FROM industries ORDER BY name")->fetchAll()?:[];}catch(Throwable $e){}
    consultation_context_out(['context'=>[
      'country_code'=>$c['country_code']?:null,
      'industry_id'=>$c['industry_id']!==null?(int)$c['industry_id']:null,
      'company_size_band'=>$c['company_size_band']?:null,
      'expected_users'=>$c['expected_users']!==null?(int)$c['expected_users']:null
    ],'industries'=>$industries]);
  }

  if($method==='PUT'){
    $body=json_decode(file_get_contents('php://input'),true)?:[];
    $country=strtoupper(trim((string)($body['country_code']??'')));
    if($country!=='' && !preg_match('/^[A-Z]{2}$/',$country)) consultation_context_out(['error'=>'invalid_country_code'],422);
    $size=trim((string)($body['company_size_band']??''));
    $allowedSizes=['1-49','50-199','200-499','500-999','1000+'];
    if($size!=='' && !in_array($size,$allowedSizes,true)) consultation_context_out(['error'=>'invalid_company_size_band'],422);
    $users=$body['expected_users']??null;
    if($users==='' || $users===null) $users=null;
    else {
      if(filter_var($users,FILTER_VALIDATE_INT)===false || (int)$users<1 || (int)$users>10000000) consultation_context_out(['error'=>'invalid_expected_users'],422);
      $users=(int)$users;
    }
    $industry=$body['industry_id']??null;
    if($industry==='' || $industry===null) $industry=null;
    else {
      if(filter_var($industry,FILTER_VALIDATE_INT)===false || (int)$industry<1) consultation_context_out(['error'=>'invalid_industry'],422);
      $st=$pdo->prepare("SELECT id FROM industries WHERE id=? LIMIT 1");$st->execute([(int)$industry]);
      if(!$st->fetchColumn()) consultation_context_out(['error'=>'invalid_industry'],422);
      $industry=(int)$industry;
    }
    $st=$pdo->prepare("UPDATE consultations SET country_code=?,industry_id=?,company_size_band=?,expected_users=? WHERE id=?");
    $st->execute([$country!==''?$country:null,$industry,$size!==''?$size:null,$users,(int)$c['id']]);
    consultation_context_out(['saved'=>true,'context'=>[
      'country_code'=>$country!==''?$country:null,
      'industry_id'=>$industry,
      'company_size_band'=>$size!==''?$size:null,
      'expected_users'=>$users
    ]]);
  }

  consultation_context_out(['error'=>'method_not_allowed'],405);
}

require __DIR__.'/index.php';
