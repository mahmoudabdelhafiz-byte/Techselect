<?php
/**
 * Final crawlability wrapper for public knowledge pages.
 * Injects canonical/search metadata and public conversion tracking without changing scoring/recommendations.
 */
$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';
$target=null;
if(preg_match('#^/software/[a-z0-9-]+/?$#',$path)) $target='partner_links_page.php';
elseif(preg_match('#^/categories/[a-z0-9-]+/?$#',$path)) $target='customer_outcome_links_page.php';
elseif(preg_match('#^/capabilities/[a-z0-9-]+/?$#',$path)) $target='brand_page.php';
elseif(preg_match('#^/integrations/[a-z0-9-]+/?$#',$path)) $target='brand_page.php';
elseif(preg_match('#^/compare/[a-z0-9-]+-vs-[a-z0-9-]+/?$#',$path)) $target='contextual_comparison_page.php';
if(!$target){http_response_code(404);exit('Not found');}

ob_start();require __DIR__.'/'.$target;$html=ob_get_clean();
if(stripos($html,'<html')===false||stripos($html,'<head')===false){echo $html;return;}

$config=require __DIR__.'/app/config.php';
$base=rtrim((string)($config['site_url']??'https://techselectai.com'),'/');
$canonicalPath=preg_replace('#/+$#','',$path)?:'/';
if($canonicalPath==='')$canonicalPath='/';
$canonical=$base.($canonicalPath==='/'?'/':$canonicalPath);

$html=preg_replace('#<link\s+[^>]*rel=["\']canonical["\'][^>]*>#i','',$html)??$html;
$meta='<link rel="canonical" href="'.htmlspecialchars($canonical,ENT_QUOTES,'UTF-8').'">'
     .'<meta name="robots" content="index,follow,max-snippet:-1,max-image-preview:large,max-video-preview:-1">'
     .'<meta name="googlebot" content="index,follow,max-snippet:-1,max-image-preview:large,max-video-preview:-1">'
     .'<meta name="bingbot" content="index,follow,max-snippet:-1,max-image-preview:large,max-video-preview:-1">';
$html=str_ireplace('</head>',$meta.'</head>',$html);

// Measure contextual decision-journey CTA exposure/clicks. This analytics layer is separate from ranking/scoring.
$tracking='<script id="ts-public-conversion-tracking">(()=>{const source='.json_encode($canonicalPath,JSON_UNESCAPED_SLASHES).';const cta=[...document.querySelectorAll("section.cta a.btn, section.cta a[href^=\"/?\"]")][0];if(!cta)return;cta.dataset.tsConversionCta="selection_journey";const send=(eventType)=>{const body=JSON.stringify({event_type:eventType,source_path:source,destination_path:cta.getAttribute("href")||"",cta_id:"selection_journey"});try{if(navigator.sendBeacon){navigator.sendBeacon("/api/public-conversion",new Blob([body],{type:"application/json"}));return;}fetch("/api/public-conversion",{method:"POST",headers:{"Content-Type":"application/json"},body,keepalive:true,credentials:"same-origin"}).catch(()=>{});}catch(e){}};if(!sessionStorage.getItem("ts_cta_seen:"+source)){sessionStorage.setItem("ts_cta_seen:"+source,"1");send("cta_impression");}cta.addEventListener("click",()=>send("cta_click"),{passive:true});})();</script>';
$html=str_ireplace('</body>',$tracking.'</body>',$html);

try{
    require_once __DIR__.'/app/lib/Db.php';
    require_once __DIR__.'/app/lib/LongTailSeoLinks.php';
    $related=LongTailSeoLinks::forPath(Db::pdo(),$canonicalPath,6);
    if($related){
        $links='<section data-generated-related-guides style="max-width:1180px;margin:28px auto;padding:20px 22px"><div style="border:1px solid #dfe6ee;border-radius:14px;padding:18px;background:#fff"><h2 style="margin-top:0">Related decision guides</h2><p style="color:#64748b">Evidence-backed buyer-intent guides that passed TechSelectAI\'s programmatic SEO quality gate.</p><ul>';
        foreach($related as $r)$links.='<li style="margin:8px 0"><a href="'.htmlspecialchars($r['canonical_path'],ENT_QUOTES,'UTF-8').'">'.htmlspecialchars($r['title'],ENT_QUOTES,'UTF-8').'</a></li>';
        $links.='</ul></div></section>';
        $html=str_ireplace('</body>',$links.'</body>',$html);
    }
}catch(Throwable $e){}

echo $html;
