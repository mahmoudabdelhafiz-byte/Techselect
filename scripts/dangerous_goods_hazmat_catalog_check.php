<?php
declare(strict_types=1);

$root=dirname(__DIR__);
$migration=$root.'/db/mysql/138_dangerous_goods_hazmat_compliance_catalog.sql';
$sql=@file_get_contents($migration);
$errors=[];

if($sql===false){fwrite(STDERR,"Missing migration 138\n");exit(1);}

$category='dangerous-goods-hazmat-compliance';
$products=['hazcheck-validate','labelmaster-dgis','dgoffice-net','lisam-exess','shiphazmat'];

if(strpos($sql,"'{$category}'")===false)$errors[]="Missing category {$category}";
foreach($products as $slug){
    if(substr_count($sql,"'{$slug}'")<3)$errors[]="Product {$slug} is not carried through migration";
}

foreach(array_merge([$category],$products) as $slug){
    foreach(glob($root.'/db/mysql/*.sql')?:[] as $file){
        if(realpath($file)===realpath($migration))continue;
        if(strpos((string)@file_get_contents($file),"'{$slug}'")!==false)$errors[]="Duplicate catalog shell {$slug} in ".basename($file);
    }
}

foreach([
    'Unknown != Unsupported','product_capability_evidence','vendor_documentation','product_deployments','product_mobile_access',
    'dg-imdg-validation','dg-iata-icao-compliance','dg-adr-rid-compliance','dg-un-classification',
    'dg-packaging-labeling','dg-segregation-stowage','dg-documents-manifests','dg-sds-section14',
    'dg-regulatory-updates','dg-multimodal-compliance','dg-terminal-port-workflows','dg-enterprise-integration',
    'mobile-access','dangerous-goods-hazmat-compliance-mobile-android-app',
    'dangerous-goods-hazmat-compliance-mobile-ios-app','dangerous-goods-hazmat-compliance-mobile-web-access'
] as $needle){
    if(strpos($sql,$needle)===false)$errors[]="Missing dangerous-goods invariant: {$needle}";
}

$allowed=[
    'hazcheck.com','www.hazcheck.com',
    'labelmaster.com','www.labelmaster.com','blog.labelmaster.com',
    'dgis.com','www.dgis.com',
    'dgm-sdg.com','www.dgm-sdg.com',
    'lisam.com','www.lisam.com',
    'shiphazmat.net','www.shiphazmat.net','blog.shiphazmat.net'
];
preg_match_all('#https://[^\s\'"]+#',$sql,$m);
foreach(array_unique($m[0]??[]) as $url){
    $url=rtrim($url,');,');
    $host=strtolower((string)parse_url($url,PHP_URL_HOST));
    if($host===''||!in_array($host,$allowed,true))$errors[]="Unapproved evidence/vendor host: {$host}";
}

foreach(['g2.com','capterra','fit_score','overall_score','recommendation_rank','popularity_score','sponsored_rank'] as $bad){
    if(stripos($sql,$bad)!==false)$errors[]="Prohibited catalog coupling/source: {$bad}";
}

foreach([
    "'hazcheck-validate','dg-adr-rid-compliance','partially_supported',0.980",
    "'hazcheck-validate','dg-enterprise-integration','partially_supported',0.990",
    "'hazcheck-validate','dg-terminal-port-workflows','partially_supported',0.980",
    "'labelmaster-dgis','dg-multimodal-compliance','partially_supported',0.970",
    "'dgoffice-net','dg-imdg-validation','partially_supported',0.990",
    "'dgoffice-net','dg-iata-icao-compliance','partially_supported',0.990",
    "'dgoffice-net','dg-adr-rid-compliance','partially_supported',0.990",
    "'dgoffice-net','dg-sds-section14','partially_supported',0.990",
    "'dgoffice-net','dg-enterprise-integration','partially_supported',0.990",
    "'lisam-exess','dg-imdg-validation','partially_supported',0.970",
    "'lisam-exess','dg-iata-icao-compliance','partially_supported',0.970",
    "'lisam-exess','dg-adr-rid-compliance','partially_supported',0.960",
    "'lisam-exess','dg-multimodal-compliance','partially_supported',0.960",
    "'shiphazmat','dg-multimodal-compliance','partially_supported',0.980"
] as $req){
    if(strpos($sql,$req)===false)$errors[]="Required suite/evidence boundary missing: {$req}";
}

foreach([
    'API connectivity from Validate Enterprise',
    'air IATA/ICAO and RID support are not inferred',
    'ADR/RID coverage is not inferred',
    'transport modes are selected by license/module',
    'selected number of modes rather than universally including all modes',
    'full IMDG shipment validation is not inferred',
    'full air-shipment declaration/acceptance validation is not inferred',
    'current reviewed evidence does not verify equivalent RID shipment functionality',
    'is not treated as a multimodal shipment-execution engine',
    'ADR/RID support is not inferred from current reviewed evidence'
] as $phrase){
    if(strpos($sql,$phrase)===false)$errors[]="Missing dangerous-goods limitation text: {$phrase}";
}

if(strpos($sql,"WHERE p.slug='hazcheck-validate'")===false)$errors[]='Hazcheck SaaS deployment mapping missing';
if(strpos($sql,"WHERE p.slug='labelmaster-dgis'")===false)$errors[]='DGIS hosted deployment mapping missing';
if(strpos($sql,"WHERE p.slug='shiphazmat'")===false)$errors[]='ShipHazmat hosted deployment/mobile mapping missing';
if(strpos($sql,"WHERE p.slug='lisam-exess'")===false)$errors[]='ExESS on-prem deployment mapping missing';
if(strpos($sql,"DGOffice.net is described as online software with optional local synchronization/hybrid setup")===false)$errors[]='DGOffice deployment boundary missing';
if(strpos($sql,"ExESS supports cloud access")===false)$errors[]='ExESS cloud-vs-public-SaaS boundary missing';

if(strpos($sql,"SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000")===false)$errors[]='Mobile defaults must remain unknown';
if(strpos($sql,"ON DUPLICATE KEY UPDATE product_id=VALUES(product_id);")===false)$errors[]='Mobile default seeding must preserve later reviewed facts';
if(strpos($sql,"p.slug='shiphazmat' AND pma.platform='mobile_web'")===false)$errors[]='ShipHazmat mobile-web evidence mapping missing';
if(strpos($sql,"Responsive browser use from tablets and other smart devices is explicitly documented")===false)$errors[]='ShipHazmat mobile-web scope boundary missing';

if(strpos($sql,"'hazcheck-validate','dg-iata-icao-compliance','supported'")!==false)$errors[]='Hazcheck IATA support must not be inferred';
if(strpos($sql,"'labelmaster-dgis','dg-adr-rid-compliance','supported'")!==false)$errors[]='DGIS ADR/RID support must not be inferred';
if(strpos($sql,"'lisam-exess','dg-segregation-stowage','supported'")!==false)$errors[]='ExESS segregation/stowage must not be inferred';
if(strpos($sql,"'shiphazmat','dg-adr-rid-compliance','supported'")!==false)$errors[]='ShipHazmat ADR/RID support must not be inferred';

if($errors){
    fwrite(STDERR,"Dangerous goods / hazmat catalog check failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}
echo "Dangerous goods / hazmat catalog contract passed: 1 canonical category, 5 current products, first-party evidence, explicit suite/module boundaries, conservative deployment/mobile handling and ranking neutrality.\n";
