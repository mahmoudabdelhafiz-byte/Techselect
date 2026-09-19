<?php
declare(strict_types=1);
$root=dirname(__DIR__);
$files=[
 'authority'=>(string)@file_get_contents($root.'/app/lib/TosResearchAuthority.php'),
 'research_report.php'=>(string)@file_get_contents($root.'/research_report.php'),
 '.htaccess'=>(string)@file_get_contents($root.'/.htaccess'),
 'sitemap.php'=>(string)@file_get_contents($root.'/sitemap.php'),
 'llms.txt'=>(string)@file_get_contents($root.'/llms.txt'),
 'category_page.php'=>(string)@file_get_contents($root.'/category_page.php'),
 'about_techselectai.php'=>(string)@file_get_contents($root.'/about_techselectai.php'),
 'methodology.php'=>(string)@file_get_contents($root.'/methodology.php'),
 'trust.php'=>(string)@file_get_contents($root.'/trust.php')
];
$errors=[];
foreach($files as $name=>$src)if($src==='')$errors[]="Missing or empty {$name}";
foreach([
 '<title>','meta name="description"','rel="canonical"','application/ld+json',
 'Terminal Operating Systems (TOS)','Not yet verified','not supported',
 '/categories/terminal-operating-systems','/research/tos-capability-taxonomy',
 "'@type'=>'CollectionPage'","'@type'=>'ItemList'","'@type'=>'BreadcrumbList'",
 'Terminal Operating System Capability Taxonomy','Taxonomy depth is not evidence depth',
 "'@type'=>'TechArticle'","'@type'=>'DefinedTermSet'","'@type'=>'DefinedTerm'",
 "module_slug']==='mobile-access'"
] as $needle)if(strpos($files['authority'],$needle)===false)$errors[]="TOS research authority component missing {$needle}";
if(strpos($files['research_report.php'],'TosResearchAuthority::render')===false)$errors[]='Existing research surface must dispatch TOS authority routes';
foreach(['research/terminal-operating-systems','research/tos-capability-taxonomy'] as $route){
 if(strpos($files['.htaccess'],$route)===false||strpos($files['.htaccess'],$route.'/?$ research_report.php')===false)$errors[]=".htaccess must consolidate {$route} through research_report.php";
}
foreach(['/research/terminal-operating-systems','/research/tos-capability-taxonomy'] as $needle)
 if(strpos($files['sitemap.php'],$needle)===false)$errors[]="Sitemap missing {$needle}";
foreach([
 'Terminal Operating Systems specialization',
 'https://techselectai.com/research/terminal-operating-systems',
 'https://techselectai.com/research/tos-capability-taxonomy',
 'https://techselectai.com/categories/terminal-operating-systems',
 'Navis N4','Tideworks Mainsail','RBS TOPS Expert','CyberLogitec OPUS Terminal','Total Soft Bank CATOS','CARGOES TOS+','Navis Mixed Cargo TOS'
] as $needle)if(strpos($files['llms.txt'],$needle)===false)$errors[]="llms.txt missing TOS discovery signal: {$needle}";
foreach(['TOS research','TOS capability taxonomy'] as $needle)
 if(strpos($files['category_page.php'],$needle)===false)$errors[]="TOS category missing internal authority link: {$needle}";
foreach(['Terminal Operating Systems (TOS)','/research/terminal-operating-systems'] as $needle){
 foreach(['about_techselectai.php','methodology.php','trust.php'] as $file){
  if(strpos($files[$file],$needle)===false)$errors[]="{$file} missing TOS authority signal: {$needle}";
 }
}
foreach(['recommendation_rank','overall_score','fit_score','sponsored_rank','popularity_score'] as $bad)
 if(stripos($files['authority'],$bad)!==false)$errors[]="TOS authority component must not implement ranking logic: {$bad}";
if($errors){fwrite(STDERR,"TOS GEO authority contract failed:\n- ".implode("\n- ",$errors)."\n");exit(1);}
echo "TOS GEO authority contract passed: consolidated research hub, taxonomy, internal links, sitemap and AI discovery signals are present without new top-level product surfaces or ranking logic.\n";
