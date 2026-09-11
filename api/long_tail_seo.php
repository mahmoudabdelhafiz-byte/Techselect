<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/Security.php';
require_once __DIR__.'/../app/lib/LongTailSeoGenerator.php';
$config=require __DIR__.'/../app/config.php';$pdo=Db::pdo();Security::start();$user=Security::requireRole(['reviewer','admin','super_admin']);
$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';$method=$_SERVER['REQUEST_METHOD']??'GET';
function lt_out($d,int $s=200){http_response_code($s);header('Content-Type: application/json; charset=utf-8');echo json_encode($d,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);exit;}
function lt_body(){return json_decode(file_get_contents('php://input'),true)?:[];}
if($method!=='GET'){Security::sameOrigin($config);Security::requireCsrf();Security::rateLimit($pdo,'long-tail-seo-write',20,60);}
if($path==='/api/long-tail-seo'&&$method==='GET'){
  $pages=$pdo->query("SELECT g.id,g.canonical_path,g.title,g.status,g.quality_decision,g.quality_score,g.gate_reasons_json,g.last_reviewed_at,g.updated_at,l.template_key,l.context_label FROM seo_generated_pages g JOIN seo_long_tail_pages l ON l.page_id=g.id ORDER BY g.updated_at DESC LIMIT 300")->fetchAll(PDO::FETCH_ASSOC);
  foreach($pages as &$p){$p['reasons']=json_decode($p['gate_reasons_json']?:'[]',true)?:[];unset($p['gate_reasons_json']);}unset($p);
  $categories=$pdo->query("SELECT name,slug FROM categories WHERE is_active=1 ORDER BY name")->fetchAll(PDO::FETCH_ASSOC);
  $products=$pdo->query("SELECT p.name,p.slug,c.slug category_slug FROM products p JOIN categories c ON c.id=p.category_id WHERE p.status='active' ORDER BY p.name LIMIT 1000")->fetchAll(PDO::FETCH_ASSOC);
  lt_out(['templates'=>LongTailSeoGenerator::TEMPLATES,'categories'=>$categories,'products'=>$products,'pages'=>$pages,'csrf_token'=>Security::csrf()]);
}
if($path==='/api/long-tail-seo/generate'&&$method==='POST'){
  try{$r=LongTailSeoGenerator::create($pdo,lt_body(),(int)$user['id']);Security::audit($pdo,(int)$user['id'],'LONG_TAIL_SEO_GENERATE','seo_generated_page',(string)$r['page_id'],null,$r);lt_out($r,201);}catch(Throwable $e){$code=$e instanceof InvalidArgumentException?422:409;lt_out(['error'=>$e->getMessage()],$code);}
}
lt_out(['error'=>'not_found'],404);
