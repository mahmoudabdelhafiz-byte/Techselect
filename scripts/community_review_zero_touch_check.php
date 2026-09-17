<?php
$m88=file_get_contents(__DIR__.'/../db/mysql/088_automatic_public_review_publication.sql');
$m89=file_get_contents(__DIR__.'/../db/mysql/089_trusted_public_review_source_bootstrap.sql');
$w=file_get_contents(__DIR__.'/community_review_automation.php');
$b=file_get_contents(__DIR__.'/../app/lib/PublicReviewConnectorBootstrap.php');
$c=file_get_contents(__DIR__.'/../app/lib/CommunitySourceCollectors.php');
$a=file_get_contents(__DIR__.'/../app/lib/AppleAppStoreReviewCollector.php');
$h=file_get_contents(__DIR__.'/../app/lib/HackerNewsReviewCollector.php');
$p=file_get_contents(__DIR__.'/../app/lib/PublicReviewSourcePolicy.php');
$ap=file_get_contents(__DIR__.'/../app/lib/CommunityIntelligenceAutoPublisher.php');
$errors=[];
foreach([
 'community_intelligence_auto_publish_settings','VALUES(1,1)',"policy_status='pending_review'","access_policy='pending_review'",'auto_publish_manual_hold_reason=NULL'
] as $needle) if(strpos($m88,$needle)===false)$errors[]="088 missing: {$needle}";
foreach([
 'trg_public_review_connector_auto_policy_bi','trg_public_review_source_auto_policy_bi',"source_type IN ('g2','capterra')",'hackernews_algolia_api','apple_app_store_reviews','stackexchange','reddit','algolia','itunes','androidpublisher',"ELSE 'restricted'"
] as $needle) if(stripos($m89,$needle)===false)$errors[]="089 missing policy semantic: {$needle}";
foreach([
 'PublicReviewConnectorBootstrap::ensure','CommunitySourceCollectors::due','CommunitySourceCollectors::run','CommunitySourceCollectors::analyzePending','CommunitySourceCollectors::purgeExpiredText'
] as $needle) if(strpos($w,$needle)===false)$errors[]="worker missing: {$needle}";
foreach([
 "'stackexchange_api','public_forum'","'rss_atom','reddit'","'hackernews_algolia_api','other_public'",'AppleAppStoreReviewCollector::discover','connectors_created','match_confidence'
] as $needle) if(strpos($b,$needle)===false)$errors[]="bootstrap missing: {$needle}";
foreach(['hackernews_algolia_api','apple_app_store_reviews','HackerNewsReviewCollector::collect','AppleAppStoreReviewCollector::collect'] as $needle)if(strpos($c,$needle)===false)$errors[]="collector registry missing: {$needle}";
foreach(['itunes.apple.com','apps.apple.com','customerreviews','confidence'] as $needle)if(strpos($a,$needle)===false)$errors[]="Apple collector missing: {$needle}";
foreach(['hn.algolia.com','news.ycombinator.com','search_by_date'] as $needle)if(strpos($h,$needle)===false)$errors[]="HN collector missing: {$needle}";
foreach(['pri-source-policy-v3','machineDecision','g2.com','capterra.com'] as $needle)if(strpos($p,$needle)===false)$errors[]="policy missing: {$needle}";
if(strpos($ap,"if(\$policy==='pending_review')\$unresolved++;")===false)$errors[]='auto-publisher must treat only pending_review source policy as unresolved';
if(strpos($ap,"['pending_review','restricted']")!==false)$errors[]='restricted source policy is a resolved exclusion and must not block publication';
if(preg_match('/g2\.com|capterra\.com/i',$b))$errors[]='bootstrap must never create G2/Capterra connectors';
if(stripos($w,'requireRole')!==false||stripos($w,'admin_required')!==false)$errors[]='worker must not require admin/reviewer approval';
if($errors){fwrite(STDERR,implode("\n",$errors)."\n");exit(1);}echo "Zero-touch public review automation contract passed.\n";