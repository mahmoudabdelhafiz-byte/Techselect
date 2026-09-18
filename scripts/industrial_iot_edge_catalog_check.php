<?php

declare(strict_types=1);

$root=dirname(__DIR__);
$migration=$root.'/db/mysql/130_industrial_iot_edge_data_platforms_catalog.sql';
$sql=@file_get_contents($migration);
$errors=[];

if($sql===false){
    fwrite(STDERR,"Missing migration: db/mysql/130_industrial_iot_edge_data_platforms_catalog.sql\n");
    exit(1);
}

$category='industrial-iot-edge-data-platforms';
$products=[
    'highbyte-intelligence-hub',
    'litmus-edge',
    'siemens-industrial-edge',
    'microsoft-azure-iot-operations',
    'hivemq-edge'
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
        $text=@file_get_contents($file)?:'';
        if(strpos($text,"'{$slug}'")!==false)$hits[]=basename($file);
    }
    if($hits)$errors[]="Potential duplicate catalog shell {$slug} already exists in ".implode(', ',$hits);
}

foreach([
    'not_yet_verified','product_capability_evidence','vendor_documentation',
    'product_mobile_access',"'android'","'ios'","'mobile_web'",
    'product_deployments',"'public-saas'","'on-premise'",'last_reviewed_at','Unknown != Unsupported',
    'edge-industrial-connectivity','edge-mqtt-uns-publication','edge-data-transformation',
    'edge-contextualization-modeling','edge-store-forward','edge-local-analytics-ai',
    'edge-container-app-runtime','edge-bidirectional-control','edge-cloud-enterprise-integration',
    'edge-fleet-central-management'
] as $needle){
    if(strpos($sql,$needle)===false)$errors[]="Missing industrial edge invariant: {$needle}";
}

