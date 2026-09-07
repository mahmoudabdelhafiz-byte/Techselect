<?php
require_once __DIR__.'/../lib/Db.php';
require_once __DIR__.'/../lib/Scoring.php';
$config=require __DIR__.'/../config.php';
$pdo=Db::pdo();
$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';
$method=$_SERVER['REQUEST_METHOD']??'GET';
function json_out($data,int $status=200){http_response_code($status);header('Content-Type: application/json; charset=utf-8');echo json_encode($data,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);exit;}
function body_json(){return json_decode(file_get_contents('php://input'),true)?:[];}
function token(){return bin2hex(random_bytes(24));}
function h($v){return htmlspecialchars((string)$v,ENT_QUOTES,'UTF-8');}

if($path==='/health') json_out(['status'=>'ok','stack'=>'php-mariadb']);
if($path==='/robots.txt'){
  header('Content-Type: text/plain; charset=utf-8');
  echo "User-agent: *\nAllow: /\nDisallow: /admin/\nDisallow: /account/\nDisallow: /api/\nDisallow: /advice/\nDisallow: /login\nDisallow: /register\nSitemap: {$config['site_url']}/sitemap.xml\n";exit;
}
if($path==='/sitemap.xml'){
  header('Content-Type: application/xml; charset=utf-8');
  $urls=[['/','weekly','1.0'],['/software','daily','0.9'],['/methodology','monthly','0.6']];
  foreach($pdo->query("SELECT slug,updated_at FROM products WHERE status='active'") as $r)$urls[]=['/software/'.$r['slug'],'weekly','0.8',$r['updated_at']];
  foreach($pdo->query("SELECT DISTINCT c.slug FROM capabilities c WHERE c.is_active=1") as $r)$urls[]=['/capabilities/'.$r['slug'],'weekly','0.7'];
  echo '<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">';
  foreach($urls as $u){echo '<url><loc>'.h($config['site_url'].$u[0]).'</loc><changefreq>'.$u[1].'</changefreq><priority>'.$u[2].'</priority>'.(!empty($u[3])?'<lastmod>'.date('c',strtotime($u[3])).'</lastmod>':'').'</url>';}
  echo '</urlset>';exit;
}

