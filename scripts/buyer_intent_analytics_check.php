<?php
$root=dirname(__DIR__);
$checks=[
  'migration'=>['db/mysql/019_buyer_intent_analytics.sql',['buyer_intent_events','company_size_band','expected_users']],
  'service'=>['app/lib/BuyerIntentAnalytics.php',['recordPublicEvent','dashboard','repeat_buyers','taxonomy_expansion_queue']],
  'api'=>['api/buyer_analytics.php',["requireRole(['admin','super_admin','data_editor'])",'BuyerIntentAnalytics::dashboard']],
  'page'=>['buyer_analytics.php',['Buyer Intent Analytics','Most requested capabilities','Most viewed comparisons']],
  'routing'=>['.htaccess',['buyer-analytics','api/buyer-analytics']],
  'privacy'=>['robots.txt',['Disallow: /buyer-analytics']]
];
$failed=[];
foreach($checks as $name=>[$file,$needles]){
  $path=$root.'/'.$file;
  if(!is_file($path)){$failed[]="$name: missing $file";continue;}
  $text=file_get_contents($path);
  foreach($needles as $needle)if(strpos($text,$needle)===false)$failed[]="$name: missing '$needle'";
}
if($failed){fwrite(STDERR,"Buyer intent analytics check FAILED\n- ".implode("\n- ",$failed)."\n");exit(1);}echo "Buyer intent analytics check passed\n";
