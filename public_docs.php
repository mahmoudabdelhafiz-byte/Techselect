<?php
require_once __DIR__.'/app/lib/Db.php';
$config=require __DIR__.'/app/config.php';
$pdo=Db::pdo();
$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';
function e($v){return htmlspecialchars((string)$v,ENT_QUOTES,'UTF-8');}
function status_label($v){return ucwords(str_replace('_',' ',(string)$v));}
function pct($v){return (int)round(((float)$v)*100);}
function page_start($title,$description,$canonical,$breadcrumb,$extraJsonLd=null){
  global $config;
  $safeTitle=e($title);$safeDescription=e($description);$safeCanonical=e($canonical);
  $crumb=['@context'=>'https://schema.org','@type'=>'BreadcrumbList','itemListElement'=>[]];
  foreach($breadcrumb as $i=>$b)$crumb['itemListElement'][]=['@type'=>'ListItem','position'=>$i+1,'name'=>$b[0],'item'=>$config['site_url'].$b[1]];
  echo '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">';
  echo '<title>'.$safeTitle.'</title><meta name="description" content="'.$safeDescription.'"><link rel="canonical" href="'.$safeCanonical.'">';
  echo '<meta property="og:type" content="website"><meta property="og:title" content="'.$safeTitle.'"><meta property="og:description" content="'.$safeDescription.'"><meta property="og:url" content="'.$safeCanonical.'">';
  echo '<script type="application/ld+json">'.json_encode($crumb,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE).'</script>';
  if($extraJsonLd)echo '<script type="application/ld+json">'.json_encode($extraJsonLd,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE).'</script>';
  echo '<style>body{font-family:Inter,Arial,sans-serif;margin:0;color:#172033;background:#fff}header{display:flex;justify-content:space-between;align-items:center;padding:18px max(24px,5vw);border-bottom:1px solid #e7ebf0}header a{color:#123b67;text-decoration:none;font-weight:700}nav a{margin-left:18px;font-weight:600}main{max-width:1120px;margin:42px auto;padding:0 24px}h1{font-size:clamp(34px,5vw,56px);line-height:1.05;margin:8px 0 16px}h2{margin-top:38px}.eyebrow{font-size:13px;text-transform:uppercase;letter-spacing:.08em;color:#42627f;font-weight:700}.lead{font-size:19px;line-height:1.7;color:#4b596c;max-width:850px}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(250px,1fr));gap:16px}.card{display:block;border:1px solid #dfe6ee;border-radius:14px;padding:18px;text-decoration:none;color:inherit;background:#fff}.card:hover{border-color:#8ca8c1}.status{display:inline-block;padding:4px 9px;border-radius:999px;background:#eef4f8;font-size:12px}.muted{color:#6c7787}.warning{color:#8a4b13}.cta{margin-top:40px;padding:24px;border-radius:16px;background:#f3f8fb;border:1px solid #d7e4ed}.cta a{display:inline-block;margin-top:8px;padding:11px 16px;border-radius:9px;background:#123b67;color:#fff;text-decoration:none;font-weight:700}.sponsor{margin-top:24px;padding:18px;border:1px solid #d7e4ed;border-radius:14px}.sponsor small{display:block;color:#6c7787;margin-top:8px}table{width:100%;border-collapse:collapse}td,th{text-align:left;padding:12px;border-bottom:1px solid #e6ebf0;vertical-align:top}footer{margin:60px 0 30px;color:#6c7787;font-size:13px}</style></head><body>';
  echo '<header><a href="/">TechSelectAI</a><nav><a href="/software">Software</a><a href="/methodology">Methodology</a><a href="/">Get Advice</a></nav></header><main>';
}
function page_end(){echo '<footer>TechSelectAI uses evidence-backed product data. Unknown means not yet verified; it does not mean unsupported.</footer></main></body></html>';}
function consultancy_cta($context){echo '<section class="cta"><div class="eyebrow">Independent software advice</div><h2>Need help choosing the right option?</h2><p>Tell TechSelectAI what your company needs and we will evaluate products against your requirements, integrations, deployment constraints and evidence.</p><a href="/?considering='.rawurlencode($context).'">Get independent software advice</a></section>';}
function cardiq_sponsor(){echo '<aside class="sponsor"><div class="eyebrow">Sponsored · Relevant alternative</div><h3>CardIQ</h3><p>Corporate digital identity control with managed business cards, employee verification, signatures, verification and identity lifecycle capabilities.</p><small>CardIQ is a Barmageyat product. Sponsorship does not affect TechSelectAI rankings, methodology or evidence scoring.</small><p><a href="/software/cardiq">Review CardIQ evidence</a></p></aside>';}
function not_found(){http_response_code(404);echo 'Not found';exit;}

