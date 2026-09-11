<?php
$root=dirname(__DIR__);
$checks=[
  'db/mysql/057_public_conversion_events.sql'=>['public_conversion_events','cta_impression','cta_click'],
  'app/lib/PublicConversionAnalytics.php'=>['sourceType','contextKey','public_conversion_events'],
  'api/public_conversion.php'=>['sameOrigin','rateLimit','dashboard'],
  'crawlable_public_page.php'=>['ts-public-conversion-tracking','/api/public-conversion','section.cta'],
  '.htaccess'=>['api/public-conversion'],
  'docs/public_conversion_neutral_monetization.md'=>['must never affect','Fit Score','recommendation order']
];
$errors=[];foreach($checks as $file=>$needles){$p=$root.'/'.$file;if(!is_file($p)){$errors[]="missing {$file}";continue;}$s=file_get_contents($p);foreach($needles as $n)if(strpos($s,$n)===false)$errors[]="{$file} missing {$n}";}
// Guard against accidental monetization hooks in recommendation/decision-pack code from this feature.
foreach(['app/lib/Scoring.php','app/lib/DecisionPack.php'] as $file){$p=$root.'/'.$file;if(is_file($p)){ $s=strtolower(file_get_contents($p)); if(strpos($s,'public_conversion_events')!==false)$errors[]="conversion analytics leaked into {$file}"; }}
if($errors){fwrite(STDERR,implode("\n",$errors)."\n");exit(1);}echo "public conversion neutrality contract OK\n";
