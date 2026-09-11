<?php
$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';
if(!preg_match('#^/software/([a-z0-9-]+)/?$#',$path,$m)){http_response_code(404);exit('Not found');}
$slug=$m[1];
ob_start();
require __DIR__.'/customer_outcome_links_page.php';
$html=ob_get_clean();
if(stripos($html,'<html')===false){echo $html;return;}
$esc=htmlspecialchars($slug,ENT_QUOTES,'UTF-8');
$section='<section class="ts-partner-discovery" id="verified-partners" data-citation-section="verified-partners"><div class="eyebrow">Local delivery options</div><h2>Find verified vendors & implementation partners</h2><p>See verified resellers, distributors, implementation partners and local agents for this software by country or city. Provider ordering is separate from TechSelectAI software evaluation and fit ranking.</p><a href="/partners?software='.$esc.'">Find verified providers →</a><small>Only reviewed company↔software relationships are shown as verified. Sponsorship cannot change software recommendation scores.</small></section>';
$css='<style id="techselectai-partner-discovery-style">.ts-partner-discovery{margin-top:34px;padding:24px;border:1px solid #d8e5ec;border-radius:16px;background:#f8fbfd}.ts-partner-discovery h2{margin:5px 0 8px}.ts-partner-discovery p{color:#64748b;line-height:1.6}.ts-partner-discovery a{display:inline-flex;padding:10px 14px;border-radius:10px;background:#123b67;color:#fff!important;text-decoration:none;font-weight:750}.ts-partner-discovery small{display:block;margin-top:12px;color:#64748b;line-height:1.5}</style>';
$html=str_ireplace('</head>',$css.'</head>',$html);
$html=preg_replace('#<section class="cta">#',$section.'<section class="cta">',$html,1)??$html;
echo $html;