if($path==='/api/software' && $method==='GET'){
  $q=$pdo->query("SELECT p.id,p.name,p.slug,p.short_description,p.status,v.name vendor,c.name category FROM products p LEFT JOIN vendors v ON v.id=p.vendor_id LEFT JOIN categories c ON c.id=p.category_id WHERE p.status='active' ORDER BY p.name");
  json_out(['products'=>$q->fetchAll()]);
}
if(preg_match('#^/api/software/([a-z0-9-]+)$#',$path,$m) && $method==='GET'){
  $st=$pdo->prepare("SELECT p.*,v.name vendor,c.name category FROM products p LEFT JOIN vendors v ON v.id=p.vendor_id LEFT JOIN categories c ON c.id=p.category_id WHERE p.slug=? AND p.status='active'");$st->execute([$m[1]]);$p=$st->fetch();if(!$p)json_out(['error'=>'not_found'],404);
  $st=$pdo->prepare("SELECT cap.name,cap.slug,mod.name module,pc.support_status,pc.limitations,pc.confidence_score,pc.last_verified_at FROM product_capabilities pc JOIN capabilities cap ON cap.id=pc.capability_id JOIN modules mod ON mod.id=cap.module_id WHERE pc.product_id=? AND pc.edition_id IS NULL ORDER BY mod.name,cap.name");$st->execute([$p['id']]);$p['capabilities']=$st->fetchAll();
  $st=$pdo->prepare("SELECT source_title,source_url,source_type,verification_status,confidence,checked_at FROM evidence_sources WHERE product_id=? ORDER BY checked_at DESC");$st->execute([$p['id']]);$p['evidence']=$st->fetchAll();json_out(['product'=>$p]);
}
if(preg_match('#^/api/capabilities/([a-z0-9-]+)$#',$path,$m) && $method==='GET'){
  $st=$pdo->prepare("SELECT c.id,c.name,c.slug,c.description,m.name module,cat.name category FROM capabilities c JOIN modules m ON m.id=c.module_id JOIN categories cat ON cat.id=m.category_id WHERE c.slug=? AND c.is_active=1 LIMIT 1");$st->execute([$m[1]]);$c=$st->fetch();if(!$c)json_out(['error'=>'not_found'],404);
  $st=$pdo->prepare("SELECT p.name,p.slug,pc.support_status,pc.confidence_score,pc.limitations FROM product_capabilities pc JOIN products p ON p.id=pc.product_id WHERE pc.capability_id=? AND pc.edition_id IS NULL AND p.status='active' ORDER BY pc.confidence_score DESC,p.name");$st->execute([$c['id']]);$c['products']=$st->fetchAll();json_out(['capability'=>$c]);
}
if(preg_match('#^/api/compare/([a-z0-9-]+)-vs-([a-z0-9-]+)$#',$path,$m) && $method==='GET'){
  $slugs=[$m[1],$m[2]];$canonical=$slugs;sort($canonical,SORT_STRING);$canonical=implode('-vs-',$canonical);
  $in=$pdo->prepare("SELECT id,name,slug FROM products WHERE slug IN (?,?) AND status='active'");$in->execute($slugs);$products=$in->fetchAll();if(count($products)!==2)json_out(['error'=>'not_found'],404);
  $ids=array_column($products,'id');$st=$pdo->prepare("SELECT pc.product_id,c.name,c.slug,m.name module,pc.support_status,pc.confidence_score FROM product_capabilities pc JOIN capabilities c ON c.id=pc.capability_id JOIN modules m ON m.id=c.module_id WHERE pc.product_id IN (?,?) AND pc.edition_id IS NULL ORDER BY m.name,c.name");$st->execute($ids);json_out(['canonical'=>$canonical,'products'=>$products,'facts'=>$st->fetchAll()]);
}
if($path==='/api/consultations' && $method==='POST'){
  $b=body_json();$problem=trim($b['business_problem']??'');if(strlen($problem)<5)json_out(['error'=>'business_problem_required'],422);
  $visitor=token();$hash=hash('sha256',$visitor,true);$pdo->beginTransaction();
  $st=$pdo->prepare("INSERT INTO visitor_sessions(session_token_hash) VALUES(?)");$st->execute([$hash]);$visitorId=(int)$pdo->lastInsertId();
  $st=$pdo->prepare("INSERT INTO consultations(public_token,visitor_session_id,business_problem,original_user_request,consultation_source,status) VALUES(?,?,?,?, 'guided_wizard','in_progress')");$public=token();$st->execute([$public,$visitorId,$problem,$problem]);$id=(int)$pdo->lastInsertId();$pdo->commit();json_out(['consultation_id'=>$id,'public_token'=>$public,'visitor_token'=>$visitor],201);
}
if(preg_match('#^/api/consultations/([a-f0-9]+)/requirements$#',$path,$m) && $method==='PUT'){
  $b=body_json();$st=$pdo->prepare("SELECT id FROM consultations WHERE public_token=?");$st->execute([$m[1]]);$c=$st->fetch();if(!$c)json_out(['error'=>'not_found'],404);$cid=(int)$c['id'];$pdo->beginTransaction();$pdo->prepare("DELETE FROM consultation_requirements WHERE consultation_id=?")->execute([$cid]);
  $ins=$pdo->prepare("INSERT INTO consultation_requirements(consultation_id,capability_id,requirement_text,priority,is_mandatory,source,user_confirmed) VALUES(?,?,?,?,?,'user_added',1)");foreach(($b['requirements']??[]) as $r)$ins->execute([$cid,$r['capability_id'],$r['text']??'Confirmed requirement',$r['priority']??'important',!empty($r['mandatory'])?1:0]);$pdo->commit();json_out(['saved'=>true]);
}
if(preg_match('#^/api/consultations/([a-f0-9]+)/recommendations$#',$path,$m) && $method==='POST'){
  $st=$pdo->prepare("SELECT id FROM consultations WHERE public_token=?");$st->execute([$m[1]]);$c=$st->fetch();if(!$c)json_out(['error'=>'not_found'],404);$cid=(int)$c['id'];
  $products=$pdo->query("SELECT id,name,slug FROM products WHERE status='active'")->fetchAll();$req=$pdo->prepare("SELECT id,capability_id,priority,is_mandatory FROM consultation_requirements WHERE consultation_id=?");$req->execute([$cid]);$requirements=$req->fetchAll();$results=[];
  foreach($products as $p){$rows=[];$fact=$pdo->prepare("SELECT support_status FROM product_capabilities WHERE product_id=? AND capability_id=? AND edition_id IS NULL LIMIT 1");foreach($requirements as $r){$fact->execute([$p['id'],$r['capability_id']]);$f=$fact->fetch();$rows[]=['priority'=>$r['priority'],'is_mandatory'=>$r['is_mandatory'],'support_status'=>$f['support_status']??'not_yet_verified'];}
    $functional=Scoring::weighted($rows);$mandatory=Scoring::mustHave($rows);$gaps=Scoring::mandatoryGaps($rows);$dims=['functional'=>$functional,'mandatory'=>$mandatory,'integration'=>100,'deployment'=>100,'budget'=>100,'regional'=>100,'security'=>100];$overall=Scoring::overall($dims);$results[]=['product'=>$p,'overall'=>$overall,'functional'=>$functional,'mandatory'=>$mandatory,'mandatory_gaps'=>$gaps,'status'=>$gaps?'conditional':($overall>=90?'strong_match':($overall>=75?'recommended':'possible_match'))];}
  usort($results,fn($a,$b)=>[$a['mandatory_gaps'],$b['overall']]<=>[$b['mandatory_gaps'],$a['overall']]);json_out(['scoring_version'=>'php-v1','recommendations'=>$results]);
}
json_out(['error'=>'not_found'],404);
