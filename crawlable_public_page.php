<?php
/**
 * Final crawlability wrapper for public knowledge pages.
 * Injects canonical/search metadata without changing the underlying page renderer.
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

// Remove accidental duplicate canonicals/robots injected by child renderers before adding one authoritative set.
$html=preg_replace('#<link\s+[^>]*rel=["\']canonical["\'][^>]*>#i','',$html)??$html;
$meta='<link rel="canonical" href="'.htmlspecialchars($canonical,ENT_QUOTES,'UTF-8').'">'
     .'<meta name="robots" content="index,follow,max-snippet:-1,max-image-preview:large,max-video-preview:-1">'
     .'<meta name="googlebot" content="index,follow,max-snippet:-1,max-image-preview:large,max-video-preview:-1">'
     .'<meta name="bingbot" content="index,follow,max-snippet:-1,max-image-preview:large,max-video-preview:-1">';
$html=str_ireplace('</head>',$meta.'</head>',$html);

echo $html;
