<?php
/**
 * Final crawlability wrapper for public knowledge pages.
 * Injects canonical/search metadata, optional admin-managed advertising, and public conversion tracking without changing scoring/recommendations.
 */
$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';
$target=null;$pageType=null;
if(preg_match('#^/software/[a-z0-9-]+/?$#',$path)){ $target='partner_links_page.php';$pageType='software'; }
elseif(preg_match('#^/categories/[a-z0-9-]+/?$#',$path)){ $target='customer_outcome_links_page.php';$pageType='category'; }
elseif(preg_match('#^/capabilities/[a-z0-9-]+/?$#',$path)){ $target='brand_page.php';$pageType='capability'; }
elseif(preg_match('#^/integrations/[a-z0-9-]+/?$#',$path)){ $target='brand_page.php';$pageType='integration'; }
elseif(preg_match('#^/compare/[a-z0-9-]+-vs-[a-z0-9-]+/?$#',$path)){ $target='contextual_comparison_page.php';$pageType='comparison'; }
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

// Optional AdSense Auto Ads loader. Configuration is display-only and never participates in scoring or recommendations.
try{
    require_once __DIR__.'/app/lib/Db.php';
    require_once __DIR__.'/app/lib/AdvertisingSettings.php';
    $meta.=AdvertisingSettings::headScript(Db::pdo(),(string)$pageType);
}catch(Throwable $e){}
$html=str_ireplace('</head>',$meta.'</head>',$html);

// Measure contextual decision-journey CTA exposure/clicks. This analytics layer is separate from ranking/scoring.
$tracking='<script id="ts-public-conversion-tracking">(()=>{const source='.json_encode($canonicalPath,JSON_UNESCAPED_SLASHES).';const cta=[...document.querySelectorAll("section.cta a.btn, section.cta a[href^=\"/?\"]")][0];if(!cta)return;cta.dataset.tsConversionCta="selection_journey";const send=(eventType)=>{const body=JSON.stringify({event_type:eventType,source_path:source,destination_path:cta.getAttribute("href")||"",cta_id:"selection_journey"});try{if(navigator.sendBeacon){navigator.sendBeacon("/api/public-conversion",new Blob([body],{type:"application/json"}));return;}fetch("/api/public-conversion",{method:"POST",headers:{"Content-Type":"application/json"},body,keepalive:true,credentials:"same-origin"}).catch(()=>{});}catch(e){}};if(!sessionStorage.getItem("ts_cta_seen:"+source)){sessionStorage.setItem("ts_cta_seen:"+source,"1");send("cta_impression");}cta.addEventListener("click",()=>send("cta_click"),{passive:true});})();</script>';
$html=str_ireplace('</body>',$tracking.'</body>',$html);

try{
    require_once __DIR__.'/app/lib/LongTailSeoLinks.php';
    $related=LongTailSeoLinks::forPath(Db::pdo(),$canonicalPath,6);
    if($related){
        $links='<section data-generated-related-guides style="max-width:1180px;margin:28px auto;padding:20px 22px"><div style="border:1px solid #dfe6ee;border-radius:14px;padding:18px;background:#fff"><h2 style="margin-top:0">Related decision guides</h2><p style="color:#64748b">Evidence-backed buyer-intent guides that passed TechSelectAI\'s programmatic SEO quality gate.</p><ul>';
        foreach($related as $r)$links.='<li style="margin:8px 0"><a href="'.htmlspecialchars($r['canonical_path'],ENT_QUOTES,'UTF-8').'">'.htmlspecialchars($r['title'],ENT_QUOTES,'UTF-8').'</a></li>';
        $links.='</ul></div></section>';
        $html=str_ireplace('</body>',$links.'</body>',$html);
    }
}catch(Throwable $e){}

