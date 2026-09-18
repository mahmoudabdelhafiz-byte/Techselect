<?php

declare(strict_types=1);

$root=dirname(__DIR__);
$migration=$root.'/db/mysql/117_terminal_operating_system_catalog.sql';
$sql=@file_get_contents($migration);
$errors=[];

if($sql===false){
    fwrite(STDERR,"Missing migration: db/mysql/117_terminal_operating_system_catalog.sql\n");
    exit(1);
}

$category='terminal-operating-systems';
$products=[
    'kaleris-n4-tos',
    'tideworks-mainsail',
    'rbs-tops-expert',
    'cyberlogitec-opus-terminal',
    'total-soft-bank-catos'
];

if(strpos($sql,"'{$category}'")===false)$errors[]="Missing category {$category}";
foreach($products as $slug){
    if(substr_count($sql,"'{$slug}'")<3)$errors[]="Product {$slug} is not carried through product/evidence/mobile or deployment rows";
}

$migrations=glob($root.'/db/mysql/*.sql')?:[];
foreach(array_merge([$category],$products) as $slug){
    $hits=[];
    foreach($migrations as $file){
        if(realpath($file)===realpath($migration))continue;
        if(in_array(basename($file),['139_tos_depth_taxonomy_foundation.sql','140_tos_kaleris_n4_depth_evidence.sql','141_tos_market_names_zodiac_master_terminal.sql','142_tos_cyberlogitec_opus_depth_evidence.sql'],true))continue;
        $text=@file_get_contents($file)?:'';
        if(strpos($text,"'{$slug}'")!==false)$hits[]=basename($file);
    }
    if($hits)$errors[]="Potential duplicate catalog shell {$slug} already exists in ".implode(', ',$hits);
}

foreach([
    'not_yet_verified','product_capability_evidence','vendor_documentation',
    'product_mobile_access',"'android'","'ios'","'mobile_web'",
    'product_deployments',"'public-saas'","'on-premise'",'last_reviewed_at','Unknown != Unsupported',
    'tos-vessel-berth-planning','tos-yard-planning-inventory','tos-gate-truck-operations','tos-rail-operations',
    'tos-equipment-dispatch-control','tos-automation-ecs','tos-edi-api-integrations','tos-kpi-visibility',
    'tos-billing-financial','tos-special-cargo-controls'
] as $needle){
    if(strpos($sql,$needle)===false)$errors[]="Missing TOS invariant: {$needle}";
}

$allowedHosts=[
    'kaleris.com','www.kaleris.com',
    'tideworks.com','www.tideworks.com',
    'rbs-tops.com','www.rbs-tops.com','rbs-emea.com','www.rbs-emea.com',
    'cyberlogitec.com','www.cyberlogitec.com',
    'tsb.co.kr','www.tsb.co.kr'
];
preg_match_all('#https://[^\s\'\"]+#',$sql,$matches);
foreach(array_unique($matches[0]??[]) as $url){
    $url=rtrim($url,');,');
    $host=strtolower((string)parse_url($url,PHP_URL_HOST));
    if($host===''||!in_array($host,$allowedHosts,true))$errors[]="Non-first-party or unapproved host: {$host} ({$url})";
}

foreach(['g2.com','capterra','consultation_recommendations','recommendation_rank','Scoring::','overall_score','fit_score'] as $needle){
    if(stripos($sql,$needle)!==false)$errors[]="Catalog migration contains prohibited source/ranking coupling: {$needle}";
}

// Every promoted capability must point to a registered first-party source URL.
if(preg_match('/INSERT INTO cat117_sources VALUES\s*(.*?);\s*\n\s*INSERT INTO evidence_sources/is',$sql,$sm)){
    preg_match_all("/\\('(?:''|[^'])*','(https:\/\/(?:''|[^'])+)'/",$sm[1],$sourceMatches);
    $registered=array_fill_keys($sourceMatches[1]??[],true);
    if(preg_match('/INSERT INTO cat117_facts VALUES\s*(.*?);\s*\n\s*INSERT INTO product_capabilities/is',$sql,$fm)){
        preg_match_all("/\\('(?:''|[^'])*','(?:''|[^'])*','(?:''|[^'])*',[0-9.]+,'(?:''|[^'])*','(https:\/\/(?:''|[^'])+)'\\)/",$fm[1],$factMatches);
        foreach(array_unique($factMatches[1]??[]) as $url){
            if(!isset($registered[$url]))$errors[]="Capability source URL is not registered in cat117_sources: {$url}";
        }
    } else {
        $errors[]='Could not parse cat117_facts block for evidence-link validation.';
    }
} else {
    $errors[]='Could not parse cat117_sources block for evidence-link validation.';
}

