<?php
/**
 * Shared HTML branding wrapper for server-rendered TechSelectAI pages.
 * Keeps API responses untouched and reuses the same favicon/logo as the Vite homepage.
 */
$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';
$target=null;

if(preg_match('#^/software/[a-z0-9-]+/?$#',$path)) $target='software_reviews_page.php';
elseif(preg_match('#^/categories/[a-z0-9-]+/?$#',$path)) $target='category_page.php';
elseif(preg_match('#^/capabilities/[a-z0-9-]+/?$#',$path)) $target='capability_page.php';
elseif(preg_match('#^/integrations/[a-z0-9-]+/?$#',$path)) $target='integration_page.php';
elseif(preg_match('#^/compare/[a-z0-9-]+-vs-[a-z0-9-]+/?$#',$path)) $target='comparison_page.php';
elseif(preg_match('#^/(login|register|verify-email|reset-password)/?$#',$path) || $path==='/account.php') $target='account.php';
elseif($path==='/admin' || $path==='/admin/' || $path==='/admin.php') $target='admin.php';
elseif(preg_match('#^/review/[a-z0-9-]+/?$#',$path) || $path==='/review.php') $target='review.php';
elseif(in_array($path,['/my-reviews','/my-reviews/','/my_reviews.php'],true)) $target='my_reviews.php';
elseif(in_array($path,['/my-consultations','/my-consultations/','/my_consultations.php'],true)) $target='my_consultations.php';
elseif(in_array($path,['/review-moderation','/review-moderation/','/review_moderation.php'],true)) $target='review_moderation.php';
elseif(in_array($path,['/review-rewards','/review-rewards/','/review_rewards.php'],true)) $target='review_rewards.php';
elseif(in_array($path,['/taxonomy-queue','/taxonomy-queue/','/taxonomy_queue.php'],true)) $target='taxonomy_queue.php';
elseif(in_array($path,['/pri-source-policy','/pri-source-policy/','/pri_source_policy.php'],true)) $target='pri_source_policy.php';
elseif(in_array($path,['/ai-referrals','/ai-referrals/','/ai_referrals.php'],true)) $target='ai_referrals.php';

if(!$target || !is_file(__DIR__.'/'.$target)){
  http_response_code(404);
  exit('Not found');
}

ob_start();
require __DIR__.'/'.$target;
$html=ob_get_clean();

if(stripos($html,'<html')===false || stripos($html,'<head')===false){echo $html;exit;}

$favicon='<link rel="icon" type="image/svg+xml" href="/favicon.svg"><link rel="shortcut icon" href="/favicon.svg">';
if(stripos($html,'href="/favicon.svg"')===false && stripos($html,"href='/favicon.svg'")===false){$html=str_ireplace('</head>',$favicon.'</head>',$html);}

$brandCss='<style id="techselectai-global-branding">.ts-brand-link{display:inline-flex!important;align-items:center!important;text-decoration:none!important}.ts-brand-link img{display:block;width:auto;height:34px;max-width:210px}.ts-global-brand{padding:14px max(20px,5vw);border-bottom:1px solid #e2e8f0;background:#fff}.ts-global-brand a{display:inline-flex;align-items:center}.ts-global-brand img{height:34px;width:auto;max-width:210px;display:block}@media(max-width:560px){.ts-brand-link img,.ts-global-brand img{height:30px;max-width:180px}}</style>';
if(stripos($html,'techselectai-global-branding')===false){$html=str_ireplace('</head>',$brandCss.'</head>',$html);}

$logo='<img src="/techselectai-logo.svg" alt="TechSelectAI" width="210" height="46" decoding="async">';
$replaced=0;
$html=preg_replace_callback('#<a([^>]*href=["\']/["\'][^>]*)>\s*TechSelectAI\s*</a>#i',static function($m) use ($logo,&$replaced){$replaced++;$attrs=$m[1];if(stripos($attrs,'class=')!==false){$attrs=preg_replace('#class=(["\'])(.*?)\1#i','class=$1$2 ts-brand-link$1',$attrs,1);}else{$attrs.=' class="ts-brand-link"';}return '<a'.$attrs.' aria-label="TechSelectAI home">'.$logo.'</a>';},$html)??$html;
if($replaced===0 && stripos($html,'src="/techselectai-logo.svg"')===false){$strip='<div class="ts-global-brand"><a href="/" aria-label="TechSelectAI home">'.$logo.'</a></div>';$html=preg_replace('#<body([^>]*)>#i','<body$1>'.$strip,$html,1)??$html;}

$isPublicKnowledge=(bool)preg_match('#^/(software|categories|capabilities|integrations|compare)/#',$path);
if($isPublicKnowledge){
  try{
    require_once __DIR__.'/app/lib/Db.php';
    require_once __DIR__.'/app/lib/AiReferralAnalytics.php';
    AiReferralAnalytics::record(Db::pdo(),$path,$_SERVER['HTTP_REFERER']??null);
  }catch(Throwable $e){}

  if(stripos($html,'href="/llms.txt"')===false){
    $html=str_ireplace('</head>','<link rel="alternate" type="text/plain" href="/llms.txt" title="TechSelectAI AI discovery guide"></head>',$html);
  }
  $html=preg_replace('#<section class="hero"(?![^>]*\bid=)#i','<section class="hero" id="overview" data-citation-section="overview"',$html,1)??$html;
  $anchorMap=[
    'Capabilities'=>'capabilities','Product support comparison'=>'product-support','Product support'=>'product-support','Capability comparison'=>'capability-comparison','Integration comparison'=>'integration-comparison','Deployment comparison'=>'deployment-comparison','Deployment options'=>'deployment','Integrations'=>'integrations','Plans / editions'=>'plans','Pricing'=>'pricing','Evidence sources'=>'evidence','Alternatives'=>'alternatives','How to use this comparison'=>'interpretation','How to read this comparison'=>'interpretation'
  ];
  foreach($anchorMap as $heading=>$id){
    $quoted=preg_quote($heading,'#');
    $pattern='#<section class="section"(?![^>]*\bid=)([^>]*)>\s*<h2>'.$quoted.'</h2>#i';
    $replacement='<section class="section" id="'.$id.'" data-citation-section="'.$id.'"$1><h2>'.$heading.'</h2>';
    $html=preg_replace($pattern,$replacement,$html,1)??$html;
  }
  $html=preg_replace('#<section class="verified-reviews"(?![^>]*\bid=)#i','<section class="verified-reviews" id="verified-reviews" data-citation-section="verified-reviews"',$html,1)??$html;
  $html=preg_replace('#<section class="public-review-intelligence"(?![^>]*\bid=)#i','<section class="public-review-intelligence" id="public-review-intelligence" data-citation-section="public-review-intelligence"',$html,1)??$html;
}

echo $html;
