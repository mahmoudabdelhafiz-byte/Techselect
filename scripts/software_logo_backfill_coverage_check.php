<?php
$manager=file_get_contents(__DIR__.'/../app/lib/SoftwareLogoManager.php');
$backfill=file_get_contents(__DIR__.'/software_logo_backfill.php');
$fail=[];
$needManager=[
    'private const MAX_HTML_BYTES=1572864;',
    'private const MAX_LOGO_BYTES=3145728;',
    '$overflow=false',
    "throw new RuntimeException('response_too_large')",
    'commonOfficialIconCandidates',
    "'/favicon.ico'",
    "'/apple-touch-icon.png'",
];
foreach($needManager as $needle){if(strpos($manager,$needle)===false)$fail[]='manager missing: '.$needle;}
$needBackfill=[
    '>=75',
    'candidate_failures',
    'foreach($candidates as $candidate)',
    'SoftwareLogoManager::cache',
    'RETRY',
];
foreach($needBackfill as $needle){if(strpos($backfill,$needle)===false)$fail[]='backfill missing: '.$needle;}
if(strpos($manager,'logo_source_not_official_host')===false)$fail[]='official-host restriction must remain enforced';
if($fail){foreach($fail as $f)fwrite(STDERR,$f.PHP_EOL);exit(1);}echo "Software logo backfill coverage checks passed.\n";
