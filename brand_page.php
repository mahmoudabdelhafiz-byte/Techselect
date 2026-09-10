<?php
/**
 * Shared HTML branding wrapper for server-rendered TechSelectAI pages.
 * Keeps API responses untouched and reuses the same favicon/logo as the Vite homepage.
 */
$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';
$target=null;

if(preg_match('#^/software/[a-z0-9-]+/?$#',$path)) $target='software_logo_page.php';
elseif(preg_match('#^/categories/[a-z0-9-]+/?$#',$path)) $target='category_page.php';
elseif(preg_match('#^/capabilities/[a-z0-9-]+/?$#',$path)) $target='capability_page.php';
elseif(preg_match('#^/integrations/[a-z0-9-]+/?$#',$path)) $target='integration_page.php';
elseif(preg_match('#^/compare/[a-z0-9-]+-vs-[a-z0-9-]+/?$#',$path)) $target='comparison_page.php';
elseif(preg_match('#^/(login|register|verify-email|reset-password)/?$#',$path)) $target='account.php';
elseif(preg_match('#^/admin/?$#',$path)) $target='admin.php';

if(!$target || !is_file(__DIR__.'/'.$target)){
  http_response_code(404);
  exit('Not found');
}

ob_start();
require __DIR__.'/'.$target;
$html=ob_get_clean();

// Only transform HTML documents. This wrapper must never alter JSON/API output.
if(stripos($html,'<html')===false || stripos($html,'<head')===false){
  echo $html;
  exit;
}

$favicon='<link rel="icon" type="image/svg+xml" href="/favicon.svg"><link rel="shortcut icon" href="/favicon.svg">';
if(stripos($html,'href="/favicon.svg"')===false && stripos($html,"href='/favicon.svg'")===false){
  $html=str_ireplace('</head>',$favicon.'</head>',$html);
}

$brandCss='<style id="techselectai-global-branding">.ts-brand-link{display:inline-flex!important;align-items:center!important;text-decoration:none!important}.ts-brand-link img{display:block;width:auto;height:34px;max-width:210px}.ts-global-brand{padding:14px max(20px,5vw);border-bottom:1px solid #e2e8f0;background:#fff}.ts-global-brand a{display:inline-flex;align-items:center}.ts-global-brand img{height:34px;width:auto;max-width:210px;display:block}@media(max-width:560px){.ts-brand-link img,.ts-global-brand img{height:30px;max-width:180px}}</style>';
if(stripos($html,'techselectai-global-branding')===false){
  $html=str_ireplace('</head>',$brandCss.'</head>',$html);
}

$logo='<img src="/techselectai-logo.svg" alt="TechSelectAI" width="210" height="46" decoding="async">';
$replaced=0;
$html=preg_replace_callback(
  '#<a([^>]*href=["\']/["\'][^>]*)>\s*TechSelectAI\s*</a>#i',
  static function($m) use ($logo,&$replaced){
    $replaced++;
    $attrs=$m[1];
    if(stripos($attrs,'class=')!==false){
      $attrs=preg_replace('#class=(["\'])(.*?)\1#i','class=$1$2 ts-brand-link$1',$attrs,1);
    }else{
      $attrs.=' class="ts-brand-link"';
    }
    return '<a'.$attrs.' aria-label="TechSelectAI home">'.$logo.'</a>';
  },
  $html
)??$html;

// Pages such as account/admin may not have a homepage brand anchor. Add a compact brand strip.
if($replaced===0 && stripos($html,'src="/techselectai-logo.svg"')===false){
  $strip='<div class="ts-global-brand"><a href="/" aria-label="TechSelectAI home">'.$logo.'</a></div>';
  $html=preg_replace('#<body([^>]*)>#i','<body$1>'.$strip,$html,1)??$html;
}

echo $html;
