<?php
$m=file_get_contents(__DIR__.'/../db/mysql/088_automatic_public_review_publication.sql');
$w=file_get_contents(__DIR__.'/community_review_automation.php');
$errors=[];
foreach([
 'community_intelligence_auto_publish_settings',
 'VALUES(1,1)',
 "policy_status='pending_review'",
 "access_policy='pending_review'",
 'trg_public_review_connector_auto_policy_bi',
 'trg_public_review_source_auto_policy_bi',
 "source_type IN ('g2','capterra')",
 'auto_publish_manual_hold_reason=NULL'
] as $needle) if(strpos($m,$needle)===false)$errors[]="migration missing: {$needle}";
foreach([
 'CommunitySourceCollectors::due',
 'CommunitySourceCollectors::run',
 'CommunitySourceCollectors::analyzePending',
 'CommunitySourceCollectors::purgeExpiredText'
] as $needle) if(strpos($w,$needle)===false)$errors[]="worker missing: {$needle}";
if(stripos($w,'requireRole')!==false||stripos($w,'admin_required')!==false)$errors[]='worker must not require admin/reviewer approval';
if($errors){fwrite(STDERR,implode("\n",$errors)."\n");exit(1);}echo "Zero-touch public review automation contract passed.\n";