// Curated comparison links: only evidence-ready buyer-intent pairs are surfaced. This improves
// discovery without generating arbitrary N×N links or changing any product/recommendation score.
try{
    require_once __DIR__.'/app/lib/ComparisonSeoPriority.php';
    $pdo=Db::pdo();$cmpLinks=[];
    if(preg_match('#^/software/([a-z0-9-]+)$#',$canonicalPath,$cm)){
        $cmpLinks=ComparisonSeoPriority::linksForProduct($pdo,$cm[1],4);
    }elseif(preg_match('#^/categories/([a-z0-9-]+)$#',$canonicalPath,$cm)){
        $cmpLinks=ComparisonSeoPriority::linksForCategory($pdo,$cm[1],6);
    }
    if($cmpLinks){
        $section='<section data-priority-comparisons style="max-width:1180px;margin:28px auto;padding:0 22px"><div style="border:1px solid #dfe6ee;border-radius:14px;padding:18px;background:#f8fbfd"><h2 style="margin:0 0 6px">Evidence-ready comparisons</h2><p style="margin:0 0 12px;color:#64748b">High-intent product comparisons are listed only when both products meet TechSelectAI evidence-depth and freshness gates.</p><ul style="margin:0;padding-left:20px">';
        foreach($cmpLinks as $c){$names=array_map(static fn($p)=>$p['name'],$c['products']);$section.='<li style="margin:8px 0"><a href="'.htmlspecialchars($c['path'],ENT_QUOTES,'UTF-8').'">'.htmlspecialchars(implode(' vs ',$names),ENT_QUOTES,'UTF-8').'</a> <span style="color:#64748b">— '.htmlspecialchars($c['buyer_intent'],ENT_QUOTES,'UTF-8').'</span></li>';}
        $section.='</ul></div></section>';
        $html=str_ireplace('</body>',$section.'</body>',$html);
    }

    // Preserve the already-ranking Blinq/CardIQ page byte-for-byte at the comparison-content
    // level. New priority comparisons receive a compact interpretation block only after readiness.
    if(preg_match('#^/compare/([a-z0-9-]+)-vs-([a-z0-9-]+)$#',$canonicalPath,$cm)&&!ComparisonSeoPriority::isProtected($cm[1],$cm[2])){
        $cmp=ComparisonSeoPriority::find($pdo,$cm[1],$cm[2]);
        if($cmp&&!empty($cmp['indexable'])){
            $p0=$cmp['products'][0];$p1=$cmp['products'][1];$fresh=array_filter([$p0['last_reviewed_at']??null,$p1['last_reviewed_at']??null]);$last=$fresh?max($fresh):null;
            $context='<section class="section" data-comparison-decision-context><h2>How to use this comparison</h2><p class="intro">Buyer context: '.htmlspecialchars($cmp['buyer_intent'],ENT_QUOTES,'UTF-8').'. Capability status and evidence confidence describe what TechSelectAI has verified about each product; Context Fit is a separate buyer-specific analytical signal and can change when your requirements, region, integrations, security needs or budget change.</p><p class="intro"><strong>Evidence depth:</strong> '.intval($cmp['overlap_known_capabilities']).' mutually known capability facts are directly comparable. '.($last?'Product data last reviewed as recently as '.htmlspecialchars(date('M j, Y',strtotime((string)$last)),ENT_QUOTES,'UTF-8').'. ':'').'Unknown remains “not yet verified,” never automatically “unsupported.”</p>';
            if(!empty($cmp['category_slug']))$context.='<p class="intro">Continue with the <a href="/categories/'.htmlspecialchars($cmp['category_slug'],ENT_QUOTES,'UTF-8').'">'.htmlspecialchars((string)$cmp['category'],ENT_QUOTES,'UTF-8').' category</a>, review each product profile, or see the <a href="/methodology">TechSelectAI methodology</a>.</p>';
            $context.='</section>';
            $html=preg_replace('#<section class="cta">#',$context.'<section class="cta">',$html,1)??$html;
        }
    }
}catch(Throwable $e){}

echo $html;
