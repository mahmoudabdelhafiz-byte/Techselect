<?php
require_once __DIR__.'/../app/lib/PublicReviewIngestion.php';

$fail=[];
try{PublicReviewIngestion::validateSource(['status'=>'active','access_policy'=>'permitted','source_url'=>'https://www.g2.com/products/example/reviews']);$fail[]='G2 must be blocked by default.';}catch(Throwable $e){}
try{PublicReviewIngestion::validateSource(['status'=>'active','access_policy'=>'permitted','source_url'=>'https://www.capterra.com/p/example/reviews']);$fail[]='Capterra must be blocked by default.';}catch(Throwable $e){}
try{PublicReviewIngestion::validateSource(['status'=>'active','access_policy'=>'permitted','source_url'=>'https://www.reddit.com/r/software/comments/example']);}catch(Throwable $e){$fail[]='Permitted public source unexpectedly blocked.';}
$signal=PublicReviewIngestion::normalizeDerivedSignal(['sentiment_score'=>0.5,'sentiment_label'=>'positive','public_rating'=>null,'public_rating_scale'=>null,'topics'=>['usability'],'themes'=>['strengths'=>['easy setup'],'weaknesses'=>[],'implementation'=>[],'support'=>[],'pricing_value'=>[],'integrations'=>[],'reliability'=>[],'usability'=>['easy setup'],'best_fit'=>['SMB'],'poor_fit'=>[]],'reviewer_context'=>[],'source_confidence'=>0.8,'source_quality'=>0.8,'independence_score'=>0.9,'specificity_score'=>0.7,'duplicate_suspected'=>false,'spam_suspected'=>false,'affiliate_suspected'=>false,'vendor_promotion_suspected'=>false,'bot_suspected'=>false,'low_signal_suspected'=>false]);
if(!PublicReviewIngestion::isEligibleSignal($signal))$fail[]='Valid community signal should be eligible.';
$signal['vendor_promotion_suspected']=true;if(PublicReviewIngestion::isEligibleSignal($signal))$fail[]='Vendor-promotional signal must be excluded.';
$migration=file_get_contents(__DIR__.'/../db/mysql/039_community_intelligence_pipeline.sql');foreach(['themes_json','source_quality','independence_score','affiliate_suspected','source_mix_json','date_range_start'] as $needle)if(strpos($migration,$needle)===false)$fail[]='Migration missing '.$needle;
$doc=file_get_contents(__DIR__.'/../docs/community_intelligence_source_policy.md');foreach(['G2','Capterra','explicitly reviewed','does not republish'] as $needle)if(stripos($doc,$needle)===false)$fail[]='Policy documentation missing '.$needle;
if($fail){fwrite(STDERR,implode("\n",$fail)."\n");exit(1);}echo "community_intelligence_pipeline_check: OK\n";
