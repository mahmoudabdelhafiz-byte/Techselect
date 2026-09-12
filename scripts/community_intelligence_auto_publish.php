<?php
// Cron-compatible evaluator for already analyzed Community Intelligence records.
// Example: php scripts/community_intelligence_auto_publish.php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/CommunityIntelligenceAutoPublisher.php';

if(PHP_SAPI!=='cli'){http_response_code(404);exit;}
$pdo=Db::pdo();$settings=CommunityIntelligenceAutoPublisher::settings($pdo);
if(!empty($settings['migration_required'])){fwrite(STDERR,"Migration 062 is required.\n");exit(2);}
if(empty($settings['enabled'])){fwrite(STDOUT,"Community Intelligence auto-publication is disabled.\n");exit(0);}
$ids=$pdo->query("SELECT product_id FROM product_public_review_intelligence ORDER BY product_id")->fetchAll(PDO::FETCH_COLUMN);$published=0;$held=0;$failed=0;
foreach($ids as $id){try{$d=CommunityIntelligenceAutoPublisher::evaluateExisting($pdo,(int)$id);if($d['eligible'])$published++;else$held++;fwrite(STDOUT,"product {$id}: {$d['decision']}".($d['failed_gates']?' ['.implode(',',$d['failed_gates']).']':'')."\n");}catch(Throwable $e){$failed++;fwrite(STDERR,"product {$id}: error: ".$e->getMessage()."\n");}}
fwrite(STDOUT,"Done. published={$published} held={$held} failed={$failed}\n");exit($failed?1:0);
