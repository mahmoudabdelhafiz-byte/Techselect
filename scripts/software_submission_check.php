<?php
$schema=file_get_contents(__DIR__.'/../db/mysql/043_software_submissions.sql');
$service=file_get_contents(__DIR__.'/../app/lib/SoftwareSubmission.php');
$api=file_get_contents(__DIR__.'/../api/software_submissions.php');
$page=file_get_contents(__DIR__.'/../software_submission.php');
$routes=file_get_contents(__DIR__.'/../.htaccess');
$fail=[];
foreach(['software_submissions','product_aliases','duplicate_detected','created_product_id'] as $n)if(strpos($schema,$n)===false)$fail[]='schema missing '.$n;
foreach(['findDuplicate','createDraftProduct',"status='draft'",'matching known alias','matching official website'] as $n)if(strpos($service,$n)===false)$fail[]='service missing '.$n;
foreach(['rateLimit','requireCsrf','sameOrigin','SOFTWARE_SUBMISSION_CREATE'] as $n)if(strpos($api,$n)===false)$fail[]='api guard missing '.$n;
foreach(['Submission does not guarantee listing','never influences TechSelectAI scores','duplicate_detected'] as $n)if(strpos($page,$n)===false)$fail[]='page disclosure missing '.$n;
foreach(['^submit-software/?$','^api/software-submissions'] as $n)if(strpos($routes,$n)===false)$fail[]='route missing '.$n;
if($fail){fwrite(STDERR,implode("\n",$fail)."\n");exit(1);}echo "software_submission_check: OK\n";