if(preg_match('#^/software/([a-z0-9-]+)$#',$path,$m)){
  $st=$pdo->prepare("SELECT p.*,v.name vendor,c.name category,c.slug category_slug FROM products p LEFT JOIN vendors v ON v.id=p.vendor_id LEFT JOIN categories c ON c.id=p.category_id WHERE p.slug=? AND p.status='active' LIMIT 1");$st->execute([$m[1]]);$p=$st->fetch();if(!$p)not_found();
  $q=$pdo->prepare("SELECT cap.name,cap.slug,mo.name module,pc.support_status,pc.limitations,pc.confidence_score,pc.last_verified_at FROM product_capabilities pc JOIN capabilities cap ON cap.id=pc.capability_id JOIN modules mo ON mo.id=cap.module_id WHERE pc.product_id=? AND pc.edition_id IS NULL ORDER BY mo.name,cap.name");$q->execute([$p['id']]);$caps=$q->fetchAll();
  $q=$pdo->prepare("SELECT i.name,i.slug,pi.support_status,pi.confidence_score FROM product_integrations pi JOIN integrations i ON i.id=pi.integration_id WHERE pi.product_id=? ORDER BY i.name");$q->execute([$p['id']]);$ints=$q->fetchAll();
  $q=$pdo->prepare("SELECT d.name,d.slug,pd.support_status,pd.confidence_score FROM product_deployments pd JOIN deployment_models d ON d.id=pd.deployment_model_id WHERE pd.product_id=? ORDER BY d.name");$q->execute([$p['id']]);$deps=$q->fetchAll();
  $q=$pdo->prepare("SELECT source_title,source_url,source_type,verification_status,confidence,checked_at FROM evidence_sources WHERE product_id=? ORDER BY checked_at DESC");$q->execute([$p['id']]);$evidence=$q->fetchAll();
  $q=$pdo->prepare("SELECT p2.name,p2.slug FROM products p2 WHERE p2.category_id=? AND p2.id<>? AND p2.status='active' ORDER BY p2.name LIMIT 6");$q->execute([$p['category_id'],$p['id']]);$alts=$q->fetchAll();
  $desc=$p['short_description']?:('Evidence-backed review of '.$p['name'].' capabilities, integrations, deployment options and limitations.');
  $softwareLd=['@context'=>'https://schema.org','@type'=>'SoftwareApplication','name'=>$p['name'],'applicationCategory'=>$p['category'],'url'=>$config['site_url'].'/software/'.$p['slug'],'description'=>$desc];
  page_start($p['name'].' Review, Capabilities & Evidence | TechSelectAI',$desc,$config['site_url'].'/software/'.$p['slug'],[['Home','/'],['Software','/software'],[$p['name'],'/software/'.$p['slug']]],$softwareLd);
  echo '<div class="eyebrow">'.e($p['category']).' · '.e($p['vendor']).'</div><h1>'.e($p['name']).'</h1><p class="lead">'.e($desc).'</p>';
  if($p['category_slug'])echo '<p><a href="/categories/'.e($p['category_slug']).'">Browse '.e($p['category']).' software</a></p>';
  echo '<h2>Capabilities</h2><table><thead><tr><th>Capability</th><th>Module</th><th>Status</th><th>Confidence</th><th>Last verified</th></tr></thead><tbody>';
  foreach($caps as $x)echo '<tr><td><a href="/capabilities/'.e($x['slug']).'">'.e($x['name']).'</a>'.($x['limitations']?'<br><span class="muted">'.e($x['limitations']).'</span>':'').'</td><td>'.e($x['module']).'</td><td><span class="status">'.e(status_label($x['support_status'])).'</span></td><td>'.pct($x['confidence_score']).'%</td><td>'.e($x['last_verified_at']?:'Not recorded').'</td></tr>';echo '</tbody></table>';
  if($ints){echo '<h2>Integrations</h2><div class="grid">';foreach($ints as $x)echo '<a class="card" href="/integrations/'.e($x['slug']).'"><h3>'.e($x['name']).'</h3><p>'.e(status_label($x['support_status'])).' · '.pct($x['confidence_score']).'% confidence</p></a>';echo '</div>';}
  if($deps){echo '<h2>Deployment</h2><div class="grid">';foreach($deps as $x)echo '<div class="card"><h3>'.e($x['name']).'</h3><p>'.e(status_label($x['support_status'])).' · '.pct($x['confidence_score']).'% confidence</p></div>';echo '</div>';}
  echo '<h2>Evidence sources</h2>';if($evidence){foreach($evidence as $x)echo '<p><a href="'.e($x['source_url']).'" rel="nofollow noopener" target="_blank">'.e($x['source_title']).'</a> · '.e(status_label($x['verification_status'])).' · checked '.e($x['checked_at']).'</p>';}else echo '<p class="muted">No published evidence sources are available yet.</p>';
  if($alts){echo '<h2>Related alternatives</h2><div class="grid">';foreach($alts as $x){$pair=[$p['slug'],$x['slug']];sort($pair,SORT_STRING);$compare=implode('-vs-',$pair);echo '<div class="card"><h3><a href="/software/'.e($x['slug']).'">'.e($x['name']).'</a></h3><p><a href="/compare/'.e($compare).'">Compare '.e($p['name']).' vs '.e($x['name']).'</a></p></div>';}echo '</div>';}
  consultancy_cta($p['name']);
  if($p['slug']!=='cardiq' && (stripos((string)$p['category'],'identity')!==false || stripos((string)$p['category'],'business card')!==false))cardiq_sponsor();
  page_end();exit;
}

