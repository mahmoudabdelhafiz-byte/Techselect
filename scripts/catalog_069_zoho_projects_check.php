<?php
$root=dirname(__DIR__);$errors=[];
$migrationPath=$root.'/db/mysql/069_add_zoho_projects_catalog.sql';
$migration=is_file($migrationPath)?(file_get_contents($migrationPath)?:''):'';

if($migration==='')$errors[]='missing or empty migration 069_add_zoho_projects_catalog.sql';

// This gap-completion migration must reuse the existing taxonomy instead of creating duplicates.
foreach(['INSERT INTO categories','INSERT INTO modules','INSERT INTO capabilities'] as $forbidden){
    if(stripos($migration,$forbidden)!==false)$errors[]="069 must not create duplicate taxonomy via {$forbidden}";
}
if(!str_contains($migration,"WHERE slug='project-management'"))$errors[]='069 does not reuse the existing project-management category';
if(substr_count($migration,"'zoho-projects'")<8)$errors[]='069 does not consistently target the zoho-projects product slug';

// Evidence-first / Unknown != Unsupported contract.
foreach([
    'vendor_owned,verification_status,confidence',
    "1,'verified','high',NOW()",
    "'not_yet_verified',0",
    'product_capability_evidence',
    'last_reviewed_at'
] as $needle){
    if(!str_contains($migration,$needle))$errors[]="069 missing required evidence/integrity marker: {$needle}";
}
if(stripos($migration,"'not_supported'")!==false)$errors[]='069 must not infer unsupported from missing evidence';
if(stripos($migration,'g2.com')!==false||stripos($migration,'capterra')!==false)$errors[]='069 contains prohibited third-party review data';

$officialDomains=['zoho.com','help.zoho.com'];
foreach($officialDomains as $domain){
    if(!str_contains($migration,$domain))$errors[]="069 missing expected first-party evidence domain {$domain}";
}

// Every asserted capability fact must carry a source URL and be linkable through product_capability_evidence.
if(!preg_match('/CREATE TEMPORARY TABLE cat69_facts\([^;]*source_url TEXT/s',$migration))$errors[]='069 fact table does not retain source_url';
$factCount=preg_match_all('/\(\'zoho-projects\',\'pm-[^\']+\',\'supported\',/',$migration);
if($factCount<8)$errors[]="069 has only {$factCount} explicit known capability facts; expected at least 8";
if(!str_contains($migration,'e.source_url=f.source_url'))$errors[]='069 does not link known facts to their exact evidence source';

// Deployment/integration assertions remain narrow and explicit.
if(!str_contains($migration,"d.slug='public-saas'"))$errors[]='069 missing verified public SaaS deployment fact';
if(!str_contains($migration,"CASE WHEN i.slug='api' THEN 'supported' ELSE 'not_yet_verified' END"))$errors[]='069 integration matrix does not preserve unknowns outside verified API access';

if($errors){
    fwrite(STDERR,"Catalog 069 contract failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}
echo "Catalog 069 contract passed: Zoho Projects uses existing taxonomy, {$factCount} evidence-linked known facts, and explicit unknown placeholders.\n";
