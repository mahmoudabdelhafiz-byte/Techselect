<?php
require_once __DIR__.'/../app/lib/PublicReviewIngestion.php';

$failures=[];
function assert_true($cond,$msg){global $failures;if($cond){echo "[OK]   {$msg}\n";}else{$failures[]=$msg;echo "[FAIL] {$msg}\n";}}

$now=new DateTimeImmutable('2026-09-10T00:00:00Z');
$base=[
 ['source_type'=>'forum','source_published_at'=>'2026-09-01','status'=>'active','access_policy'=>'permitted','source_confidence'=>0.9,'sentiment_score'=>0.8],
 ['source_type'=>'forum','source_published_at'=>'2026-08-01','status'=>'active','access_policy'=>'permitted','source_confidence'=>0.8,'sentiment_score'=>0.7],
 ['source_type'=>'app_store','source_published_at'=>'2026-07-01','status'=>'active','access_policy'=>'permitted','source_confidence'=>0.85,'sentiment_score'=>0.6],
 ['source_type'=>'app_store','source_published_at'=>'2026-06-01','status'=>'active','access_policy'=>'permitted','source_confidence'=>0.8,'sentiment_score'=>0.5],
 ['source_type'=>'blog','source_published_at'=>'2026-05-01','status'=>'active','access_policy'=>'permitted','source_confidence'=>0.75,'sentiment_score'=>0.4],
];
$analyzer=fn($s)=>[
 'sentiment_score'=>$s['sentiment_score'],
 'sentiment_label'=>'positive',
 'topics'=>['usability','support'],
 'source_confidence'=>$s['source_confidence'],
];
$r=PublicReviewIngestion::analyzePermittedSources($base,$analyzer,$now);
assert_true($r['eligible_source_count']===5,'Permitted sources are analyzed.');
assert_true($r['excluded_source_count']===0,'No permitted source is excluded.');
assert_true($r['intelligence']['insufficient_data']===false,'Diversified sufficient data produces PRI output.');

$restricted=$base;
$restricted[0]['access_policy']='restricted';
$r=PublicReviewIngestion::analyzePermittedSources($restricted,$analyzer,$now);
assert_true($r['eligible_source_count']===4,'Restricted source is rejected before analysis.');
assert_true($r['intelligence']['insufficient_data']===true,'Dropping below threshold yields insufficient data.');

$pending=$base;$pending[0]['access_policy']='pending_review';
$r=PublicReviewIngestion::analyzePermittedSources($pending,$analyzer,$now);
assert_true($r['excluded_source_count']===1,'Pending-review source is not processed.');

$threw=false;try{PublicReviewIngestion::normalizeDerivedSignal(['sentiment_label'=>'positive']);}catch(Throwable $e){$threw=true;}
assert_true($threw,'Malformed analyzer output is rejected.');

$f1=PublicReviewIngestion::contentFingerprint("Great   product\nEasy to use");
$f2=PublicReviewIngestion::contentFingerprint(" great product easy to use ");
assert_true(hash_equals($f1,$f2),'Normalized content fingerprint catches whitespace/case duplicates.');

$dupes=$base;
$dupes[0]['duplicate_suspected']=1;
$analyzerDup=fn($s)=>[
 'sentiment_score'=>$s['sentiment_score'],
 'sentiment_label'=>'positive',
 'topics'=>['usability'],
 'source_confidence'=>$s['source_confidence'],
 'duplicate_suspected'=>!empty($s['duplicate_suspected']),
];
$r=PublicReviewIngestion::analyzePermittedSources($dupes,$analyzerDup,$now);
assert_true($r['intelligence']['sources_analyzed']===4,'Duplicate-suspected signal is excluded by deterministic scorer.');

$spam=$base;$spam[0]['spam_suspected']=1;
$analyzerSpam=fn($s)=>[
 'sentiment_score'=>$s['sentiment_score'],
 'sentiment_label'=>'positive',
 'source_confidence'=>$s['source_confidence'],
 'spam_suspected'=>!empty($s['spam_suspected']),
];
$r=PublicReviewIngestion::analyzePermittedSources($spam,$analyzerSpam,$now);
assert_true($r['intelligence']['sources_analyzed']===4,'Spam-suspected signal is excluded by deterministic scorer.');

echo "\nSummary: ".count($failures)." failure(s).\n";
exit($failures?2:0);
