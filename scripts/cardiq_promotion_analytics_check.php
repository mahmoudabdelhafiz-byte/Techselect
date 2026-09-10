<?php
$root=dirname(__DIR__);
$checks=[
  'app/lib/BuyerIntentAnalytics.php'=>['CardIQ Promotion Performance','contextual_promotions','cardiq-identity-control','by_trigger','by_category','signed_in_impressions','anonymous_impressions'],
  'buyer_analytics.php'=>['CardIQ Promotion Performance','Click-through rate','Performance by buyer context','Performance by software category','This data never affects TechSelectAI ranking or Fit Score']
];
$failed=[];
foreach($checks as $file=>$needles){$text=@file_get_contents($root.'/'.$file);if($text===false){$failed[]=$file.' missing';continue;}foreach($needles as $needle){if(strpos($text,$needle)===false)$failed[]=$file.' missing '.$needle;}}
if($failed){fwrite(STDERR,"FAIL\n - ".implode("\n - ",$failed)."\n");exit(1);}echo "OK: CardIQ promotion analytics is aggregate-only and separate from recommendation scoring.\n";
