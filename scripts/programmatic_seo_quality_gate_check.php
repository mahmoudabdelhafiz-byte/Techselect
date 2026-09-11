<?php
$root=dirname(__DIR__);$checks=[];
$schema=file_get_contents($root.'/db/mysql/050_programmatic_seo_quality_gates.sql');
$svc=file_get_contents($root.'/app/lib/ProgrammaticSeoQualityGate.php');
$sitemap=file_get_contents($root.'/sitemap.php');
$routes=file_get_contents($root.'/.htaccess');
$checks['registry_schema']=str_contains($schema,'seo_generated_pages')&&str_contains($schema,'quality_decision')&&str_contains($schema,'canonical_target_path');
$checks['three_state_decision']=str_contains($svc,"'not_generated'")&&str_contains($svc,"'published_noindex'")&&str_contains($svc,"'indexable'");
$checks['duplicate_detection']=str_contains($svc,'near_duplicate_or_overlapping_intent')&&str_contains($svc,'jaccard');
$checks['freshness_evidence_links']=str_contains($svc,'stale_content')&&str_contains($svc,'insufficient_source_diversity')&&str_contains($svc,'insufficient_internal_links');
$checks['robots_boundary']=str_contains($svc,'noindex,follow')&&str_contains($svc,'index,follow');
$checks['sitemap_gate']=str_contains($sitemap,"status='published' AND quality_decision='indexable'");
$checks['admin_routes']=str_contains($routes,'seo-quality-gates')&&is_file($root.'/seo_quality_gates_admin.php')&&is_file($root.'/api/seo_quality_gates.php');
$failed=array_keys(array_filter($checks,fn($v)=>!$v));
echo json_encode(['checks'=>$checks,'ok'=>!$failed,'failed'=>$failed],JSON_PRETTY_PRINT).PHP_EOL;exit($failed?1:0);
