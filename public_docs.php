<?php
require_once __DIR__.'/app/lib/Db.php';
$config=require __DIR__.'/app/config.php';
$pdo=Db::pdo();
$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';
function e($v){return htmlspecialchars((string)$v,ENT_QUOTES,'UTF-8');}
function status_label($v){return ucwords(str_replace('_',' ',(string)$v));}
function pct($v){return (int)round(((float)$v)*100);}
function page_start($title,$description,$canonical,$breadcrumb){
  global $config;
  $title=e($title);$description=e($description);$canonical=e($canonical);
  $json=['@context'=>'https://schema.org','@type'=>'BreadcrumbList','itemListElement'=>[]];
  foreach($breadcrumb as $i=>$b)$json['itemListElement'][]=['@type'=>'ListItem','position'=>$i+1,'name'=>$b[0],'item'=>$config['site_url'].$b[1]];
  echo '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">';
  echo '<title>'.$title.'</title><meta name="description" content="'.$description.'"><link rel="canonical" href="'.$canonical.'">';
  echo '<meta property="og:type" content="website"><meta property="og:title" content="'.$title.'"><meta property="og:description" content="'.$description.'"><meta property="og:url" content="'.$canonical.'">';
  echo '<script type="application/ld+json">'.json_encode($json,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE).'</script>';
  echo '<style>body{font-family:Inter,Arial,sans-serif;margin:0;color:#172033;background:#fff}header{display:flex;justify-content:space-between;align-items:center;padding:18px max(24px,5vw);border-bottom:1px solid #e7ebf0}header a{color:#123b67;text-decoration:none;font-weight:700}nav a{margin-left:18px;font-weight:600}main{max-width:1120px;margin:42px auto;padding:0 24px}h1{font-size:clamp(34px,5vw,56px);line-height:1.05;margin:8px 0 16px}h2{margin-top:38px}.eyebrow{font-size:13px;text-transform:uppercase;letter-spacing:.08em;color:#42627f;font-weight:700}.lead{font-size:19px;line-height:1.7;color:#4b596c;max-width:850px}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(250px,1fr));gap:16px}.card{display:block;border:1px solid #dfe6ee;border-radius:14px;padding:18px;text-decoration:none;color:inherit;background:#fff}.card:hover{border-color:#8ca8c1}.status{display:inline-block;padding:4px 9px;border-radius:999px;background:#eef4f8;font-size:12px}.muted{color:#6c7787}.cta{margin-top:40px;padding:24px;border-radius:16px;background:#f3f8fb;border:1px solid #d7e4ed}.cta a{display:inline-block;margin-top:8px;padding:11px 16px;border-radius:9px;background:#123b67;color:#fff;text-decoration:none;font-weight:700}.sponsor{margin-top:24px;padding:18px;border:1px solid #d7e4ed;border-radius:14px}.sponsor small{display:block;color:#6c7787;margin-top:8px}table{width:100%;border-collapse:collapse}td,th{text-align:left;padding:12px;border-bottom:1px solid #e6ebf0}footer{margin:60px 0 30px;color:#6c7787;font-size:13px}</style></head><body>';
  echo '<header><a href="/">TechSelectAI</a><nav><a href="/software">Software</a><a href="/methodology">Methodology</a><a href="/">Get Advice</a></nav></header><main>';
}
function page_end(){echo '<footer>TechSelectAI uses evidence-backed product data. Unknown means not yet verified; it does not mean unsupported.</footer></main></body></html>';}
function consultancy_cta($label,$context){echo '<section class="cta"><div class="eyebrow">Independent software advice</div><h2>Need help choosing the right option?</h2><p>Tell TechSelectAI what your company needs and we will evaluate products against your requirements, integrations, deployment constraints and evidence.</p><a href="/?considering='.rawurlencode($context).'">Get independent software advice</a></section>';}
function cardiq_sponsor(){echo '<aside class="sponsor"><div class="eyebrow">Sponsored · Relevant alternative</div><h3>CardIQ</h3><p>Corporate digital identity control with managed business cards, employee verification, signatures, verification and identity lifecycle capabilities.</p><small>CardIQ is a Barmageyat product. Sponsorship does not affect TechSelectAI rankings, methodology or evidence scoring.</small><p><a href="/software/cardiq">Review CardIQ evidence</a></p></aside>';}

