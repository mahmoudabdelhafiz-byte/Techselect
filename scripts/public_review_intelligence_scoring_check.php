<?php
require_once __DIR__.'/../app/lib/PublicReviewIntelligence.php';

$failures=[];
function expect_true($cond,$message){global $failures;if($cond){echo "[OK]   $message\n";}else{$failures[]=$message;echo "[FAIL] $message\n";}}
function rows($n,$types,$sentiments,$confidence=0.9,$date='2026-09-01 00:00:00'){
    $out=[];
    for($i=0;$i<$n;$i++)$out[]=[
        'status'=>'active','access_policy'=>'permitted','duplicate_suspected'=>0,'spam_suspected'=>0,
        'source_type'=>$types[$i%count($types)],'sentiment_score'=>$sentiments[$i%count($sentiments)],
        'source_confidence'=>$confidence,'source_published_at'=>$date
    ];
    return $out;
}
$now=new DateTimeImmutable('2026-09-10 00:00:00',new DateTimeZone('UTC'));

$r=PublicReviewIntelligence::calculate(rows(4,['forum','app_store'],[0.8]),$now);
expect_true($r['insufficient_data']===true,'Fewer than 5 usable signals is insufficient.');

$r=PublicReviewIntelligence::calculate(rows(8,['forum'],[0.8]),$now);
expect_true($r['insufficient_data']===true,'Single source type is insufficient despite volume.');

$r=PublicReviewIntelligence::calculate(rows(8,['forum','app_store'],[0.8,0.6]),$now);
expect_true($r['insufficient_data']===false,'Diversified permitted sources can produce a score.');
expect_true($r['score_5']>4.0,'Strong positive sentiment yields a strong score.');

$mixed=PublicReviewIntelligence::calculate(rows(10,['forum','app_store','community'],[0.9,-0.9]),$now);
$consistent=PublicReviewIntelligence::calculate(rows(10,['forum','app_store','community'],[0.7,0.8]),$now);
expect_true($mixed['confidence_score']<$consistent['confidence_score'],'Strong disagreement lowers confidence.');

$restricted=rows(6,['forum','app_store'],[0.8]);
$restricted[0]['access_policy']='restricted';
$restricted[1]['access_policy']='blocked';
$r=PublicReviewIntelligence::calculate($restricted,$now);
expect_true($r['sources_analyzed']===4,'Restricted and blocked sources are excluded.');
expect_true($r['insufficient_data']===true,'Exclusion can cause insufficient-data state.');

$spam=rows(7,['forum','app_store'],[0.8]);
$spam[0]['spam_suspected']=1;
$spam[1]['duplicate_suspected']=1;
$r=PublicReviewIntelligence::calculate($spam,$now);
expect_true($r['sources_analyzed']===5,'Spam/duplicate-suspected signals are excluded.');

$fresh=PublicReviewIntelligence::calculate(rows(8,['forum','app_store'],[0.9],0.9,'2026-09-01 00:00:00'),$now);
$stale=PublicReviewIntelligence::calculate(array_merge(
    rows(4,['forum'],[0.9],0.9,'2024-01-01 00:00:00'),
    rows(4,['app_store'],[-0.9],0.9,'2026-09-01 00:00:00')
),$now);
expect_true($stale['score_5']<2.5,'Fresh negative signals outweigh stale positive signals under recency weighting.');

expect_true(PublicReviewIntelligence::sourceEligible(['status'=>'active','access_policy'=>'permitted'])===true,'Permitted active source is eligible.');
expect_true(PublicReviewIntelligence::sourceEligible(['status'=>'active','access_policy'=>'pending_review'])===false,'Pending-review source is not eligible.');

if($failures){echo "\n".count($failures)." failure(s).\n";exit(2);}echo "\nAll PRI scoring checks passed.\n";exit(0);
