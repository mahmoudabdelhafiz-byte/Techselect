<?php
/**
 * Public first-party TechSelectAI Verified Reviews layer for software pages.
 * Also renders the independent TechSelectAI product evaluation when a published
 * evaluation is available. Neither layer changes buyer-specific recommendation scoring.
 */
require_once __DIR__.'/app/lib/Db.php';
require_once __DIR__.'/app/lib/ProductEvaluation.php';
$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';
$product=null;$rating=null;$reviews=[];$reviewTablesAvailable=false;$productEvaluation=null;

if(preg_match('#^/software/([a-z0-9-]+)/?$#',$path,$m)){
    try{
        $pdo=Db::pdo();
        $st=$pdo->prepare("SELECT id,name,slug FROM products WHERE slug=? AND status='active' LIMIT 1");
        $st->execute([$m[1]]);
        $product=$st->fetch()?:null;
        if($product){
            try{$productEvaluation=ProductEvaluation::publishedForProduct($pdo,(int)$product['id']);}catch(Throwable $e){$productEvaluation=null;}

            $reviewTablesAvailable=true;
            $rs=$pdo->prepare("SELECT rating_5,approved_review_count,weighted_review_count,verification_confidence,methodology_version,last_calculated_at FROM product_verified_review_ratings WHERE product_id=? LIMIT 1");
            $rs->execute([(int)$product['id']]);
            $rating=$rs->fetch()?:null;

            $q=$pdo->prepare("SELECT r.id,r.overall_rating,r.ease_of_use_rating,r.implementation_rating,r.support_rating,r.value_for_money_rating,r.reliability_rating,r.would_recommend,r.would_choose_again,r.pros,r.cons,r.improvements,r.reviewer_role,r.reviewer_industry,r.reviewer_country,r.company_size_band,r.usage_duration_band,r.deployment_model,r.public_identity_mode,r.published_at,(SELECT MAX(CASE v.verification_level WHEN 'admin_verified' THEN 4 WHEN 'proof_of_use_verified' THEN 3 WHEN 'business_domain_verified' THEN 2 WHEN 'email_verified' THEN 1 ELSE 0 END) FROM software_review_verifications v WHERE v.review_id=r.id AND v.verification_status='verified') AS verification_rank FROM software_reviews r WHERE r.product_id=? AND r.moderation_status='approved' AND r.published_at IS NOT NULL ORDER BY r.published_at DESC,r.id DESC LIMIT 5");
            $q->execute([(int)$product['id']]);
            $reviews=$q->fetchAll()?:[];
        }
    }catch(Throwable $e){
        // Review migrations may not yet be deployed. Product pages must remain available.
        $rating=null;$reviews=[];$reviewTablesAvailable=false;
    }
}

ob_start();
require __DIR__.'/software_logo_page.php';
$html=ob_get_clean();

if(!$product){echo $html;return;}
$esc=static fn($v)=>htmlspecialchars((string)$v,ENT_QUOTES,'UTF-8');
$verificationLabel=static function($rank){return match((int)$rank){4=>'Admin verified',3=>'Proof of use verified',2=>'Business domain verified',default=>'Email verified'};};
$ratingPill=static function($label,$value) use($esc){if($value===null||$value==='')return '';return '<span class="vr-pill">'.$esc($label).' <strong>'.intval($value).'/5</strong></span>';};

