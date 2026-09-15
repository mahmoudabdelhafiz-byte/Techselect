<?php
$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';
if(!preg_match('#^/software/([a-z0-9-]+)/?$#',$path,$m)){http_response_code(404);exit('Not found');}
$slug=$m[1];
ob_start();
require __DIR__.'/customer_outcome_links_page.php';
$html=ob_get_clean();
if(stripos($html,'<html')===false){echo $html;return;}
$esc=htmlspecialchars($slug,ENT_QUOTES,'UTF-8');
$follow='<div class="ts-product-follow ts-product-follow-top" data-product-follow="'.$esc.'"><button type="button" class="btn secondary" aria-pressed="false">Follow product</button><small data-follow-note>Get email updates when this product meaningfully changes.</small></div>';
$alternatives='';
try{
    require_once __DIR__.'/app/lib/Db.php';
    require_once __DIR__.'/app/lib/ComparisonSeoPriority.php';
    require_once __DIR__.'/app/lib/AlternativeSeo.php';
    $altPage=AlternativeSeo::pageForProduct(Db::pdo(),$slug);
    if($altPage){
        $alternatives='<section class="ts-product-alternatives"><div class="eyebrow">Buyer research</div><h2>Compare evidence-qualified alternatives</h2><p>Explore same-category alternatives only when TechSelectAI has fresh verified evidence and enough overlapping known capabilities for a meaningful comparison.</p><a href="/alternatives/'.$esc.'">View '.$esc.' alternatives →</a><small>This is not a ranking and does not change Fit Score or recommendations.</small></section>';
    }
}catch(Throwable $e){}
$section='<section class="ts-partner-discovery" id="verified-partners" data-citation-section="verified-partners"><div class="eyebrow">Local delivery options</div><h2>Find verified vendors & implementation partners</h2><p>See verified resellers, distributors, implementation partners and local agents for this software by country or city. Provider ordering is separate from TechSelectAI software evaluation and fit ranking.</p><a href="/partners?software='.$esc.'">Find verified providers →</a><small>Only reviewed company↔software relationships are shown as verified. Sponsorship cannot change software recommendation scores.</small></section>';
$css='<style id="techselectai-partner-discovery-style">.ts-product-follow-top{display:flex;flex-direction:column;gap:7px}.ts-product-follow-top button{width:100%;cursor:pointer}.ts-product-follow-top button[aria-pressed="true"]{background:#0f766e!important;border-color:#0f766e!important;color:#fff!important}.ts-product-follow-top button:disabled{opacity:.65;cursor:wait}.ts-product-follow-top small{max-width:210px;color:#64748b;font-size:11px;line-height:1.35;text-align:center}.ts-product-alternatives,.ts-partner-discovery{margin-top:34px;padding:24px;border:1px solid #d8e5ec;border-radius:16px;background:#f8fbfd}.ts-product-alternatives h2,.ts-partner-discovery h2{margin:5px 0 8px}.ts-product-alternatives p,.ts-partner-discovery p{color:#64748b;line-height:1.6}.ts-product-alternatives a,.ts-partner-discovery a{display:inline-flex;padding:10px 14px;border:0;border-radius:10px;background:#123b67;color:#fff!important;text-decoration:none;font-weight:750;cursor:pointer}.ts-product-alternatives small,.ts-partner-discovery small{display:block;margin-top:12px;color:#64748b;line-height:1.5}@media(max-width:850px){.ts-product-follow-top{min-width:180px}.ts-product-follow-top small{max-width:240px;text-align:left}}@media(max-width:560px){.ts-product-follow-top{width:100%}.ts-product-follow-top small{max-width:none;text-align:left}}</style><script src="/product_follow.js" defer></script>';
$html=str_ireplace('</head>',$css.'</head>',$html);
if(stripos($html,'<div class="hero-actions">')!==false){
    $html=preg_replace('#<div class="hero-actions">#','<div class="hero-actions">'.$follow,$html,1)??$html;
}else{
    $html=preg_replace('#(<section class="hero"[^>]*>.*?</section>)#is','$1'.$follow,$html,1)??$html;
}
$html=preg_replace('#<section class="cta">#',$alternatives.$section.'<section class="cta">',$html,1)??$html;
echo $html;
