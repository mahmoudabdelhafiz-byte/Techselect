<?php
/** Adds visible factual summaries and matching JSON-LD to software/comparison pages. */
ob_start();
require __DIR__.'/brand_page.php';
$html=ob_get_clean();
$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';
try{
  require_once __DIR__.'/app/lib/Db.php';
  require_once __DIR__.'/app/lib/AiFactualSummary.php';
  $cfg=require __DIR__.'/app/config.php';
  $fact=AiFactualSummary::build(Db::pdo(),$path,(string)($cfg['site_url']??'https://techselectai.com'));
  if($fact && stripos($html,'<html')!==false){
    $css='<style id="techselectai-factual-summary-style">.ts-factual-summary{margin:6px 0 26px;padding:18px 20px;border:1px solid #d9e6ed;border-radius:14px;background:#f8fbfd}.ts-factual-summary h2{margin:4px 0 8px;font-size:20px;color:#123b67}.ts-factual-summary p{margin:0;color:#43546a;line-height:1.65}.ts-factual-summary small{display:block;margin-top:9px;color:#64748b;line-height:1.5}@media(max-width:560px){.ts-factual-summary{padding:16px}}</style>';
    $json='<script type="application/ld+json" id="techselectai-factual-summary-ld">'.json_encode($fact['jsonld'],JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE).'</script>';
    $html=str_ireplace('</head>',$css.$json.'</head>',$html);
    $html=preg_replace('#(<section class="hero"[^>]*>.*?</section>)#is','$1'.$fact['html'],$html,1)??$html;
  }
}catch(Throwable $e){}
echo $html;
