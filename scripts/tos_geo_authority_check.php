<?php
declare(strict_types=1);
$root=dirname(__DIR__);
$files=[
 'tos_research.php'=>(string)@file_get_contents($root.'/tos_research.php'),
 'tos_taxonomy.php'=>(string)@file_get_contents($root.'/tos_taxonomy.php'),
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
 'Terminal Operating Systems (TOS)','not supported','not yet verified',
 '/categories/terminal-operating-systems','/research/tos-capability-taxonomy',
 "'@type'=>'CollectionPage'","'@type'=>'ItemList'","'@type'=>'BreadcrumbList'"
] as $needle)if(strpos($files['tos_research.php'],$needle)===false)$errors[]="TOS research hub missing {$needle}";
foreach([
 '<title>','meta name="description"','rel="canonical"','application/ld+json',
 'Terminal Operating System Capability Taxonomy','Taxonomy depth is not evidence depth',
 "'@type'=>'TechArticle'","'@type'=>'DefinedTermSet'","'@type'=>'DefinedTerm'",
 "module_slug']==='mobile-access'"
] as $needle)if(strpos($files['tos_taxonomy.php'],$needle)===false)$errors[]="TOS taxonomy page missing {$needle}";
foreach(['research/terminal-operating-systems','tos_research.php','research/tos-capability-taxonomy','tos_taxonomy.php'] as $needle)
 if(strpos($files['.htaccess'],$needle)===false)$errors[]=".htaccess missing {$needle}";
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
foreach(['recommendation_rank','overall_score','fit_score','sponsored_rank','popularity_score'] as $bad){
 if(stripos($files['tos_research.php'],$bad)!==false||stripos($files['tos_taxonomy.php'],$bad)!==false)$errors[]="TOS authority pages must not implement ranking logic: {$bad}";
}
if($errors){fwrite(STDERR,"TOS GEO authority contract failed:\n- ".implode("\n- ",$errors)."\n");exit(1);}
echo "TOS GEO authority contract passed: crawlable research hub, taxonomy, internal links, sitemap and AI discovery signals are present without ranking logic.\n";