if(preg_match('#^/categories/([a-z0-9-]+)$#',$path,$m)){
  $st=$pdo->prepare('SELECT id,name,slug,description FROM categories WHERE slug=? AND is_active=1 LIMIT 1');$st->execute([$m[1]]);$c=$st->fetch();
  if(!$c){http_response_code(404);echo 'Not found';exit;}
  $p=$pdo->prepare("SELECT p.name,p.slug,p.short_description,v.name vendor FROM products p LEFT JOIN vendors v ON v.id=p.vendor_id WHERE p.category_id=? AND p.status='active' ORDER BY p.name");$p->execute([$c['id']]);$products=$p->fetchAll();
  $cap=$pdo->prepare("SELECT DISTINCT cp.name,cp.slug,m.name module FROM capabilities cp JOIN modules m ON m.id=cp.module_id WHERE m.category_id=? AND cp.is_active=1 ORDER BY m.name,cp.name");$cap->execute([$c['id']]);$caps=$cap->fetchAll();
  $desc=$c['description']?:('Compare '.$c['name'].' software using evidence-backed capabilities, limitations and product data.');
  page_start($c['name'].' Software Guide & Comparison | TechSelectAI',$desc,$config['site_url'].'/categories/'.$c['slug'],[['Home','/'],['Categories','/software'],[$c['name'],'/categories/'.$c['slug']]]);
  echo '<div class="eyebrow">Software category</div><h1>'.e($c['name']).'</h1><p class="lead">'.e($desc).'</p>';
  echo '<h2>Products in this category</h2><div class="grid">';foreach($products as $x)echo '<a class="card" href="/software/'.e($x['slug']).'"><div class="eyebrow">'.e($x['vendor']).'</div><h3>'.e($x['name']).'</h3><p>'.e($x['short_description']).'</p></a>';echo '</div>';
  echo '<h2>Capabilities buyers commonly evaluate</h2><div class="grid">';foreach($caps as $x)echo '<a class="card" href="/capabilities/'.e($x['slug']).'"><div class="eyebrow">'.e($x['module']).'</div><h3>'.e($x['name']).'</h3></a>';echo '</div>';
  consultancy_cta($c['name'],$c['name']);
  if(stripos($c['name'],'identity')!==false || stripos($c['name'],'business card')!==false)cardiq_sponsor();
  page_end();exit;
}

if(preg_match('#^/integrations/([a-z0-9-]+)$#',$path,$m)){
  $st=$pdo->prepare('SELECT id,name,slug,description FROM integrations WHERE slug=? LIMIT 1');$st->execute([$m[1]]);$i=$st->fetch();
  if(!$i){http_response_code(404);echo 'Not found';exit;}
  $p=$pdo->prepare("SELECT p.name,p.slug,p.short_description,c.name category,pi.support_status,pi.confidence_score FROM product_integrations pi JOIN products p ON p.id=pi.product_id LEFT JOIN categories c ON c.id=p.category_id WHERE pi.integration_id=? AND p.status='active' ORDER BY CASE pi.support_status WHEN 'supported' THEN 1 WHEN 'partially_supported' THEN 2 WHEN 'not_yet_verified' THEN 3 WHEN 'not_supported' THEN 4 ELSE 5 END,pi.confidence_score DESC,p.name");$p->execute([$i['id']]);$products=$p->fetchAll();
  $desc=$i['description']?:('Compare software support for '.$i['name'].' integration using evidence-backed TechSelectAI data.');
  page_start($i['name'].' Integration Software Comparison | TechSelectAI',$desc,$config['site_url'].'/integrations/'.$i['slug'],[['Home','/'],['Integrations','/software'],[$i['name'],'/integrations/'.$i['slug']]]);
  echo '<div class="eyebrow">Software integration</div><h1>'.e($i['name']).' integration</h1><p class="lead">'.e($desc).' Support status and confidence below come from the same canonical facts used by TechSelectAI recommendations.</p>';
  echo '<h2>Software support</h2><table><thead><tr><th>Product</th><th>Category</th><th>Status</th><th>Confidence</th></tr></thead><tbody>';foreach($products as $x)echo '<tr><td><a href="/software/'.e($x['slug']).'">'.e($x['name']).'</a></td><td>'.e($x['category']).'</td><td><span class="status">'.e(status_label($x['support_status'])).'</span></td><td>'.pct($x['confidence_score']).'%</td></tr>';echo '</tbody></table>';
  echo '<p class="muted">A low confidence score means TechSelectAI has limited verified evidence. It should not be interpreted as proof that the integration is unavailable.</p>';
  consultancy_cta($i['name'],$i['name'].' integration');
  $cardiq=false;foreach($products as $x)if($x['slug']==='cardiq' && in_array($x['support_status'],['supported','partially_supported'],true))$cardiq=true;if($cardiq)cardiq_sponsor();
  page_end();exit;
}

http_response_code(404);echo 'Not found';
