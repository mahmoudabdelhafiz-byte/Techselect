<?php
$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';
if(!preg_match('#^/software/([a-z0-9-]+)/?$#',$path,$m)){http_response_code(404);exit('Not found');}
$slug=$m[1];
ob_start();
require __DIR__.'/customer_outcome_links_page.php';
$html=ob_get_clean();
if(stripos($html,'<html')===false){echo $html;return;}
$esc=htmlspecialchars($slug,ENT_QUOTES,'UTF-8');
$follow='<section class="ts-product-follow" data-product-follow="'.$esc.'"><div class="eyebrow">Product updates</div><h2>Follow this product</h2><p data-follow-note>Get email updates when this researched product profile meaningfully changes.</p><button type="button" aria-pressed="false">Follow product</button><small>Following never affects TechSelectAI ranking, Fit Score, or recommendations. You can unfollow at any time.</small></section>';
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
$css='<style id="techselectai-partner-discovery-style">.ts-product-follow,.ts-product-alternatives,.ts-partner-discovery{margin-top:34px;padding:24px;border:1px solid #d8e5ec;border-radius:16px;background:#f8fbfd}.ts-product-follow h2,.ts-product-alternatives h2,.ts-partner-discovery h2{margin:5px 0 8px}.ts-product-follow p,.ts-product-alternatives p,.ts-partner-discovery p{color:#64748b;line-height:1.6}.ts-product-follow button,.ts-product-alternatives a,.ts-partner-discovery a{display:inline-flex;padding:10px 14px;border:0;border-radius:10px;background:#123b67;color:#fff!important;text-decoration:none;font-weight:750;cursor:pointer}.ts-product-follow button[aria-pressed="true"]{background:#0f766e}.ts-product-follow button:disabled{opacity:.65;cursor:wait}.ts-product-follow small,.ts-product-alternatives small,.ts-partner-discovery small{display:block;margin-top:12px;color:#64748b;line-height:1.5}</style><script src="/product_follow.js" defer></script>';
$html=str_ireplace('</head>',$css.'</head>',$html);
$html=preg_replace('#<section class="cta">#',$follow.$alternatives.$section.'<section class="cta">',$html,1)??$html;
echo $html;
