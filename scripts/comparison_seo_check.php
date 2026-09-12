<?php
$root=dirname(__DIR__);$errors=[];
$class=file_get_contents($root.'/app/lib/ComparisonSeoPriority.php')?:'';
$sitemap=file_get_contents($root.'/sitemap.php')?:'';
$wrapper=file_get_contents($root.'/crawlable_public_page.php')?:'';
$comparison=file_get_contents($root.'/comparison_page.php')?:'';

require_once $root.'/app/lib/ComparisonSeoPriority.php';
if(ComparisonSeoPriority::path('cardiq','blinq')!=='/compare/blinq-vs-cardiq')$errors[]='CardIQ/Blinq canonical comparison path changed';
if(!ComparisonSeoPriority::isProtected('cardiq','blinq'))$errors[]='existing ranking CardIQ/Blinq pair is not protected';
if(str_contains($class,'Scoring::')||str_contains($class,'recommendation_runs')||str_contains($class,'UPDATE recommendation')||str_contains($class,'INSERT INTO recommendation'))$errors[]='comparison SEO priority layer appears coupled to recommendation scoring/ranking';
if(!str_contains($sitemap,"support_status NOT IN ('unknown','not_yet_verified')"))$errors[]='comparison sitemap does not exclude unknown placeholder facts';
if(!str_contains($sitemap,"verification_status='verified'"))$errors[]='comparison sitemap lacks verified-evidence gate';
if(!str_contains($sitemap,'ComparisonSeoPriority::indexablePairs'))$errors[]='curated comparison priority set is not wired into sitemap';
if(!str_contains($wrapper,'ComparisonSeoPriority::linksForProduct')||!str_contains($wrapper,'ComparisonSeoPriority::linksForCategory'))$errors[]='priority comparison internal links are not wired to product/category pages';
if(!str_contains($wrapper,'!ComparisonSeoPriority::isProtected'))$errors[]='ranking comparison page lacks protected-content guard';
if(!str_contains($comparison,'Unknown means not yet verified, not unsupported.'))$errors[]='core comparison evidence semantics changed';
if(!str_contains($comparison,"'@type'=>'WebPage'")||!str_contains($comparison,'rel="canonical"'))$errors[]='core comparison canonical/structured-data contract changed';
if($errors){fwrite(STDERR,"Comparison SEO contract failed:\n- ".implode("\n- ",$errors)."\n");exit(1);}echo "Comparison SEO contract passed.\n";