if(preg_match('#^/capabilities/([a-z0-9-]+)$#',$path,$m)){
  $st=$pdo->prepare("SELECT c.id,c.name,c.slug,c.description,mo.name module,cat.name category,cat.slug category_slug FROM capabilities c JOIN modules mo ON mo.id=c.module_id JOIN categories cat ON cat.id=mo.category_id WHERE c.slug=? AND c.is_active=1 LIMIT 1");$st->execute([$m[1]]);$c=$st->fetch();if(!$c)not_found();
  $q=$pdo->prepare("SELECT p.name,p.slug,pc.support_status,pc.confidence_score,pc.limitations,pc.last_verified_at FROM product_capabilities pc JOIN products p ON p.id=pc.product_id WHERE pc.capability_id=? AND pc.edition_id IS NULL AND p.status='active' ORDER BY CASE pc.support_status WHEN 'supported' THEN 1 WHEN 'partially_supported' THEN 2 WHEN 'not_yet_verified' THEN 3 WHEN 'not_supported' THEN 4 ELSE 5 END,pc.confidence_score DESC,p.name");$q->execute([$c['id']]);$products=$q->fetchAll();
  $desc=$c['description']?:('Compare software support for '.$c['name'].' using evidence-backed TechSelectAI data.');
  page_start($c['name'].' Software Capability Comparison | TechSelectAI',$desc,$config['site_url'].'/capabilities/'.$c['slug'],[['Home','/'],['Categories','/categories/'.$c['category_slug']],[$c['name'],'/capabilities/'.$c['slug']]]);
  echo '<div class="eyebrow">'.e($c['category']).' · '.e($c['module']).'</div><h1>'.e($c['name']).'</h1><p class="lead">'.e($desc).'</p>';
  echo '<h2>Product support</h2><table><thead><tr><th>Product</th><th>Status</th><th>Confidence</th><th>Limitations</th><th>Last verified</th></tr></thead><tbody>';
  foreach($products as $x)echo '<tr><td><a href="/software/'.e($x['slug']).'">'.e($x['name']).'</a></td><td><span class="status">'.e(status_label($x['support_status'])).'</span></td><td>'.pct($x['confidence_score']).'%</td><td>'.e($x['limitations']).'</td><td>'.e($x['last_verified_at']?:'Not recorded').'</td></tr>';echo '</tbody></table>';
  echo '<p class="muted">Unknown or not yet verified means TechSelectAI does not currently have enough verified evidence. It is not the same as not supported.</p>';
  consultancy_cta($c['name']);
  page_end();exit;
}

