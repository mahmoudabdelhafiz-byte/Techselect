<?php
$root=dirname(__DIR__);
$required=[
    'app/lib/PublicReviewAiAnalyzer.php',
    'app/lib/PublicReviewIngestion.php',
    'app/lib/PublicReviewIntelligence.php',
    'api/admin.php',
    'admin.php',
];
foreach($required as $file){
    if(!is_file($root.'/'.$file)){fwrite(STDERR,"Missing {$file}\n");exit(1);}
}
$analyzer=file_get_contents($root.'/app/lib/PublicReviewAiAnalyzer.php');
foreach(['OPENAI_API_KEY','TECHSELECT_PRI_MODEL','json_schema','/v1/responses'] as $needle){
    if(strpos($analyzer,$needle)===false){fwrite(STDERR,"Analyzer check failed: {$needle}\n");exit(1);}
}
echo "PRI admin/analyzer foundation checks passed.\n";
