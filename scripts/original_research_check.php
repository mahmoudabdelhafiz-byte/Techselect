<?php
$root=dirname(__DIR__);
$must=[
 'db/mysql/055_original_research.sql'=>['research_report_snapshots','research_report_rows'],
 'app/lib/OriginalResearch.php'=>['research-v1.0','not_yet_verified','verified_source_share_pct'],
 'research_report.php'=>['Dataset','Suggested citation','Download CSV','Embeddable chart'],
 'research_export.php'=>['text/csv','image/svg+xml','techselectai.com/research/software-evidence-benchmark'],
 '.htaccess'=>['research/software-evidence-benchmark','research_export.php'],
 'sitemap.php'=>['/research/software-evidence-benchmark'],
 'llms.txt'=>['Original research','software-evidence-benchmark']
];
$errors=[];foreach($must as $file=>$needles){$p=$root.'/'.$file;if(!is_file($p)){$errors[]="$file missing";continue;}$c=file_get_contents($p);foreach($needles as $n)if(strpos($c,$n)===false)$errors[]="$file missing $n";}
if($errors){fwrite(STDERR,"Original research contract FAILED\n- ".implode("\n- ",$errors)."\n");exit(1);}echo "Original research contract OK\n";
