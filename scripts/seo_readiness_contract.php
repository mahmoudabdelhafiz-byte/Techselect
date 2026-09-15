<?php
/**
 * Static SEO readiness contract for TechSelectAI's public knowledge surface.
 * Tests architecture/source contracts without requiring a production DB.
 */
$root=dirname(__DIR__);
$fail=[];$ok=[];
function seo_read(string $path): string { global $root,$fail; $full=$root.'/'.$path; if(!is_file($full)){ $fail[]="missing:$path"; return ''; } return (string)file_get_contents($full); }
function seo_require(string $file,string $needle,string $label): void { global $fail,$ok; $src=seo_read($file); if($src!=='' && strpos($src,$needle)!==false)$ok[]=$label; else $fail[]="$label ($file missing $needle)"; }
$pages=['software_page.php','category_page.php','capability_page.php','integration_page.php','comparison_page.php','alternatives_page.php'];
foreach($pages as $file){
  seo_require($file,'<title>',$file.':title');
  seo_require($file,'meta name="description"',$file.':description');
  seo_require($file,'rel="canonical"',$file.':canonical');
  seo_require($file,'property="og:title"',$file.':og-title');
  seo_require($file,'property="og:description"',$file.':og-description');
  seo_require($file,'application/ld+json',$file.':jsonld');
}
seo_require('software_page.php',"'@type'=>'SoftwareApplication'",'software:schema-softwareapplication');
seo_require('software_page.php',"'@type'=>'BreadcrumbList'",'software:schema-breadcrumb');
seo_require('category_page.php',"'@type'=>'ItemList'",'category:schema-itemlist');
seo_require('capability_page.php',"'@type'=>'ItemList'",'capability:schema-itemlist');
seo_require('alternatives_page.php',"'@type'=>'ItemList'",'alternatives:schema-itemlist');
seo_require('app/lib/AlternativeSeo.php','count($alts)<3','alternatives:min-three-peers');
seo_require('app/lib/AlternativeSeo.php','fresh_verified_evidence_count','alternatives:fresh-evidence-label');
seo_require('app/lib/AlternativeSeo.php','support_status NOT IN','alternatives:known-capability-gate');
seo_require('app/lib/AlternativeSeo.php','if($overlap<3)','alternatives:overlap-gate');
seo_require('crawlable_public_page.php','rel="canonical"','crawl-wrapper:canonical');
seo_require('crawlable_public_page.php','index,follow,max-snippet:-1','crawl-wrapper:index-follow');
seo_require('crawlable_public_page.php','googlebot','crawl-wrapper:googlebot');
seo_require('crawlable_public_page.php','bingbot','crawl-wrapper:bingbot');
seo_require('crawlable_public_page.php','twitter:card','crawl-wrapper:twitter-card');
seo_require('crawlable_public_page.php','og:site_name','crawl-wrapper:og-site-name');
seo_require('crawlable_public_page.php','PublicSeoMetadata::forPath','crawl-wrapper:centralized-snippets');
seo_require('crawlable_public_page.php',"'@type'=>'Organization'",'crawl-wrapper:organization-schema');
seo_require('crawlable_public_page.php',"'@type'=>'WebSite'",'crawl-wrapper:website-schema');
seo_require('crawlable_public_page.php',"'@type'=>'WebPage'",'crawl-wrapper:webpage-schema');
seo_require('crawlable_public_page.php','LongTailSeoLinks','crawl-wrapper:related-guides');
seo_require('crawlable_public_page.php','ComparisonSeoPriority','crawl-wrapper:evidence-ready-comparisons');
seo_require('crawlable_public_page.php',"pageType='alternatives'",'crawl-wrapper:alternatives-route');
seo_require('app/lib/PublicSeoMetadata.php','Review: Features, Pricing & Alternatives','snippet:product-intent');
seo_require('app/lib/PublicSeoMetadata.php','Alternatives: Compare Evidence-Backed Options','snippet:alternatives-intent');
seo_require('app/lib/PublicSeoMetadata.php','Compare Product Support','snippet:capability-intent');
seo_require('app/lib/PublicSeoMetadata.php','Compare Compatible Products','snippet:integration-intent');
seo_require('app/lib/PublicSeoMetadata.php','Features, Evidence & Differences','snippet:comparison-intent');
seo_require('app/lib/PublicSeoMetadata.php','not yet verified','snippet:unknown-not-negative');
seo_require('sitemap.php',"COUNT(*) FROM product_capabilities",'sitemap:product-depth-gate');
seo_require('sitemap.php','EXISTS(SELECT 1 FROM evidence_sources','sitemap:evidence-gate');
seo_require('sitemap.php',"quality_decision='indexable'",'sitemap:generated-quality-gate');
seo_require('sitemap.php','ComparisonSeoPriority::indexablePairs','sitemap:comparison-quality-gate');
seo_require('sitemap.php','AlternativeSeo::indexable','sitemap:alternatives-quality-gate');
$ht=seo_read('.htaccess');
foreach(['software/','categories/','capabilities/','integrations/','compare/','alternatives/'] as $route){
  if(strpos($ht,$route)!==false && strpos($ht,'crawlable_public_page.php')!==false)$ok[]="route:$route"; else $fail[]="route:$route not wired through crawlable_public_page.php";
}
seo_require('brand_page.php','/llms.txt','ai-discovery:llms');
seo_require('brand_page.php','PublicKnowledgeSummary','ai-discovery:knowledge-summary');
seo_require('knowledge_page.php','AiFactualSummary','ai-discovery:factual-summary');
seo_require('knowledge_page.php','PublicTransparency','ai-discovery:source-transparency');
if($fail){fwrite(STDERR,"SEO readiness contract FAILED\n- ".implode("\n- ",$fail)."\n");exit(1);}echo "SEO readiness contract passed (".count($ok)." checks).\n";
