<?php
$files=[
  __DIR__.'/../api/community_intelligence_admin.php',
  __DIR__.'/../community_intelligence_admin.php',
  __DIR__.'/../community_intelligence_admin.js',
  __DIR__.'/../db/mysql/041_community_intelligence_approval.sql',
  __DIR__.'/../.htaccess',
];
foreach($files as $f){if(!is_file($f)){fwrite(STDERR,"Missing $f\n");exit(1);}}
$api=file_get_contents($files[0]);
foreach(['approve','reject','request_more_evidence','publication_threshold_not_met','COMMUNITY_INTELLIGENCE_REVIEW','source_type_count','confidence_score'] as $n){if(strpos($api,$n)===false){fwrite(STDERR,"Missing API contract: $n\n");exit(1);}}
$js=file_get_contents($files[2]);foreach(['Approve Intelligence','Request more evidence','excluded signal','source_quality','independence_score','specificity_score'] as $n){if(strpos($js,$n)===false){fwrite(STDERR,"Missing UI contract: $n\n");exit(1);}}
$routes=file_get_contents($files[4]);foreach(['community-intelligence-admin','api/community-intelligence'] as $n){if(strpos($routes,$n)===false){fwrite(STDERR,"Missing route: $n\n");exit(1);}}
echo "community_intelligence_admin_check: OK\n";
