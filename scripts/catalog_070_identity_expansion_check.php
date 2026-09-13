<?php
$root=dirname(__DIR__);$errors=[];
$migrationPath=$root.'/db/mysql/070_expand_identity_catalog_known_products.sql';
$migration=is_file($migrationPath)?(file_get_contents($migrationPath)?:''):'';
$products=['wave-connect','spreadly','tapt'];

if($migration==='')$errors[]='missing or empty migration 070_expand_identity_catalog_known_products.sql';

// Reuse the existing category/modules/capabilities; this batch must not create parallel taxonomy.
foreach(['INSERT INTO categories','INSERT INTO modules','INSERT INTO capabilities'] as $forbidden){
    if(stripos($migration,$forbidden)!==false)$errors[]="070 must not create duplicate taxonomy via {$forbidden}";
}
if(!str_contains($migration,"slug='corporate-identity-digital-business-cards'"))$errors[]='070 does not reuse the existing identity category';
if(!str_contains($migration,'ON DUPLICATE KEY UPDATE'))$errors[]='070 is not idempotent for reruns';

foreach($products as $slug){
    if(substr_count($migration,"'{$slug}'")<6)$errors[]="070 does not consistently target {$slug}";
    foreach(glob($root.'/db/mysql/*.sql')?:[] as $file){
        if(basename($file)==='070_expand_identity_catalog_known_products.sql')continue;
        $src=file_get_contents($file)?:'';
        if(str_contains($src,"'{$slug}'"))$errors[]="{$slug} is already referenced by earlier migration ".basename($file);
    }
}

// Evidence-first / Unknown != Unsupported.
foreach([
    'vendor_owned,verification_status,confidence',
    "1,'verified','high',NOW()",
    "'not_yet_verified',0",
    'product_capability_evidence',
    'last_reviewed_at'
] as $needle){
    if(!str_contains($migration,$needle))$errors[]="070 missing required evidence/integrity marker: {$needle}";
}
if(stripos($migration,"'not_supported'")!==false)$errors[]='070 must not infer unsupported from missing evidence';
if(stripos($migration,'g2.com')!==false||stripos($migration,'capterra')!==false)$errors[]='070 contains prohibited third-party review ingestion';

foreach(['wavecnct.com','spreadly.app','tapt.io','help.tapt.io'] as $domain){
    if(!str_contains($migration,$domain))$errors[]="070 missing first-party evidence domain {$domain}";
}

if(!preg_match('/CREATE TEMPORARY TABLE cat70_facts\([^;]*source_url TEXT/s',$migration))$errors[]='070 fact table does not retain source_url';
if(!str_contains($migration,'e.source_url=f.source_url'))$errors[]='070 does not link known facts to exact evidence sources';

$minimumFacts=['wave-connect'=>9,'spreadly'=>10,'tapt'=>8];
foreach($minimumFacts as $slug=>$minimum){
    $count=preg_match_all('/\(\''.preg_quote($slug,'/').'\',\'[^\']+\',\'supported\',/',$migration);
    if($count<$minimum)$errors[]="070 has only {$count} explicit known facts for {$slug}; expected at least {$minimum}";
}

if(!str_contains($migration,"d.slug='public-saas'"))$errors[]='070 missing verified public SaaS deployment facts';
if(!str_contains($migration,"p.slug='spreadly' AND i.slug IN('microsoft-entra-id','crm','api')"))$errors[]='070 missing conservative Spreadly integration assertions';
if(!str_contains($migration,"ELSE 'not_yet_verified' END"))$errors[]='070 integration matrix does not preserve explicit unknowns';

if($errors){
    fwrite(STDERR,"Catalog 070 identity expansion contract failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}
echo "Catalog 070 identity expansion contract passed: Wave Connect, Spreadly and Tapt reuse the existing taxonomy with first-party evidence, linked known facts and explicit unknowns.\n";