if(preg_match('#^/compare/([a-z0-9-]+)-vs-([a-z0-9-]+)$#',$path,$m)){
  $requested=[$m[1],$m[2]];$canonical=$requested;sort($canonical,SORT_STRING);$canonicalSlug=implode('-vs-',$canonical);
  if($canonicalSlug!==$m[1].'-vs-'.$m[2]){header('Location: '.$config['site_url'].'/compare/'.$canonicalSlug,true,301);exit;}
  $st=$pdo->prepare("SELECT p.id,p.name,p.slug,p.short_description,c.name category FROM products p LEFT JOIN categories c ON c.id=p.category_id WHERE p.slug IN (?,?) AND p.status='active'");$st->execute($canonical);$products=$st->fetchAll();if(count($products)!==2)not_found();
  usort($products,fn($a,$b)=>array_search($a['slug'],$canonical,true)<=>array_search($b['slug'],$canonical,true));$ids=array_column($products,'id');
  $q=$pdo->prepare("SELECT pc.product_id,c.name,c.slug,mo.name module,pc.support_status,pc.confidence_score,pc.limitations FROM product_capabilities pc JOIN capabilities c ON c.id=pc.capability_id JOIN modules mo ON mo.id=c.module_id WHERE pc.product_id IN (?,?) AND pc.edition_id IS NULL ORDER BY mo.name,c.name,pc.product_id");$q->execute($ids);$facts=$q->fetchAll();
  $matrix=[];foreach($facts as $f){$key=$f['slug'];if(!isset($matrix[$key]))$matrix[$key]=['name'=>$f['name'],'module'=>$f['module'],'rows'=>[]];$matrix[$key]['rows'][$f['product_id']]=$f;}
  $a=$products[0];$b=$products[1];$desc='Evidence-backed comparison of '.$a['name'].' and '.$b['name'].' across capabilities, confidence and known limitations.';
  page_start($a['name'].' vs '.$b['name'].' | TechSelectAI',$desc,$config['site_url'].'/compare/'.$canonicalSlug,[['Home','/'],['Software','/software'],[$a['name'].' vs '.$b['name'],'/compare/'.$canonicalSlug]]);
  echo '<div class="eyebrow">Evidence-backed software comparison</div><h1>'.e($a['name']).' vs '.e($b['name']).'</h1><p class="lead">'.e($desc).'</p>';
  echo '<table><thead><tr><th>Capability</th><th>'.e($a['name']).'</th><th>'.e($b['name']).'</th></tr></thead><tbody>';
  foreach($matrix as $x){$ra=$x['rows'][$a['id']]??null;$rb=$x['rows'][$b['id']]??null;echo '<tr><td>'.e($x['module']).' · <a href="/capabilities/'.e($ra['slug']??$rb['slug']).'">'.e($x['name']).'</a></td><td>'.($ra?e(status_label($ra['support_status'])).' · '.pct($ra['confidence_score']).'%':'Not yet verified').'</td><td>'.($rb?e(status_label($rb['support_status'])).' · '.pct($rb['confidence_score']).'%':'Not yet verified').'</td></tr>';}
  echo '</tbody></table><p class="muted">This comparison reports recorded evidence status. It does not replace a requirements-based recommendation.</p>';
  consultancy_cta($a['name'].' vs '.$b['name']);
  page_end();exit;
}