// Preserve Tideworks companion-product boundaries.
foreach([
    "'tideworks-mainsail','tos-vessel-berth-planning','partially_supported',0.950",
    "'tideworks-mainsail','tos-yard-planning-inventory','partially_supported',0.950",
    "'tideworks-mainsail','tos-rail-operations','partially_supported',0.940",
    "'tideworks-mainsail','tos-equipment-dispatch-control','partially_supported',0.950",
    "'tideworks-mainsail','tos-edi-api-integrations','partially_supported',0.960"
] as $required){
    if(strpos($sql,$required)===false)$errors[]="Tideworks companion-product boundary missing: {$required}";
}
if(strpos($sql,'companion Spinnaker')===false)$errors[]='Tideworks planning limitations must mention companion Spinnaker.';
if(strpos($sql,'companion EDI Porter')===false)$errors[]='Tideworks EDI boundary must mention companion EDI Porter.';

// Preserve other known scope boundaries.
if(strpos($sql,"'rbs-tops-expert','tos-billing-financial','partially_supported',0.950")===false){
    $errors[]='RBS billing/financial scope must remain partial rather than native-billing inference.';
}
if(strpos($sql,"'cyberlogitec-opus-terminal','tos-kpi-visibility','partially_supported',0.950")===false){
    $errors[]='CyberLogitec analytics scope must preserve the OPUS DigiPort companion boundary.';
}
if(strpos($sql,'separate OPUS DigiPort product')===false){
    $errors[]='CyberLogitec digital-twin companion-product boundary must remain explicit.';
}

// Special cargo remains unknown until product-specific evidence is researched.
foreach($products as $slug){
    if(strpos($sql,"'{$slug}','tos-special-cargo-controls','supported'")!==false ||
       strpos($sql,"'{$slug}','tos-special-cargo-controls','partially_supported'")!==false){
        $errors[]="Special-cargo support must remain not_yet_verified in batch 117 for {$slug}.";
    }
}

// Deployment promotion is intentionally narrow and product-specific.
if(strpos($sql,"WHERE p.slug='kaleris-n4-tos'")===false){
    $errors[]='Kaleris N4 on-premises deployment evidence must remain explicit.';
}
if(strpos($sql,"WHERE p.slug='tideworks-mainsail'")===false){
    $errors[]='Tideworks Mainsail SaaS deployment evidence must remain explicit.';
}
if(strpos($sql,"WHERE p.slug='rbs-tops-expert'")===false || strpos($sql,"d.slug IN('on-premise','public-saas')")===false){
    $errors[]='RBS TOPS Expert family deployment evidence must preserve both enterprise/on-prem and cloud variants.';
}
if(preg_match('/-- Promote deployment only where current product-specific evidence is explicit\.(.*?)-- Do not infer platform-specific mobile access/s',$sql,$dm)){
    foreach(['cyberlogitec-opus-terminal','total-soft-bank-catos'] as $slug){
        if(strpos($dm[1],"'{$slug}'")!==false)$errors[]="Deployment must remain unverified for {$slug} unless current product-specific evidence is added.";
    }
} else {
    $errors[]='Could not isolate TOS deployment block.';
}

// Platform-specific mobile access remains unknown for all five products.
if(strpos($sql,"SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000")===false){
    $errors[]='TOS mobile access must be inserted as not_yet_verified.';
}
if(preg_match("/'supported','supported','vendor_documentation'.*WHERE p\.slug IN\([^;]*(kaleris-n4-tos|tideworks-mainsail|rbs-tops-expert|cyberlogitec-opus-terminal|total-soft-bank-catos)/s",$sql)){
    $errors[]='Do not infer supported platform-specific mobile access for TOS products.';
}
if(strpos($sql,"ON DUPLICATE KEY UPDATE product_id=VALUES(product_id);")===false){
    $errors[]='TOS mobile default seeding must preserve later reviewed facts on migration rerun.';
}
if(strpos($sql,"ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score)")!==false){
    $errors[]='TOS migration must not reset curated mobile evidence on rerun.';
}

if($errors){
    fwrite(STDERR,"TOS catalog check failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}

echo "TOS catalog contract passed: 1 canonical category, 5 current products, first-party evidence, exact evidence links, companion-product boundaries, explicit unknowns, deployment/mobile discipline and ranking neutrality.\n";
