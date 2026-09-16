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
$community='<section class="ts-product-community" id="community" data-product-community="'.$esc.'"><div class="eyebrow">Product community</div><div class="community-head"><div><h2>Ask the TechSelectAI Community</h2><p>Ask implementation, licensing, integration, migration or operational questions, or share a useful product discussion.</p></div><div class="community-sort"><button type="button" class="active" data-community-sort="recent">Recent</button><button type="button" data-community-sort="helpful">Most helpful</button></div></div><form class="community-composer" data-community-composer><select name="type" aria-label="Post type"><option value="question">Question</option><option value="discussion">Discussion</option></select><textarea name="body" maxlength="3000" required placeholder="Ask a practical question or start a useful discussion…"></textarea><button type="submit" class="btn primary">Post to community</button></form><div class="community-status" data-community-status hidden></div><div class="community-list" data-community-list aria-live="polite"></div><small class="community-neutrality">Community posts, replies and Helpful reactions are separate from verified reviews, product evidence, Fit Score and recommendation ranking. Reports are reviewed; a report does not automatically declare a post false or remove it.</small></section>';
$css='<style id="techselectai-partner-discovery-style">.ts-product-follow-top{display:flex;flex-direction:column;gap:7px}.ts-product-follow-top button{width:100%;cursor:pointer}.ts-product-follow-top button[aria-pressed="true"]{background:#0f766e!important;border-color:#0f766e!important;color:#fff!important}.ts-product-follow-top button:disabled{opacity:.65;cursor:wait}.ts-product-follow-top small{max-width:210px;color:#64748b;font-size:11px;line-height:1.35;text-align:center}.ts-product-community,.ts-product-alternatives,.ts-partner-discovery{margin-top:34px;padding:24px;border:1px solid #d8e5ec;border-radius:16px;background:#f8fbfd}.ts-product-community h2,.ts-product-alternatives h2,.ts-partner-discovery h2{margin:5px 0 8px}.ts-product-community p,.ts-product-alternatives p,.ts-partner-discovery p{color:#64748b;line-height:1.6}.ts-product-alternatives a,.ts-partner-discovery a{display:inline-flex;padding:10px 14px;border:0;border-radius:10px;background:#123b67;color:#fff!important;text-decoration:none;font-weight:750;cursor:pointer}.ts-product-alternatives small,.ts-partner-discovery small{display:block;margin-top:12px;color:#64748b;line-height:1.5}.community-head{display:flex;justify-content:space-between;gap:20px;align-items:flex-start}.community-sort{display:flex;gap:7px}.community-sort button,.community-action{border:1px solid #cbd5e1;background:#fff;color:#334155;border-radius:999px;padding:7px 10px;font-weight:700;cursor:pointer}.community-sort button.active{background:#123b67;color:#fff;border-color:#123b67}.community-composer{display:grid;grid-template-columns:140px 1fr auto;gap:10px;margin:18px 0}.community-composer select,.community-composer textarea,.community-reply-form textarea{border:1px solid #cbd5e1;border-radius:10px;padding:10px;font:inherit;background:#fff}.community-composer textarea{min-height:72px;resize:vertical}.community-list{display:grid;gap:12px}.community-post{border:1px solid #dbe5eb;border-radius:12px;background:#fff;padding:15px}.community-reply{margin-top:10px;background:#fbfdfe;border-color:#e7edf1}.community-meta{display:flex;align-items:center;gap:8px;color:#64748b;font-size:12px}.community-type{background:#eef6fa;color:#123b67;padding:4px 7px;border-radius:999px;font-weight:800}.community-body{white-space:pre-wrap;color:#243043!important;margin:10px 0!important}.community-actions{display:flex;gap:8px;flex-wrap:wrap}.community-replies{margin-left:24px;border-left:2px solid #e2e8f0;padding-left:12px}.community-reply-form{display:flex;gap:8px;margin-top:12px}.community-reply-form textarea{flex:1;min-height:54px}.community-empty,.community-status{padding:13px;border-radius:10px;background:#fff;border:1px solid #e2e8f0;color:#64748b}.community-status.error{border-color:#fecaca;color:#991b1b}.community-neutrality{display:block;margin-top:15px;color:#64748b;line-height:1.5}.pri-pipeline-status{margin-top:10px;padding:10px 12px;border-radius:10px;background:#f8fafc;border:1px solid #e2e8f0;color:#536174;font-size:12px;line-height:1.5}@media(max-width:850px){.ts-product-follow-top{min-width:180px}.ts-product-follow-top small{max-width:240px;text-align:left}.community-head{display:block}.community-sort{margin-top:10px}.community-composer{grid-template-columns:1fr}.community-replies{margin-left:10px}}@media(max-width:560px){.ts-product-follow-top{width:100%}.ts-product-follow-top small{max-width:none;text-align:left}.community-reply-form{display:grid}.community-actions{gap:5px}}</style><script src="/product_follow.js" defer></script><script src="/product_community.js" defer></script>';
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

$html=preg_replace('#<section class="cta">#',$community.$alternatives.$section.'<section class="cta">',$html,1)??$html;
echo $html;
