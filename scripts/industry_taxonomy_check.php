<?php

declare(strict_types=1);

$root=dirname(__DIR__);
$migration=$root.'/db/mysql/116_industry_taxonomy_seed.sql';
$api=$root.'/api/secure.php';
$front=$root.'/frontend/src/consultationContext.js';
$errors=[];

$sql=@file_get_contents($migration);
$apiText=@file_get_contents($api);
$frontText=@file_get_contents($front);

if($sql===false)$errors[]='Missing migration 116_industry_taxonomy_seed.sql.';
if($apiText===false)$errors[]='Missing api/secure.php.';
if($frontText===false)$errors[]='Missing frontend/src/consultationContext.js.';

$industries=[
 'agriculture','automotive','construction','consulting','education','energy-oil-gas',
 'engineering','financial-services','government-public-sector','healthcare','hospitality',
 'insurance','logistics-transportation','manufacturing','media-entertainment','nonprofit',
 'professional-services','real-estate','retail-ecommerce','shipping-maritime',
 'technology-software','telecommunications','utilities','other'
];

if($sql!==false){
    if(strpos($sql,'INSERT IGNORE INTO industries(name,slug)')===false){
        $errors[]='Industry seed must preserve existing rows with INSERT IGNORE.';
    }
    foreach($industries as $slug){
        if(strpos($sql,"'{$slug}'")===false)$errors[]="Missing industry slug: {$slug}";
    }
    if(substr_count($sql,"),\n(")<23)$errors[]='Expected at least 24 seeded industry rows.';
    if(stripos($sql,'DELETE FROM industries')!==false || stripos($sql,'TRUNCATE')!==false){
        $errors[]='Industry seed must not delete or renumber existing industries.';
    }
}

if($apiText!==false){
    if(strpos($apiText,'SELECT id,name FROM industries ORDER BY name')===false){
        $errors[]='Company-context API must continue loading industries from the canonical table.';
    }
    if(strpos($apiText,'SELECT id FROM industries WHERE id=? LIMIT 1')===false){
        $errors[]='Company-context API must validate submitted industry IDs.';
    }
}

if($frontText!==false){
    if(strpos($frontText,'Prefer not to say')===false){
        $errors[]='Industry dropdown must retain the optional Prefer not to say choice.';
    }
    if(strpos($frontText,'d.industries||[]')===false){
        $errors[]='Industry dropdown must continue rendering API-provided industries.';
    }
}

if($errors){
    fwrite(STDERR,"Industry taxonomy contract failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}

echo "Industry taxonomy contract passed: 24 canonical industries, non-destructive seeding, API-backed dropdown and optional null choice.\n";
