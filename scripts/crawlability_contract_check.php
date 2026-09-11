<?php
$root=dirname(__DIR__);
$required=['robots.txt','sitemap.php','llms.txt','crawlable_public_page.php','.htaccess','docs/ai_search_crawler_readiness.md'];
foreach($required as $f){if(!is_file($root.'/'.$f)){fwrite(STDERR,"missing $f\n");exit(1);}}
$robots=file_get_contents($root.'/robots.txt');
foreach(['OAI-SearchBot','Googlebot','Bingbot','Sitemap: https://techselectai.com/sitemap.xml'] as $needle){if(strpos($robots,$needle)===false){fwrite(STDERR,"robots missing $needle\n");exit(1);}}
$wrapper=file_get_contents($root.'/crawlable_public_page.php');
foreach(['rel=\"canonical\"','index,follow','max-snippet:-1'] as $needle){if(strpos($wrapper,$needle)===false){fwrite(STDERR,"wrapper missing $needle\n");exit(1);}}
$ht=file_get_contents($root.'/.htaccess');
foreach(['software/[a-z0-9-]+/?$ crawlable_public_page.php','categories/[a-z0-9-]+/?$ crawlable_public_page.php','compare/[a-z0-9-]+-vs-[a-z0-9-]+/?$ crawlable_public_page.php'] as $needle){if(strpos($ht,$needle)===false){fwrite(STDERR,"route missing $needle\n");exit(1);}}
$sitemap=file_get_contents($root.'/sitemap.php');
foreach(['/software/','/categories/','/capabilities/','/integrations/','/compare/','/case-studies/'] as $needle){if(strpos($sitemap,$needle)===false){fwrite(STDERR,"sitemap coverage missing $needle\n");exit(1);}}
echo "crawlability contract ok\n";
