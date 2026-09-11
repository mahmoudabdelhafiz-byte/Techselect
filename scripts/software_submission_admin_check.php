<?php
$api=file_get_contents(__DIR__.'/../api/software_submission_admin.php');$page=file_get_contents(__DIR__.'/../software_submission_admin.php');$sql=file_get_contents(__DIR__.'/../db/mysql/044_submission_review_history.sql');$ht=file_get_contents(__DIR__.'/../.htaccess');$fail=[];
foreach(['start_review','request_information','approve_for_draft','reject','link_existing','SoftwareSubmission::createDraftProduct','Security::audit'] as $n)if(strpos($api,$n)===false)$fail[]='api missing '.$n;
foreach(['software_submission_reviews','snapshot_json','linked_product_id'] as $n)if(strpos($sql,$n)===false)$fail[]='schema missing '.$n;
foreach(['Approve to draft','Request info','Link existing','History'] as $n)if(strpos($page,$n)===false)$fail[]='ui missing '.$n;
foreach(['software-submission-admin','software_submission_admin.php'] as $n)if(strpos($ht,$n)===false)$fail[]='route missing '.$n;
if(strpos($api,"'draft'")!==false)$fail[]='admin api should delegate draft creation rather than create active/draft rows directly';
if($fail){fwrite(STDERR,implode("\n",$fail)."\n");exit(1);}echo "software_submission_admin_check: OK\n";
