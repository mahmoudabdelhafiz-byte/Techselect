<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/Security.php';
$config=require __DIR__.'/../app/config.php';
$pdo=Db::pdo();Security::start();
$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';$method=$_SERVER['REQUEST_METHOD']??'GET';
function bc_out($d,int $s=200){http_response_code($s);header('Content-Type: application/json; charset=utf-8');echo json_encode($d,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);exit;}
function bc_body(){return json_decode(file_get_contents('php://input'),true)?:[];}
function bc_event(PDO $pdo,int $caseId,int $userId,string $type):void{$pdo->prepare('INSERT INTO business_case_events(business_case_id,user_id,event_type) VALUES(?,?,?)')->execute([$caseId,$userId,$type]);}
$user=Security::user();if(!$user)bc_out(['error'=>'authentication_required'],401);$uid=(int)$user['id'];

if($path==='/api/business-cases'&&$method==='GET'){
 $st=$pdo->prepare("SELECT bc.id,bc.title,bc.status,bc.version,bc.updated_at,p.name product_name,p.slug product_slug FROM business_cases bc JOIN products p ON p.id=bc.product_id WHERE bc.user_id=? ORDER BY bc.updated_at DESC LIMIT 100");$st->execute([$uid]);bc_out(['business_cases'=>$st->fetchAll()]);
}
if($path==='/api/business-cases'&&$method==='POST'){
 Security::sameOrigin($config);Security::rateLimit($pdo,'business-case-create',20,300);Security::requireCsrf();$b=bc_body();$productId=(int)($b['product_id']??0);$consultationId=(int)($b['consultation_id']??0);
 $st=$pdo->prepare("SELECT p.id,p.name,p.slug,v.name vendor,c.name category FROM products p LEFT JOIN vendors v ON v.id=p.vendor_id LEFT JOIN categories c ON c.id=p.category_id WHERE p.id=? AND p.status='active' LIMIT 1");$st->execute([$productId]);$product=$st->fetch();if(!$product)bc_out(['error'=>'invalid_product'],422);
 $consultation=null;if($consultationId>0){$st=$pdo->prepare("SELECT id,business_problem,country_code,company_size_band,expected_users FROM consultations WHERE id=? AND user_id=? LIMIT 1");$st->execute([$consultationId,$uid]);$consultation=$st->fetch();if(!$consultation)bc_out(['error'=>'invalid_consultation'],422);}
 $title=trim((string)($b['title']??('Business Case for '.$product['name'])));if($title===''||mb_strlen($title)>255)bc_out(['error'=>'invalid_title'],422);
 $assumptions=is_array($b['assumptions']??null)?$b['assumptions']:[];$facts=['product'=>['id'=>(int)$product['id'],'name'=>$product['name'],'slug'=>$product['slug'],'vendor'=>$product['vendor'],'category'=>$product['category']],'consultation'=>$consultation?['id'=>(int)$consultation['id'],'business_problem'=>$consultation['business_problem'],'country_code'=>$consultation['country_code'],'company_size_band'=>$consultation['company_size_band'],'expected_users'=>$consultation['expected_users']]:null];
 $st=$pdo->prepare("INSERT INTO business_cases(user_id,consultation_id,product_id,title,assumptions_json,verified_facts_json) VALUES(?,?,?,?,?,?)");$st->execute([$uid,$consultationId?:null,$productId,$title,json_encode($assumptions,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE),json_encode($facts,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE)]);$id=(int)$pdo->lastInsertId();bc_event($pdo,$id,$uid,'started');bc_out(['created'=>true,'id'=>$id,'title'=>$title,'verified_facts'=>$facts,'assumptions'=>$assumptions],201);
}
if(preg_match('#^/api/business-cases/(\d+)$#',$path,$m)){
 $id=(int)$m[1];$st=$pdo->prepare("SELECT bc.*,p.name product_name,p.slug product_slug FROM business_cases bc JOIN products p ON p.id=bc.product_id WHERE bc.id=? AND bc.user_id=? LIMIT 1");$st->execute([$id,$uid]);$case=$st->fetch();if(!$case)bc_out(['error'=>'not_found'],404);
 if($method==='GET'){foreach(['assumptions_json','verified_facts_json','generated_output_json'] as $k)$case[$k]=$case[$k]?json_decode($case[$k],true):null;bc_out(['business_case'=>$case]);}
 if($method==='PUT'){Security::sameOrigin($config);Security::rateLimit($pdo,'business-case-update',30,300);Security::requireCsrf();$b=bc_body();$title=array_key_exists('title',$b)?trim((string)$b['title']):$case['title'];if($title===''||mb_strlen($title)>255)bc_out(['error'=>'invalid_title'],422);$assumptions=array_key_exists('assumptions',$b)&&is_array($b['assumptions'])?$b['assumptions']:json_decode($case['assumptions_json']?:'{}',true);$pdo->prepare("UPDATE business_cases SET title=?,assumptions_json=?,version=version+1 WHERE id=? AND user_id=?")->execute([$title,json_encode($assumptions,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE),$id,$uid]);bc_event($pdo,$id,$uid,'saved');bc_out(['updated'=>true,'id'=>$id]);}
}
bc_out(['error'=>'not_found'],404);