if(preg_match('#^/categories/([a-z0-9-]+)$#',$path,$m)){
  $st=$pdo->prepare('SELECT id,name,slug,description FROM categories WHERE slug=? AND is_active=1 LIMIT 1');$st->execute([$m[1]]);$c=$st->fetch();if(!$c)not_found();
  $p=$pdo->prepare("SELECT p.name,p.slug,p.short_description,v.name vendor FROM products p LEFT JOIN vendors v ON v.id=p.vendor_id WHERE p.category_id=? AND p.status='active' ORDER BY p.name");$p->execute([$c['id']]);$products=$p->fetchAll();
  $cap=$pdo->prepare("SELECT DISTINCT cp.name,cp.slug,mo.name module FROM capabilities cp JOIN modules mo ON mo.id=cp.module_id WHERE mo.category_id=? AND cp.is_active=1 ORDER BY mo.name,cp.name");$cap->execute([$c['id']]);$caps=$cap->fetchAll();
  $desc=$c['description']?:('Compare '.$c['name'].' software using evidence-backed capabilities, limitations and product data.');
  page_start($c['name'].' Software Guide & Comparison | TechSelectAI',$desc,$config['site_url'].'/categories/'.$c['slug'],[['Home','/'],['Categories','/software'],[$c['name'],'/categories/'.$c['slug']]]);
  echo '<div class="eyebrow">Software category</div><h1>'.e($c['name']).'</h1><p class="lead">'.e($desc).'</p><h2>Products in this category</h2><div class="grid">';foreach($products as $x)echo '<a class="card" href="/software/'.e($x['slug']).'"><div class="eyebrow">'.e($x['vendor']).'</div><h3>'.e($x['name']).'</h3><p>'.e($x['short_description']).'</p></a>';echo '</div><h2>Capabilities buyers commonly evaluate</h2><div class="grid">';foreach($caps as $x)echo '<a class="card" href="/capabilities/'.e($x['slug']).'"><div class="eyebrow">'.e($x['module']).'</div><h3>'.e($x['name']).'</h3></a>';echo '</div>';consultancy_cta($c['name']);if(stripos($c['name'],'identity')!==false||stripos($c['name'],'business card')!==false)cardiq_sponsor();page_end();exit;
}

if(preg_match('#^/integrations/([a-z0-9-]+)$#',$path,$m)){
  $st=$pdo->prepare('SELECT id,name,slug,description FROM integrations WHERE slug=? LIMIT 1');$st->execute([$m[1]]);$i=$st->fetch();if(!$i)not_found();
  $p=$pdo->prepare("SELECT p.name,p.slug,p.short_description,c.name category,pi.support_status,pi.confidence_score FROM product_integrations pi JOIN products p ON p.id=pi.product_id LEFT JOIN categories c ON c.id=p.category_id WHERE pi.integration_id=? AND p.status='active' ORDER BY CASE pi.support_status WHEN 'supported' THEN 1 WHEN 'partially_supported' THEN 2 WHEN 'not_yet_verified' THEN 3 WHEN 'not_supported' THEN 4 ELSE 5 END,pi.confidence_score DESC,p.name");$p->execute([$i['id']]);$products=$p->fetchAll();
  $desc=$i['description']?:('Compare software support for '.$i['name'].' integration using evidence-backed TechSelectAI data.');
  page_start($i['name'].' Integration Software Comparison | TechSelectAI',$desc,$config['site_url'].'/integrations/'.$i['slug'],[['Home','/'],['Integrations','/software'],[$i['name'],'/integrations/'.$i['slug']]]);
  echo '<div class="eyebrow">Software integration</div><h1>'.e($i['name']).' integration</h1><p class="lead">'.e($desc).' Support status and confidence below come from the same canonical facts used by TechSelectAI recommendations.</p><h2>Software support</h2><table><thead><tr><th>Product</th><th>Category</th><th>Status</th><th>Confidence</th></tr></thead><tbody>';foreach($products as $x)echo '<tr><td><a href="/software/'.e($x['slug']).'">'.e($x['name']).'</a></td><td>'.e($x['category']).'</td><td><span class="status">'.e(status_label($x['support_status'])).'</span></td><td>'.pct($x['confidence_score']).'%</td></tr>';echo '</tbody></table><p class="muted">A low confidence score means TechSelectAI has limited verified evidence. It should not be interpreted as proof that the integration is unavailable.</p>';consultancy_cta($i['name'].' integration');$cardiq=false;foreach($products as $x)if($x['slug']==='cardiq'&&in_array($x['support_status'],['supported','partially_supported'],true))$cardiq=true;if($cardiq)cardiq_sponsor();page_end();exit;
}

not_found();
