<?php
/**
 * Inject approved customer outcomes into public product/category/comparison pages.
 * Customer proof remains separate from scoring, reviews and recommendation ranking.
 */
$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';
$target=null;
if(preg_match('#^/software/[a-z0-9-]+/?$#',$path)) $target='knowledge_page.php';
elseif(preg_match('#^/categories/[a-z0-9-]+/?$#',$path)) $target='brand_page.php';
elseif(preg_match('#^/compare/[a-z0-9-]+-vs-[a-z0-9-]+/?$#',$path)) $target='knowledge_page.php';
if(!$target){http_response_code(404);exit('Not found');}

ob_start();
require __DIR__.'/'.$target;
$html=ob_get_clean();
if(stripos($html,'<html')===false){echo $html;return;}

try{
  require_once __DIR__.'/app/lib/Db.php';
  require_once __DIR__.'/app/lib/CustomerOutcomes.php';
  $pdo=Db::pdo();
  $all=CustomerOutcomes::publicList($pdo);
  $related=[];

  if(preg_match('#^/software/([a-z0-9-]+)/?$#',$path,$m)){
    foreach($all as $row){if(($row['product_slug']??null)===$m[1])$related[]=$row;}
  }elseif(preg_match('#^/categories/([a-z0-9-]+)/?$#',$path,$m)){
    $productSlugs=[];
    $st=$pdo->prepare("SELECT p.slug FROM products p JOIN categories c ON c.id=p.category_id WHERE c.slug=? AND c.is_active=1 AND p.status='active'");
    $st->execute([$m[1]]);
    foreach($st->fetchAll() as $r)$productSlugs[(string)$r['slug']]=true;
    foreach($all as $row){
      if(($row['category_slug']??null)===$m[1] || isset($productSlugs[(string)($row['product_slug']??'')]))$related[]=$row;
    }
  }elseif(preg_match('#^/compare/([a-z0-9-]+)-vs-([a-z0-9-]+)/?$#',$path,$m)){
    $wanted=[$m[1]=>true,$m[2]=>true];
    foreach($all as $row){if(isset($wanted[(string)($row['product_slug']??'')]))$related[]=$row;}
  }

  if($related){
    $related=array_slice($related,0,3);
    $esc=static fn($v)=>htmlspecialchars((string)$v,ENT_QUOTES,'UTF-8');
    $cards='';
    foreach($related as $row){
      $label=CustomerOutcomes::publicCustomerLabel($row);
      $context=array_values(array_filter([$row['product_name']??null,$row['category_name']??null]));
      $summary=trim((string)($row['summary']??''));
      if($summary==='')$summary=trim((string)($row['problem']??''));
      $outcome=trim((string)($row['measurable_outcome']??''));
      $cards.='<article class="ts-outcome-card"><div class="eyebrow">Verified customer outcome</div><h3><a href="/case-studies/'.$esc($row['slug']).'">'.$esc($row['title']).'</a></h3><div class="ts-outcome-meta">'.$esc($label).($context?' · '.$esc(implode(' · ',$context)):'').(!empty($row['outcome_date'])?' · '.$esc($row['outcome_date']):'').'</div>';
      if($summary!=='')$cards.='<p>'.$esc($summary).'</p>';
      if($outcome!=='')$cards.='<div class="ts-outcome-result"><strong>Measured outcome:</strong> '.$esc($outcome).'</div>';
      $cards.='<a class="ts-outcome-link" href="/case-studies/'.$esc($row['slug']).'">Read the verified outcome →</a></article>';
    }
    $section='<section class="ts-customer-outcomes" id="customer-outcomes" data-citation-section="customer-outcomes"><div class="eyebrow">Real-world proof</div><h2>Related customer outcomes</h2><p class="ts-outcome-intro">Approved TechSelectAI case studies connected to this decision context. Customer outcomes are evidence of real use, not recommendation scores or vendor marketing claims.</p><div class="ts-outcome-grid">'.$cards.'</div><p class="ts-outcome-note">Only verified, explicitly approved and published outcomes appear here. Anonymous case studies remain anonymized.</p></section>';
    $css='<style id="techselectai-customer-outcomes-style">.ts-customer-outcomes{margin-top:38px;padding:24px;border:1px solid #d8e5ec;border-radius:16px;background:#fbfdfe}.ts-customer-outcomes h2{margin:5px 0 7px;font-size:28px}.ts-outcome-intro,.ts-outcome-note{color:#64748b;line-height:1.6}.ts-outcome-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(250px,1fr));gap:14px;margin-top:18px}.ts-outcome-card{padding:17px;border:1px solid #e2e8f0;border-radius:14px;background:#fff}.ts-outcome-card h3{margin:5px 0 6px;font-size:18px}.ts-outcome-card p{color:#536174;line-height:1.55}.ts-outcome-meta{font-size:12px;color:#64748b;line-height:1.5}.ts-outcome-result{margin-top:12px;padding:10px 12px;border-radius:10px;background:#f1f7fa;color:#334155;line-height:1.5;font-size:13px}.ts-outcome-link{display:inline-block;margin-top:12px;font-weight:750;text-decoration:none}.ts-outcome-note{font-size:12px;margin:15px 0 0}@media(max-width:560px){.ts-customer-outcomes{padding:18px}}</style>';
    $html=str_ireplace('</head>',$css.'</head>',$html);
    $html=preg_replace('#<section class="cta">#',$section.'<section class="cta">',$html,1)??$html;
  }
}catch(Throwable $e){
  // Customer-outcome migration may not be deployed yet; public knowledge pages must remain available.
}

echo $html;
