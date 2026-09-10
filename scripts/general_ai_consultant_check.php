<?php
$path=__DIR__.'/../app/lib/AiExtraction.php';
$src=file_get_contents($path);
$checks=[
  'general advisory mode schema'=>"'advisory_mode'=>['type'=>'string','enum'=>['curated','general']]",
  'unmapped topic schema'=>"'unmapped_topic'=>['type'=>['string','null']]",
  'catalog notice schema'=>"'catalog_notice'=>['type'=>['string','null']]",
  'general consultant instruction'=>'Your ability to advise is NOT limited to the supplied TechSelectAI categories.',
  'Norton regression example'=>'Norton should be recognized as cybersecurity / endpoint protection / antivirus',
  'do not force supported categories'=>'rather than asking the user to choose one of the supported categories',
  'general mode null category'=>'if(!$resolvedCategory)',
  'general mode assignment'=>"\$result['advisory_mode']='general'",
  'curated mode assignment'=>"\$result['advisory_mode']='curated'",
  'no fabricated fit score'=>'Never fabricate a deterministic TechSelectAI Fit Score'
];
$failed=[];
foreach($checks as $label=>$needle){if(strpos($src,$needle)===false)$failed[]=$label;}
if($failed){fwrite(STDERR,"General AI consultant fallback check failed:\n- ".implode("\n- ",$failed)."\n");exit(1);}
echo "General AI consultant fallback check passed.\n";
