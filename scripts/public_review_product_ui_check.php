<?php
$root=dirname(__DIR__);
$file=$root.'/software_logo_page.php';
if(!is_file($file)){fwrite(STDERR,"Missing software_logo_page.php\n");exit(2);} $s=file_get_contents($file);
$checks=[
  'PRI table lookup'=>'product_public_review_intelligence',
  'insufficient-data behavior'=>'insufficient_data',
  'score display'=>'score_5',
  'positive sentiment'=>'positive_sentiment_pct',
  'source diversity'=>'source_type_count',
  'ranking separation disclosure'=>'does not affect TechSelectAI recommendation ranking',
  'migration-safe fallback'=>'catch(Throwable $e)',
];
$failed=0;foreach($checks as $name=>$needle){if(str_contains($s,$needle)){echo "[OK] {$name}\n";}else{echo "[FAIL] {$name}\n";$failed++;}}
if(str_contains($s,'public review body')||str_contains($s,'review_text')){echo "[WARN] Review-body field reference found; inspect manually.\n";}
echo "Summary: {$failed} failure(s).\n";exit($failed?2:0);
