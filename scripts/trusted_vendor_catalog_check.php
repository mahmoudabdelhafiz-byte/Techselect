<?php
$root=dirname(__DIR__);$errors=[];
$planner=file_get_contents($root.'/app/lib/CatalogExpansionPlanner.php')?:'';
$migration=file_get_contents($root.'/db/mysql/067_trusted_vendor_security_backup_depth.sql')?:'';
$coverage=file_get_contents($root.'/db/mysql/084_vendor_coverage_public_review_automation.sql')?:'';

foreach(['crm','itsm','hrms','endpoint-security-edr','backup-disaster-recovery'] as $slug){
    if(!str_contains($planner,"'{$slug}'"))$errors[]="catalog planner does not track strategic category {$slug}";
}
foreach(['009_add_crm_catalog_batch1.sql','010_add_itsm_catalog_batch1.sql','011_add_hrms_catalog_batch1.sql','067_trusted_vendor_security_backup_depth.sql','084_vendor_coverage_public_review_automation.sql'] as $file){
    if(!is_file($root.'/db/mysql/'.$file))$errors[]="missing trusted-vendor catalog migration {$file}";
}

$endpointProducts=['microsoft-defender-for-endpoint','crowdstrike','sentinelone','sophos-endpoint'];
$backupProducts=['veeam','commvault','cohesity','acronis'];
foreach(array_merge($endpointProducts,$backupProducts) as $slug){
    if(!str_contains($migration,"'{$slug}'"))$errors[]="067 missing expected trusted product {$slug}";
}

$endpointFacts=0;$backupFacts=0;
foreach($endpointProducts as $slug)$endpointFacts+=preg_match_all('/\(\''.preg_quote($slug,'/').'\',\'endpoint-[^\']+\',/',$migration);
foreach($backupProducts as $slug)$backupFacts+=preg_match_all('/\(\''.preg_quote($slug,'/').'\',\'backup-[^\']+\',/',$migration);
if($endpointFacts<12)$errors[]="endpoint catalog has only {$endpointFacts} explicit known facts; baseline is 12";
if($backupFacts<12)$errors[]="backup/DR catalog has only {$backupFacts} explicit known facts; baseline is 12";

if(!str_contains($migration,"'verified','high',NOW()"))$errors[]='067 does not seed fresh verified first-party evidence';
if(!str_contains($migration,"'not_yet_verified',0"))$errors[]='067 does not preserve explicit unknown/not-yet-verified placeholders';
if(!str_contains($migration,'product_capability_evidence'))$errors[]='067 does not link capability facts to attributable evidence';
if(stripos($migration,'g2.com')!==false||stripos($migration,'capterra')!==false)$errors[]='067 contains prohibited third-party review ingestion';
if(stripos($migration,'sponsor')!==false||stripos($migration,'payment')!==false)$errors[]='067 contains commercial signals that must not affect catalog readiness';

foreach([
    'learn.microsoft.com','crowdstrike.com','sentinelone.com','sophos.com',
    'veeam.com','commvault.com','cohesity.com','acronis.com'
] as $domain){
    if(!str_contains($migration,$domain))$errors[]="067 missing first-party evidence domain {$domain}";
}

// Every current/future active product with a canonical vendor must receive the explicit
// software-owner relationship; this is catalog identity verification, not an endorsement.
$coverageNeedles=['vendor_product_relationships',"'software_owner'","p.status='active'","v.status='active'","verification_status='verified'",'COALESCE(NULLIF(p.website_url',"v.verification_status='verified'",'does not affect Fit Score'];
foreach($coverageNeedles as $needle)if(!str_contains($coverage,$needle))$errors[]="084 vendor coverage is missing: {$needle}";
foreach(['preferred_vendor','fit_score=','recommendation_rank'] as $needle)if(stripos($coverage,$needle)!==false)$errors[]="084 vendor identity sync must not change recommendation logic: {$needle}";

if($errors){fwrite(STDERR,"Trusted-vendor catalog contract failed:\n- ".implode("\n- ",$errors)."\n");exit(1);}echo "Trusted-vendor catalog contract passed: {$endpointFacts} endpoint facts, {$backupFacts} backup/DR facts, canonical owner coverage present.\n";
