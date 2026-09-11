<?php
$root=dirname(__DIR__);
$checks=[
 ['db/mysql/058_indexation_health_alerts.sql','indexation_daily_snapshots'],
 ['db/mysql/058_indexation_health_alerts.sql','indexation_health_alerts'],
 ['app/lib/IndexationHealth.php','probeStrategic'],
 ['app/lib/IndexationHealth.php',"follow_location'=>0"],
 ['app/lib/IndexationHealth.php','stale_sitemap_lastmod'],
 ['app/lib/IndexationHealth.php','strategic_index_drop'],
 ['app/lib/IndexationHealth.php','technical_exclusion_spike'],
 ['app/lib/IndexationHealth.php','indexation_daily_snapshots'],
 ['api/indexation_health.php','/api/indexation-health/probe'],
 ['api/indexation_health.php','/api/indexation-health/snapshot'],
 ['api/indexation_health.php','ih_sitemap_entries'],
 ['indexation_health.php','Run live technical probes'],
 ['indexation_health.php','30-day strategic trend'],
 ['scripts/indexation_health_daily.php','recordDailySnapshot'],
];
$failed=[];
foreach($checks as [$file,$needle]){$path=$root.'/'.$file;$text=is_file($path)?file_get_contents($path):false;if($text===false||strpos($text,$needle)===false)$failed[]=$file.' :: '.$needle;}
// Safety boundary: the public/admin API accepts no caller-provided URL for probing.
$api=@file_get_contents($root.'/api/indexation_health.php')?:'';
if(strpos($api,"$b['url']")!==false||strpos($api,'url_required')!==false)$failed[]='api accepts arbitrary probe URL';
if($failed){fwrite(STDERR,"Indexation health completion contract FAILED\n - ".implode("\n - ",$failed)."\n");exit(1);}echo "Indexation health completion contract OK\n";