$css='.product-evaluation{margin-top:38px;padding:24px;border:1px solid var(--line);border-radius:16px;background:#fff}.pe-head{display:flex;justify-content:space-between;align-items:flex-start;gap:18px}.pe-score{min-width:140px;text-align:right;font-size:42px;font-weight:850;color:var(--navy);line-height:1}.pe-score small{font-size:14px;color:var(--muted);font-weight:700}.pe-meta,.pe-note{margin-top:8px;color:var(--muted);font-size:12px;line-height:1.55}.pe-summary{margin-top:12px;color:#536174;line-height:1.6}.pe-best{margin-top:14px;padding:12px 14px;border-radius:12px;background:#eef8f7;color:#245b58}.pe-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:12px;margin-top:18px}.pe-card{border:1px solid #e6edf2;border-radius:13px;padding:14px;background:#fbfdfe}.pe-card-head{display:flex;justify-content:space-between;gap:12px}.pe-card h3{margin:0;font-size:14px;color:var(--navy)}.pe-dim-score{font-weight:850;color:var(--navy)}.pe-card p{margin:8px 0 0;color:#536174;font-size:13px;line-height:1.5}.pe-card-meta{margin-top:8px;color:var(--muted);font-size:11px}.verified-reviews{margin-top:38px;padding:24px;border:1px solid var(--line);border-radius:16px;background:#fff}.vr-head{display:flex;justify-content:space-between;align-items:flex-start;gap:18px}.vr-score{min-width:120px;text-align:right;font-size:38px;font-weight:850;color:var(--navy);line-height:1}.vr-score small{font-size:14px;color:var(--muted);font-weight:700}.vr-meta{margin-top:7px;color:var(--muted);font-size:12px}.vr-actions{margin-top:14px}.vr-write{display:inline-flex;align-items:center;padding:10px 14px;border-radius:10px;background:var(--navy);color:#fff!important;text-decoration:none;font-weight:750}.vr-grid{display:grid;gap:14px;margin-top:20px}.vr-card{border:1px solid #e6edf2;border-radius:14px;padding:17px;background:#fbfdfe}.vr-card-head{display:flex;justify-content:space-between;gap:14px}.vr-stars{font-size:18px;font-weight:850;color:var(--navy)}.vr-badge{display:inline-flex;padding:4px 8px;border-radius:999px;background:#e8f7f3;color:#0f766e;font-size:11px;font-weight:800}.vr-context{margin-top:5px;color:var(--muted);font-size:12px}.vr-pills{display:flex;gap:7px;flex-wrap:wrap;margin-top:12px}.vr-pill{padding:5px 8px;border:1px solid #dfe7ee;border-radius:999px;background:#fff;color:#536174;font-size:11px}.vr-copy{display:grid;grid-template-columns:1fr 1fr;gap:15px;margin-top:14px}.vr-copy h3{font-size:13px;margin:0 0 5px}.vr-copy p{margin:0;color:#536174;line-height:1.55}.vr-note{margin-top:14px;color:var(--muted);font-size:12px;line-height:1.55}.vr-empty{margin-top:18px;padding:15px;border:1px dashed #cbd5e1;border-radius:12px;color:#536174;background:#fbfdfe}@media(max-width:650px){.pe-head,.vr-head,.vr-card-head{display:block}.pe-score,.vr-score{text-align:left;margin-top:14px}.pe-grid,.vr-copy{grid-template-columns:1fr}}';
$html=str_replace('</style>',$css.'</style>',$html);

$evaluationSection='';
if($productEvaluation){
    $score=$productEvaluation['overall_score'];
    $confidence=ProductEvaluation::confidenceLabel((float)$productEvaluation['confidence_score']);
    $evaluationSection='<section class="product-evaluation" id="techselect-evaluation" data-citation-section="techselect-evaluation"><div class="pe-head"><div><div class="eyebrow">TechSelectAI Product Evaluation</div><h2>Independent product assessment</h2><p class="section-intro">A product-level assessment based on the published TechSelectAI methodology. This is separate from the buyer-specific Fit Score.</p></div>';
    if($score!==null)$evaluationSection.='<div class="pe-score">'.number_format((float)$score,1).'<small> / 10</small><div class="pe-meta">'.$esc($confidence).' confidence</div></div>';
    $evaluationSection.='</div>';
    if(!empty($productEvaluation['summary']))$evaluationSection.='<p class="pe-summary">'.$esc($productEvaluation['summary']).'</p>';
    if(!empty($productEvaluation['best_for']))$evaluationSection.='<div class="pe-best"><strong>Best for:</strong> '.$esc($productEvaluation['best_for']).'</div>';
    if(!empty($productEvaluation['dimensions'])){
        $evaluationSection.='<div class="pe-grid">';
        foreach($productEvaluation['dimensions'] as $d){
            $evaluationSection.='<article class="pe-card"><div class="pe-card-head"><h3>'.$esc($d['label']).'</h3><span class="pe-dim-score">'.($d['score']===null?'—':number_format((float)$d['score'],1).'/10').'</span></div>';
            if(!empty($d['rationale']))$evaluationSection.='<p>'.$esc($d['rationale']).'</p>';
            $evaluationSection.='<div class="pe-card-meta">'.intval($d['evidence_count']).' evidence item'.((int)$d['evidence_count']===1?'':'s').' · '.$esc(ProductEvaluation::confidenceLabel((float)$d['confidence'])).' confidence</div></article>';
        }
        $evaluationSection.='</div>';
    }
    $date=$productEvaluation['evaluated_at']?:$productEvaluation['published_at'];
    $evaluationSection.='<p class="pe-note">Methodology '.$esc($productEvaluation['methodology_version']).' · '.intval($productEvaluation['evidence_count']).' linked evidence item'.((int)$productEvaluation['evidence_count']===1?'':'s').($date?' · Evaluated '.$esc(date('M j, Y',strtotime((string)$date))):'').'. Scores reflect TechSelectAI analysis of available evidence and are not vendor-controlled. <a href="/methodology">See methodology</a>.</p>';
    if(!empty($productEvaluation['limitations']))$evaluationSection.='<p class="pe-note"><strong>Limitations:</strong> '.$esc($productEvaluation['limitations']).'</p>';
    $evaluationSection.='</section>';
}

