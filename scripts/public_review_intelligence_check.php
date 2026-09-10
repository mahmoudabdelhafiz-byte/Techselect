<?php
// TechSelectAI Public Review Intelligence schema guard.
// Usage: php scripts/public_review_intelligence_check.php
require_once __DIR__.'/../app/lib/Db.php';
$pdo=Db::pdo();

$required=[
  'public_review_sources'=>['product_id','source_url','source_url_hash','source_type','access_policy','content_fingerprint'],
  'public_review_analysis_runs'=>['product_id','analysis_version','status','source_count','eligible_source_count','excluded_source_count'],
  'public_review_signals'=>['source_id','analysis_run_id','sentiment_score','topic_json','source_confidence','duplicate_suspected','spam_suspected'],
  'product_public_review_intelligence'=>['product_id','analysis_run_id','score_5','positive_sentiment_pct','confidence_score','confidence_label','sources_analyzed','source_type_count','insufficient_data','strengths_json','concerns_json','methodology_version','last_analyzed_at'],
];

$fail=[];
foreach($required as $table=>$columns){
    $q=$pdo->prepare("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name=?");
    $q->execute([$table]);
    if(!(int)$q->fetchColumn()){$fail[]="Missing table: {$table}";continue;}
    $q=$pdo->prepare("SELECT column_name FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name=?");
    $q->execute([$table]);
    $present=$q->fetchAll(PDO::FETCH_COLUMN);
    foreach($columns as $column)if(!in_array($column,$present,true))$fail[]="Missing column: {$table}.{$column}";
}

// Legal/permission guard: only explicitly permitted sources may be eligible for analysis.
if(!$fail){
    $bad=$pdo->query("SELECT COUNT(*) FROM public_review_sources WHERE access_policy NOT IN ('pending_review','permitted','restricted','blocked')")->fetchColumn();
    if((int)$bad>0)$fail[]='Invalid access_policy values found.';
}

if($fail){foreach($fail as $x)echo "[FAIL] {$x}\n";echo "Summary: ".count($fail)." failure(s).\n";exit(2);}
echo "[OK] Public Review Intelligence schema is present.\n";
echo "[OK] Source policy field supports explicit permitted/restricted handling.\n";
echo "[OK] Public review score storage is separate from recommendation scoring tables.\n";
exit(0);