$allowedHosts=[
    'highbyte.com','www.highbyte.com','guide.highbyte.com',
    'litmus.io','www.litmus.io','docs.litmus.io',
    'siemens.com','www.siemens.com',
    'microsoft.com','www.microsoft.com','learn.microsoft.com',
    'hivemq.com','www.hivemq.com','docs.hivemq.com'
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

// Every promoted capability must resolve to a registered first-party source URL.
if(preg_match('/INSERT INTO cat130_sources VALUES\s*(.*?);\s*\n\s*INSERT INTO evidence_sources/is',$sql,$sm)){
    preg_match_all("/\\('(?:''|[^'])*','(https:\/\/(?:''|[^'])+)'/",$sm[1],$sourceMatches);
    $registered=array_fill_keys($sourceMatches[1]??[],true);
    if(preg_match('/INSERT INTO cat130_facts VALUES\s*(.*?);\s*\n\s*INSERT INTO product_capabilities/is',$sql,$fm)){
        preg_match_all("/\\('(?:''|[^'])*','(?:''|[^'])*','(?:''|[^'])*',[0-9.]+,'(?:''|[^'])*','(https:\/\/(?:''|[^'])+)'\\)/",$fm[1],$factMatches);
        foreach(array_unique($factMatches[1]??[]) as $url){
            if(!isset($registered[$url]))$errors[]="Capability source URL is not registered in cat130_sources: {$url}";
        }
    } else {
        $errors[]='Could not parse cat130_facts block for evidence-link validation.';
    }
} else {
    $errors[]='Could not parse cat130_sources block for evidence-link validation.';
}

// Preserve suite/module/commercial-feature boundaries.
foreach([
    "'litmus-edge','edge-mqtt-uns-publication','partially_supported',0.980",
    "'litmus-edge','edge-bidirectional-control','partially_supported',0.960",
    "'litmus-edge','edge-fleet-central-management','partially_supported',0.990",
    "'siemens-industrial-edge','edge-data-transformation','partially_supported',0.980",
    "'siemens-industrial-edge','edge-contextualization-modeling','partially_supported',0.970",
    "'microsoft-azure-iot-operations','edge-bidirectional-control','partially_supported',0.960",
    "'microsoft-azure-iot-operations','edge-fleet-central-management','partially_supported',0.980",
    "'hivemq-edge','edge-data-transformation','partially_supported',0.990",
    "'hivemq-edge','edge-contextualization-modeling','partially_supported',0.970",
    "'hivemq-edge','edge-store-forward','partially_supported',0.990",
    "'hivemq-edge','edge-bidirectional-control','partially_supported',0.980"
] as $required){
    if(strpos($sql,$required)===false)$errors[]="Required industrial edge scope boundary missing: {$required}";
}

foreach([
    'governed Unified Namespace product is Litmus Unify rather than assumed core Edge entitlement',
    'companion Litmus Edge Manager product rather than assumed inside every Litmus Edge license',
    'exact transformation scope depends on installed apps',
    'contextualization is app-dependent rather than assumed base-runtime functionality',
    'general-purpose southbound control of arbitrary OT protocols is not inferred',
    'standalone vendor-neutral edge fleet manager is not inferred',
    'require the commercial feature set rather than the open-source base',
    'general-purpose digital-twin/asset-modeling layer is not inferred',
    'commercial HiveMQ Edge feature',
    'southbound control is currently adapter-specific'
] as $phrase){
    if(strpos($sql,$phrase)===false)$errors[]="Missing explicit industrial edge limitation text: {$phrase}";
}

// Do not infer analytics/app-hosting from data processing or containerized deployment.
$mustRemainUnknown=[
    ['highbyte-intelligence-hub','edge-local-analytics-ai'],
    ['highbyte-intelligence-hub','edge-container-app-runtime'],
    ['siemens-industrial-edge','edge-store-forward'],
    ['siemens-industrial-edge','edge-bidirectional-control'],
    ['microsoft-azure-iot-operations','edge-local-analytics-ai'],
    ['microsoft-azure-iot-operations','edge-container-app-runtime'],
    ['hivemq-edge','edge-local-analytics-ai'],
    ['hivemq-edge','edge-container-app-runtime'],
    ['hivemq-edge','edge-fleet-central-management']
];
foreach($mustRemainUnknown as [$product,$cap]){
    if(strpos($sql,"'{$product}','{$cap}','supported'")!==false ||
       strpos($sql,"'{$product}','{$cap}','partially_supported'")!==false){
        $errors[]="Unverified capability must remain not_yet_verified: {$product} / {$cap}";
    }
}

// Current ownership hygiene: do not reintroduce stale PTC attribution for Kepware in this batch.
foreach(['kepware-edge',"'PTC','ptc'"] as $needle){
    if(stripos($sql,$needle)!==false)$errors[]="Stale/excluded Kepware ownership shell found in batch 130: {$needle}";
}

// Deployment: four explicit on-prem products, Siemens also has IEM Cloud SaaS; Azure hybrid remains unmapped.
if(strpos($sql,"WHERE p.slug IN('highbyte-intelligence-hub','litmus-edge','siemens-industrial-edge','hivemq-edge')")===false){
    $errors[]='Explicit industrial edge on-premises deployment set is missing or broadened.';
}
if(strpos($sql,"WHERE p.slug='siemens-industrial-edge'")===false){
    $errors[]='Siemens Industrial Edge public-SaaS management option must remain explicit.';
}
if(strpos($sql,'Azure IoT Operations has an edge data plane plus Azure cloud control plane; do not collapse that hybrid architecture into a generic SaaS/on-premises label here.')===false){
    $errors[]='Azure hybrid deployment boundary must remain explicit.';
}
if(preg_match('/INSERT INTO product_deployments.*?d\.slug=\'public-saas\'.*?WHERE p\.slug=\'([^\']+)\'/s',$sql,$saasMatch)){
    if($saasMatch[1]!=='siemens-industrial-edge')$errors[]='Public SaaS promotion must remain limited to Siemens Industrial Edge IEM Cloud in batch 130.';
} else {
    $errors[]='Could not isolate explicit public-SaaS promotion.';
}
if(strpos($sql,"'microsoft-azure-iot-operations'")!==false && preg_match("/d\.slug='(?:public-saas|on-premise)'.*?microsoft-azure-iot-operations/s",$sql)){
    $errors[]='Do not collapse Azure IoT Operations hybrid deployment into generic deployment labels in batch 130.';
}

// Platform-specific mobile access remains unknown for all five products.
if(strpos($sql,"SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000")===false){
    $errors[]='Industrial edge mobile access must default to not_yet_verified.';
}
if(preg_match("/'supported','supported','vendor_documentation'.*WHERE p\.slug IN\([^;]*(highbyte-intelligence-hub|litmus-edge|siemens-industrial-edge|microsoft-azure-iot-operations|hivemq-edge)/s",$sql)){
    $errors[]='Do not infer Android/iOS/mobile-web support from administrative/browser interfaces.';
}

if($errors){
    fwrite(STDERR,"Industrial IoT/edge catalog check failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}

echo "Industrial IoT/edge catalog contract passed: 1 canonical category, 5 current products, first-party evidence, suite/commercial boundaries, explicit unknowns, current ownership and deployment/mobile discipline.\n";
