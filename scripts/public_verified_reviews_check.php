<?php
$root=dirname(__DIR__);
$page=(string)@file_get_contents($root.'/software_reviews_page.php');
$brand=(string)@file_get_contents($root.'/brand_page.php');
$checks=[
  'wrapper exists'=>$page!=='',
  'software route uses review wrapper'=>strpos($brand,"\$target='software_reviews_page.php'")!==false,
  'approved-only query'=>strpos($page,"r.moderation_status='approved'")!==false,
  'published-only query'=>strpos($page,'r.published_at IS NOT NULL')!==false,
  'aggregate score source'=>strpos($page,'product_verified_review_ratings')!==false,
  'private users not joined'=>strpos($page,'JOIN users')===false,
  'verified status required'=>strpos($page,"v.verification_status='verified'")!==false,
  'write review CTA'=>strpos($page,'Write a verified review')!==false,
  'separation disclosure'=>strpos($page,'separate from buyer-specific Fit Score, Evidence Confidence, and Public Review Intelligence')!==false,
  'migration-safe fallback'=>strpos($page,'catch(Throwable $e)')!==false,
  'no ranking mutation'=>strpos($page,'consultation_product_scores')===false && strpos($page,'UPDATE recommendation')===false,
];
$failed=[];foreach($checks as $label=>$ok){echo ($ok?'PASS':'FAIL').' '.$label.PHP_EOL;if(!$ok)$failed[]=$label;}
if($failed){fwrite(STDERR,"Public verified reviews check failed:\n- ".implode("\n- ",$failed)."\n");exit(1);}echo "Public verified reviews checks passed.\n";
