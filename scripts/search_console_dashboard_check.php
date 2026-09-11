<?php
$root=dirname(__DIR__);$checks=[
 'db/mysql/049_search_console_performance.sql'=>['search_console_imports','search_console_performance'],
 'app/lib/SearchConsoleAnalytics.php'=>['quick_wins','low_ctr_pages','gaining_pages','declining_pages','new_queries','position_buckets'],
 'api/search_console.php'=>['/api/search-console/import','IndexationHealth::importIndexStates','SEARCH_CONSOLE_IMPORT'],
 'search_console_dashboard.php'=>['Quick wins: positions 11–30','High impressions, low CTR','Pages gaining visibility','Declining pages','Top queries','Top pages','Countries','Devices','Search appearance','Export CSV'],
 '.htaccess'=>['RewriteRule ^search-console/?$ search_console_dashboard.php','RewriteRule ^api/search-console(?:/.*)?$ api/search_console.php']
];$bad=[];foreach($checks as $file=>$needles){$s=@file_get_contents($root.'/'.$file);if($s===false){$bad[]='missing '.$file;continue;}foreach($needles as $n)if(strpos($s,$n)===false)$bad[]=$file.' missing '.$n;}if($bad){fwrite(STDERR,implode("\n",$bad)."\n");exit(1);}echo "Search Console dashboard contract OK\n";