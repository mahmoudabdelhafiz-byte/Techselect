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
$css='<style id="techselectai-partner-discovery-style">.ts-product-follow-top{display:flex;flex-direction:column;gap:7px}.ts-product-follow-top button{width:100%;cursor:pointer}.ts-product-follow-top button[aria-pressed="true"]{background:#0f766e!important;border-color:#0f766e!important;color:#fff!important}.ts-product-follow-top button:disabled{opacity:.65;cursor:wait}.ts-product-follow-top small{max-width:210px;color:#64748b;font-size:11px;line-height:1.35;text-align:center}.ts-product-alternatives,.ts-partner-discovery{margin-top:34px;padding:24px;border:1px solid #d8e5ec;border-radius:16px;background:#f8fbfd}.ts-product-alternatives h2,.ts-partner-discovery h2{margin:5px 0 8px}.ts-product-alternatives p,.ts-partner-discovery p{color:#64748b;line-height:1.6}.ts-product-alternatives a,.ts-partner-discovery a{display:inline-flex;padding:10px 14px;border:0;border-radius:10px;background:#123b67;color:#fff!important;text-decoration:none;font-weight:750;cursor:pointer}.ts-product-alternatives small,.ts-partner-discovery small{display:block;margin-top:12px;color:#64748b;line-height:1.5}.pri-pipeline-status{margin-top:10px;padding:10px 12px;border-radius:10px;background:#f8fafc;border:1px solid #e2e8f0;color:#536174;font-size:12px;line-height:1.5}@media(max-width:850px){.ts-product-follow-top{min-width:180px}.ts-product-follow-top small{max-width:240px;text-align:left}}@media(max-width:560px){.ts-product-follow-top{width:100%}.ts-product-follow-top small{max-width:none;text-align:left}}</style><script src="/product_follow.js" defer></script>';
$html=str_ireplace('</head>',$css.'</head>',$html);
if(stripos($html,'<div class="hero-actions">')!==false){
    $html=preg_replace('#<div class="hero-actions">#','<div class="hero-actions">'.$follow,$html,1)??$html;
}else{
    $html=preg_replace('#(<section class="hero"[^>]*>.*?</section>)#is','$1'.$follow,$html,1)??$html;
}

// Explain why Public Review Intelligence has no published score instead of exposing a null-like state.
try{
    require_once __DIR__.'/app/lib/Db.php';
    $pdo=Db::pdo();
    $p=$pdo->prepare("SELECT id,name FROM products WHERE slug=? AND status='active' LIMIT 1");
    $p->execute([$slug]);
    if($product=$p->fetch(PDO::FETCH_ASSOC)){
        $pid=(int)$product['id'];
        $candidate=null;
        try{$q=$pdo->prepare("SELECT score_5,insufficient_data,review_status,published_at,last_analyzed_at FROM product_public_review_intelligence WHERE product_id=? LIMIT 1");$q->execute([$pid]);$candidate=$q->fetch(PDO::FETCH_ASSOC)?:null;}catch(Throwable $e){}
        $needsExplanation=!$candidate||$candidate['score_5']===null||!empty($candidate['insufficient_data'])||($candidate['review_status']??'')!=='published'||empty($candidate['published_at']);
        if($needsExplanation && stripos($html,'id="public-review-intelligence"')!==false){
            $connectors=0;$permitted=0;$items=0;$pending=0;$runs=0;
            try{$q=$pdo->prepare("SELECT COUNT(*) total,SUM(policy_status='permitted' AND status='active') permitted FROM public_review_connectors WHERE product_id=?");$q->execute([$pid]);$r=$q->fetch(PDO::FETCH_ASSOC)?:[];$connectors=(int)($r['total']??0);$permitted=(int)($r['permitted']??0);}catch(Throwable $e){}
            try{$q=$pdo->prepare("SELECT COUNT(*) total,SUM(processing_status='pending_analysis') pending FROM public_review_collected_items WHERE product_id=?");$q->execute([$pid]);$r=$q->fetch(PDO::FETCH_ASSOC)?:[];$items=(int)($r['total']??0);$pending=(int)($r['pending']??0);}catch(Throwable $e){}
            try{$q=$pdo->prepare("SELECT COUNT(*) FROM public_review_analysis_runs WHERE product_id=? AND status='completed'");$q->execute([$pid]);$runs=(int)$q->fetchColumn();}catch(Throwable $e){}
            if($connectors===0)$reason='No public-review connectors have been provisioned for this product yet. The community-review automation worker must run to create and schedule trusted sources.';
            elseif($permitted===0)$reason='Public-review connectors exist, but none are currently active and permitted for collection.';
            elseif($items===0)$reason='Trusted public-review sources are configured, but no usable product-specific review items have been collected yet.';
            elseif($runs===0)$reason=$pending>0?'Public-review items have been collected and are waiting for analysis. The community-review automation worker and PRI analyzer must complete successfully.':'Collected public-review items exist, but no completed analysis run is recorded yet.';
            elseif($candidate && !empty($candidate['insufficient_data']))$reason='Analysis has completed, but the available public evidence does not yet meet TechSelectAI minimum coverage, source-diversity or confidence requirements.';
            elseif($candidate && $candidate['score_5']!==null && (($candidate['review_status']??'')!=='published'||empty($candidate['published_at'])))$reason='A Community Intelligence candidate exists, but it has not passed the configured publication quality and safety gates yet.';
            else $reason='A publishable Community Intelligence score is not available yet. Collection, analysis or publication requirements are still incomplete.';
            $status='<div class="pri-pipeline-status"><strong>Status:</strong> '.htmlspecialchars($reason,ENT_QUOTES,'UTF-8').'</div>';
            $html=preg_replace('#(<section class="pri"[^>]*id="public-review-intelligence"[^>]*>.*?<p class="pri-note">)#is','$1'.$status,$html,1)??$html;
        }
    }
}catch(Throwable $e){}

$html=preg_replace('#<section class="cta">#',$alternatives.$section.'<section class="cta">',$html,1)??$html;
echo $html;
