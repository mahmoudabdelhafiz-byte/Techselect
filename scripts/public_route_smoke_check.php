<?php
// TechSelectAI public route smoke test.
// Validates deployment wiring for software/category/capability/integration/comparison/sitemap routes.
// Usage:
//   php scripts/public_route_smoke_check.php
//   php scripts/public_route_smoke_check.php --base-url=https://techselectai.com

require_once __DIR__.'/../app/lib/Db.php';

$root=dirname(__DIR__);
$config=require $root.'/app/config.php';
$base=rtrim((string)($config['site_url']??''),'/');
foreach($argv as $arg){
    if(str_starts_with($arg,'--base-url=')){$base=rtrim(substr($arg,11),'/');}
}

$failures=[];
$warnings=[];
function ok($message){echo "[OK]   {$message}\n";}
function fail_check($message){global $failures;$failures[]=$message;echo "[FAIL] {$message}\n";}
function warn_check($message){global $warnings;$warnings[]=$message;echo "[WARN] {$message}\n";}

// 1) Deployment files and rewrite rules.
$requiredFiles=['.htaccess','public_docs.php','software_logo_page.php','sitemap.php'];
foreach($requiredFiles as $file){
    if(is_file($root.'/'.$file)) ok("Required file exists: {$file}");
    else fail_check("Missing required deployment file: {$file}");
}

$ht=@file_get_contents($root.'/.htaccess')?:'';
$rewriteExpectations=[
    'software'=>'software_logo_page.php',
    'categories'=>'public_docs.php',
    'capabilities'=>'public_docs.php',
    'integrations'=>'public_docs.php',
    'compare'=>'public_docs.php',
    'sitemap'=>'sitemap.php',
];
foreach($rewriteExpectations as $family=>$target){
    if(str_contains($ht,$target) && ($family==='sitemap' || str_contains($ht,'^'.$family.'/'))) ok("Rewrite configured: {$family} -> {$target}");
    else fail_check("Rewrite missing or incorrect for {$family} -> {$target}");
}

// 2) Pick real published slugs from the current DB so the check follows the catalog.
$pdo=Db::pdo();
$routes=[];

$product=$pdo->query("SELECT slug FROM products WHERE status='active' ORDER BY CASE WHEN slug='cardiq' THEN 0 ELSE 1 END,name LIMIT 1")->fetchColumn();
if($product)$routes['software']='/software/'.$product; else fail_check('No active product available for software route smoke test.');

$category=$pdo->query("SELECT slug FROM categories WHERE is_active=1 ORDER BY CASE WHEN slug='corporate-identity-digital-business-cards' THEN 0 ELSE 1 END,name LIMIT 1")->fetchColumn();
if($category)$routes['category']='/categories/'.$category; else fail_check('No active category available for category route smoke test.');

$capability=$pdo->query("SELECT c.slug FROM capabilities c JOIN modules m ON m.id=c.module_id JOIN categories cat ON cat.id=m.category_id WHERE c.is_active=1 AND cat.is_active=1 ORDER BY CASE WHEN c.slug='email-signatures' THEN 0 ELSE 1 END,c.name LIMIT 1")->fetchColumn();
if($capability)$routes['capability']='/capabilities/'.$capability; else fail_check('No active capability available for capability route smoke test.');

$integration=$pdo->query("SELECT i.slug FROM integrations i WHERE i.is_active=1 ORDER BY i.name LIMIT 1")->fetchColumn();
if($integration)$routes['integration']='/integrations/'.$integration; else warn_check('No active integration available; integration HTTP smoke test skipped.');

$pair=$pdo->query("SELECT p1.slug a,p2.slug b FROM products p1 JOIN products p2 ON p2.category_id=p1.category_id AND p2.id>p1.id WHERE p1.status='active' AND p2.status='active' ORDER BY p1.category_id,p1.name,p2.name LIMIT 1")->fetch();
if($pair){$slugs=[$pair['a'],$pair['b']];sort($slugs,SORT_STRING);$routes['comparison']='/compare/'.implode('-vs-',$slugs);} else warn_check('No same-category product pair available; comparison HTTP smoke test skipped.');
$routes['sitemap']='/sitemap.xml';

foreach($routes as $name=>$path) echo "[INFO] {$name}: {$path}\n";

// 3) Optional live HTTP check. cURL is preferred because shared hosting may disable allow_url_fopen.
if(!$base){
    warn_check('No site_url/base URL configured; live HTTP checks skipped.');
} elseif(!function_exists('curl_init')){
    warn_check('PHP cURL extension unavailable; live HTTP checks skipped.');
} else {
    foreach($routes as $name=>$path){
        $url=$base.$path;
        $ch=curl_init($url);
        curl_setopt_array($ch,[
            CURLOPT_RETURNTRANSFER=>true,
            CURLOPT_FOLLOWLOCATION=>true,
            CURLOPT_MAXREDIRS=>4,
            CURLOPT_CONNECTTIMEOUT=>8,
            CURLOPT_TIMEOUT=>15,
            CURLOPT_USERAGENT=>'TechSelectAI-Route-Smoke/1.0',
            CURLOPT_HEADER=>true,
        ]);
        $response=curl_exec($ch);
        $status=(int)curl_getinfo($ch,CURLINFO_HTTP_CODE);
        $type=(string)curl_getinfo($ch,CURLINFO_CONTENT_TYPE);
        $err=curl_error($ch);
        curl_close($ch);
        if($response===false){fail_check("{$name} request failed: {$err}");continue;}
        if($status<200 || $status>=400){fail_check("{$name} returned HTTP {$status}: {$url}");continue;}
        if($name==='sitemap'){
            if(stripos($type,'xml')===false && stripos($response,'<urlset')===false && stripos($response,'<sitemapindex')===false){fail_check("sitemap did not return XML-like content: {$type}");continue;}
        } else {
            if(stripos($type,'text/html')===false){fail_check("{$name} returned unexpected MIME type {$type}: {$url}");continue;}
            if(stripos($response,'404')!==false && stripos($response,'Not Found')!==false){fail_check("{$name} response appears to be a 404 page despite HTTP {$status}: {$url}");continue;}
        }
        ok("Live route works: {$name} ({$status}) {$url}");
    }
}

echo "\nSummary: ".count($failures)." failure(s), ".count($warnings)." warning(s).\n";
if($failures){exit(2);} exit(0);
