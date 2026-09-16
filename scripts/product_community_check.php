<?php
$root=dirname(__DIR__);
$files=[
 'db/mysql/101_product_community.sql',
 'app/lib/ProductCommunity.php',
 'api/product_community.php',
 'product_community.js',
 'partner_links_page.php',
];
$fail=[];$content=[];
foreach($files as $file){if(!is_file($root.'/'.$file)){$fail[]='missing '.$file;continue;}$content[$file]=file_get_contents($root.'/'.$file);}
if(!$fail){
 $m=$content['db/mysql/101_product_community.sql'];
 foreach(['product_community_posts','product_community_helpful','product_community_reports','PRIMARY KEY(post_id,user_id)','UNIQUE KEY uq_product_community_reporter'] as $needle)if(!str_contains($m,$needle))$fail[]='migration missing '.$needle;
 $api=$content['api/product_community.php'];
 foreach(['Security::sameOrigin','Security::requireCsrf','Security::rateLimit','verified_email_required','ProductCommunity::toggleHelpful','ProductCommunity::report'] as $needle)if(!str_contains($api,$needle))$fail[]='API missing '.$needle;
 $service=$content['app/lib/ProductCommunity.php'];
 foreach(["['question','discussion']","status='published'",'MAX_BODY=3000'] as $needle)if(!str_contains($service,$needle))$fail[]='service missing '.$needle;
 if(preg_match('/fit.?score|recommendation.?rank|ranking.?score/i',$service))$fail[]='community service must not reference Fit Score or ranking logic';
 $page=$content['partner_links_page.php'];
 foreach(['Ask the TechSelectAI Community','data-product-community','Helpful reactions are separate from verified reviews, product evidence, Fit Score and recommendation ranking','/product_community.js'] as $needle)if(!str_contains($page,$needle))$fail[]='page missing '.$needle;
 $js=$content['product_community.js'];
 foreach(["action:'helpful'","action:'report'","action:'post'",'textContent'] as $needle)if(!str_contains($js,$needle))$fail[]='UI missing '.$needle;
 if(str_contains($js,'.innerHTML'))$fail[]='community UI must not render user content through innerHTML';
}
if($fail){foreach($fail as $f)fwrite(STDERR,"FAIL $f\n");exit(1);}echo "Product Community contract checks passed.\n";
