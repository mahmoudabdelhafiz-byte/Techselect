<?php
$root=dirname(__DIR__);$checks=[
 'migration'=>['db/mysql/053_ai_visibility_benchmark.sql','ai_visibility_prompts'],
 'service'=>['app/lib/AiVisibilityBenchmark.php','month_over_month_citation_change'],
 'api'=>['api/ai_visibility.php','/api/ai-visibility/import'],
 'dashboard'=>['ai_visibility_dashboard.php','AI Visibility Benchmark'],
 'routes'=>['.htaccess','api/ai-visibility'],
 'docs'=>['docs/ai_visibility_benchmark.md','50 prompts'],
];$bad=[];foreach($checks as $name=>[$file,$needle]){$p=$root.'/'.$file;if(!is_file($p)||strpos((string)file_get_contents($p),$needle)===false)$bad[]=$name;}if($bad){fwrite(STDERR,'AI visibility contract failed: '.implode(',',$bad).PHP_EOL);exit(1);}echo "AI visibility contract OK\n";
