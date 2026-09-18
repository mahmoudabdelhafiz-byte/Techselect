<?php

declare(strict_types=1);

$root=dirname(__DIR__);
$migration=$root.'/db/mysql/115_identity_governance_administration_catalog.sql';
$sql=@file_get_contents($migration);
$errors=[];

if($sql===false){
    fwrite(STDERR,"Missing migration: db/mysql/115_identity_governance_administration_catalog.sql\n");
    exit(1);
}

$category='identity-governance-administration';
$products=[
    'sailpoint-identity-security-cloud',
    'saviynt-identity-governance-administration',
    'omada-identity-cloud',
    'one-identity-manager',
    'ibm-verify-identity-governance'
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
    'iga-lifecycle-provisioning','iga-access-requests','iga-entitlements-roles','iga-application-onboarding',
    'iga-access-reviews','iga-segregation-duties','iga-risk-analytics','iga-nonhuman-external'
] as $needle){
    if(strpos($sql,$needle)===false)$errors[]="Missing IGA invariant: {$needle}";
}

$allowedHosts=[
    'sailpoint.com','www.sailpoint.com','documentation.sailpoint.com',
    'saviynt.com','www.saviynt.com',
    'omadaidentity.com','www.omadaidentity.com','documentation.omadaidentity.com',
    'oneidentity.com','www.oneidentity.com',
    'ibm.com','www.ibm.com'
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

// Every promoted capability must resolve to an evidence_source row by exact source URL.
if(preg_match('/INSERT INTO cat115_sources VALUES\s*(.*?);\s*\n\s*INSERT INTO evidence_sources/is',$sql,$sm)){
    preg_match_all("/\\('(?:''|[^'])*','(https:\/\/(?:''|[^'])+)'/",$sm[1],$sourceMatches);
    $registered=array_fill_keys($sourceMatches[1]??[],true);
    if(preg_match('/INSERT INTO cat115_facts VALUES\s*(.*?);\s*\n\s*INSERT INTO product_capabilities/is',$sql,$fm)){
        preg_match_all("/\\('(?:''|[^'])*','(?:''|[^'])*','(?:''|[^'])*',[0-9.]+,'(?:''|[^'])*','(https:\/\/(?:''|[^'])+)'\\)/",$fm[1],$factMatches);
        foreach(array_unique($factMatches[1]??[]) as $url){
            if(!isset($registered[$url]))$errors[]="Capability source URL is not registered in cat115_sources: {$url}";
        }
    } else {
        $errors[]='Could not parse cat115_facts block for evidence-link validation.';
    }
} else {
    $errors[]='Could not parse cat115_sources block for evidence-link validation.';
}

// Preserve explicit scope boundaries rather than broad IGA-family inference.
foreach([
    "'saviynt-identity-governance-administration','iga-segregation-duties','supported'",
    "'one-identity-manager','iga-segregation-duties','supported'",
    "'one-identity-manager','iga-nonhuman-external','supported'",
    "'ibm-verify-identity-governance','iga-nonhuman-external','supported'"
] as $forbidden){
    if(strpos($sql,$forbidden)!==false)$errors[]="Unverified IGA capability must remain not_yet_verified: {$forbidden}";
}

if(strpos($sql,"'sailpoint-identity-security-cloud','iga-nonhuman-external','partially_supported',0.950")===false){
    $errors[]='SailPoint non-human/external governance must preserve the partial-scope boundary.';
}
if(strpos($sql,"'omada-identity-cloud','iga-nonhuman-external','partially_supported',0.970")===false){
    $errors[]='Omada non-human/external governance must preserve the partial-scope boundary.';
}

// Deployment rows are intentionally narrower than vendor-wide/cloud positioning.
if(strpos($sql,"WHERE p.slug IN('sailpoint-identity-security-cloud','omada-identity-cloud')")===false){
    $errors[]='Only explicitly evidenced SailPoint/Omada public SaaS deployment rows should be promoted.';
}
if(strpos($sql,"WHERE p.slug='ibm-verify-identity-governance'")===false){
    $errors[]='IBM Verify Identity Governance on-premises deployment evidence must remain explicit.';
}
if(preg_match('/-- Deployment is promoted only where current product-specific evidence is explicit\.(.*?)-- Do not infer platform-specific mobile access/s',$sql,$dm)){
    foreach(['saviynt-identity-governance-administration','one-identity-manager'] as $slug){
        if(strpos($dm[1],"'{$slug}'")!==false)$errors[]="Deployment must remain unverified for {$slug} unless product-specific evidence is added.";
    }
} else {
    $errors[]='Could not isolate IGA deployment block.';
}

// Platform-specific mobile access remains unknown for all five products.
if(strpos($sql,"SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000")===false){
    $errors[]='IGA mobile access must be inserted as not_yet_verified.';
}
if(preg_match("/'supported','supported','vendor_documentation'.*WHERE p\.slug IN\([^;]*(sailpoint-identity-security-cloud|saviynt-identity-governance-administration|omada-identity-cloud|one-identity-manager|ibm-verify-identity-governance)/s",$sql)){
    $errors[]='Do not infer supported platform-specific mobile access for IGA products.';
}

if($errors){
    fwrite(STDERR,"IGA catalog check failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}

echo "IGA catalog contract passed: 1 canonical category, 5 current products, first-party evidence, exact evidence links, explicit unknowns, deployment/mobile discipline and ranking neutrality.\n";