$reviewSection='';
if($reviewTablesAvailable){
    $reviewSection='<section class="verified-reviews"><div class="vr-head"><div><div class="eyebrow">TechSelectAI Verified Reviews</div><h2>Verified customer experience</h2><p class="section-intro">First-party reviews submitted to TechSelectAI and published only after moderation and verification checks.</p></div>';
    if($rating && $rating['rating_5']!==null && (int)$rating['approved_review_count']>0){
        $reviewSection.='<div class="vr-score">'.number_format((float)$rating['rating_5'],1).'<small> / 5</small><div class="vr-meta">'.intval($rating['approved_review_count']).' approved review'.((int)$rating['approved_review_count']===1?'':'s').'</div></div>';
    }
    $reviewSection.='</div><div class="vr-actions"><a class="vr-write" href="/review/'.$esc($product['slug']).'">Write a verified review</a></div>';

    if(!$reviews){
        $reviewSection.='<div class="vr-empty">No approved TechSelectAI Verified Reviews have been published for '.$esc($product['name']).' yet. Be the first to submit an honest review for verification.</div>';
    }else{
        $reviewSection.='<div class="vr-grid">';
        foreach($reviews as $r){
            $identity=$r['public_identity_mode']==='context_only'?'Verified reviewer context':'Anonymous verified reviewer';
            $context=array_values(array_filter([$r['reviewer_role']??null,$r['reviewer_industry']??null,$r['reviewer_country']??null,$r['company_size_band']??null]));
            $reviewSection.='<article class="vr-card"><div class="vr-card-head"><div><div class="vr-stars">'.intval($r['overall_rating']).' / 5</div><div class="vr-context">'.$esc($identity).($context?' · '.$esc(implode(' · ',$context)):'').'</div></div><span class="vr-badge">'.$esc($verificationLabel($r['verification_rank'])).'</span></div>';
            $pills=$ratingPill('Ease',$r['ease_of_use_rating']).$ratingPill('Implementation',$r['implementation_rating']).$ratingPill('Support',$r['support_rating']).$ratingPill('Value',$r['value_for_money_rating']).$ratingPill('Reliability',$r['reliability_rating']);
            if($pills!=='')$reviewSection.='<div class="vr-pills">'.$pills.'</div>';
            if(!empty($r['pros'])||!empty($r['cons'])){
                $reviewSection.='<div class="vr-copy"><div><h3>What worked well</h3><p>'.($r['pros']?$esc($r['pros']):'—').'</p></div><div><h3>What could be better</h3><p>'.($r['cons']?$esc($r['cons']):'—').'</p></div></div>';
            }
            if(!empty($r['improvements']))$reviewSection.='<div class="vr-copy" style="grid-template-columns:1fr"><div><h3>Suggested improvements</h3><p>'.$esc($r['improvements']).'</p></div></div>';
            $reviewSection.='<div class="vr-meta">Published '.($r['published_at']?$esc(date('M Y',strtotime((string)$r['published_at']))):'after verification').(!empty($r['usage_duration_band'])?' · Usage: '.$esc(str_replace('_',' ',$r['usage_duration_band'])):'').(!empty($r['deployment_model'])?' · '.$esc($r['deployment_model']):'').'</div></article>';
        }
        $reviewSection.='</div>';
    }
    $reviewSection.='<p class="vr-note">TechSelectAI Verified Review Score reflects moderated first-party user reviews. It is separate from buyer-specific Fit Score, Evidence Confidence, Product Evaluation, and Public Review Intelligence, and it does not alter recommendation ranking. Review rewards, when offered, are for honest verified participation and never depend on a positive rating.</p></section>';
}

$sections=$evaluationSection.$reviewSection;
if($sections!=='')$html=preg_replace('#<section class="cta">#',$sections.'<section class="cta">',$html,1)??$html;
echo $html;
