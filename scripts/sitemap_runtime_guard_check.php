<?php
$root=dirname(__DIR__);
$sitemap=file_get_contents($root.'/sitemap.php');
$schema=file_get_contents($root.'/db/mysql/001_v1_schema.sql');
$errors=[];
if(strpos($sitemap,'evidence_sources e')===false)$errors[]='sitemap evidence query missing';
if(strpos($sitemap,'e.created_at')!==false)$errors[]='sitemap references nonexistent evidence_sources.created_at';
if(strpos($sitemap,'e.checked_at>=DATE_SUB')===false)$errors[]='sitemap freshness must use evidence_sources.checked_at';
if(strpos($sitemap,'try{\n    $compareSql=')===false && strpos($sitemap,'try{\r\n    $compareSql=')===false)$errors[]='fallback comparison sitemap query should be isolated by try/catch';
if(strpos($schema,'checked_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP')===false)$errors[]='schema checked_at contract changed';
if(strpos($schema,'CREATE TABLE IF NOT EXISTS evidence_sources')===false)$errors[]='evidence_sources schema missing';
if($errors){fwrite(STDERR,"FAIL sitemap runtime guard:\n- ".implode("\n- ",$errors)."\n");exit(1);}echo "PASS sitemap runtime guard\n";
