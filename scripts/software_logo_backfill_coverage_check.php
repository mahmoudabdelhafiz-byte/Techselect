<?php
$manager=file_get_contents(__DIR__.'/../app/lib/SoftwareLogoManager.php');
$backfill=file_get_contents(__DIR__.'/software_logo_backfill.php');
$audit=file_get_contents(__DIR__.'/software_logo_integrity_audit.php');
$fail=[];
$needManager=[
    'private const MAX_HTML_BYTES=1572864;',
    'private const MAX_LOGO_BYTES=3145728;',
    '$overflow=false',
    "throw new RuntimeException('response_too_large')",
    'commonOfficialIconCandidates',
    "'/favicon.ico'",
    "'/apple-touch-icon.png'",
    'NEGATIVE_CONTEXT',
    'identityMatches',
    'scorePageImage',
    'acceptableCandidates',
    'assessStoredLogo',
    'stored_source_not_current_high_confidence_candidate',
];
foreach($needManager as $needle){if(strpos($manager,$needle)===false)$fail[]='manager missing: '.$needle;}
$needBackfill=[
    'SoftwareLogoManager::acceptableCandidates',
    'candidate_failures',
    'foreach($candidates as $candidate)',
    'SoftwareLogoManager::cache',
    'RETRY',
    '--refresh',
    '--slug=',
    'vendor_name',
];
foreach($needBackfill as $needle){if(strpos($backfill,$needle)===false)$fail[]='backfill missing: '.$needle;}
$needAudit=['SoftwareLogoManager::assessStoredLogo','same_cached_image_used_by_different_vendors','hash_file','Audit is report-only'];
foreach($needAudit as $needle){if(strpos($audit,$needle)===false)$fail[]='audit missing: '.$needle;}
if(strpos($manager,'logo_source_not_official_host')===false)$fail[]='official-host restriction must remain enforced';
if(strpos($manager,"'customer'")===false||strpos($manager,"'testimonial'")===false)$fail[]='customer/testimonial logo-wall exclusions must remain enforced';
if($fail){foreach($fail as $f)fwrite(STDERR,$f.PHP_EOL);exit(1);}echo "Software logo identity and coverage checks passed.\n";
