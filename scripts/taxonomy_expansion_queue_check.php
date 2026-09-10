<?php
$files=[
  __DIR__.'/../db/mysql/018_taxonomy_expansion_queue.sql',
  __DIR__.'/../app/lib/TaxonomyExpansionQueue.php',
  __DIR__.'/../app/lib/AiExtraction.php',
  __DIR__.'/../api/taxonomy.php',
  __DIR__.'/../taxonomy_queue.php',
  __DIR__.'/../.htaccess'
];
foreach($files as $f){if(!is_file($f)){fwrite(STDERR,"Missing: $f\n");exit(1);}}
$checks=[
  [file_get_contents($files[0]),'CREATE TABLE IF NOT EXISTS taxonomy_expansion_queue','queue table'],
  [file_get_contents($files[0]),'occurrence_count','occurrence counter'],
  [file_get_contents($files[1]),'ON DUPLICATE KEY UPDATE','topic upsert'],
  [file_get_contents($files[1]),"['new','researching','planned','added_to_catalog','ignored']",'admin statuses'],
  [file_get_contents($files[2]),'TaxonomyExpansionQueue::capture','general-mode capture'],
  [file_get_contents($files[2]),'catch(Throwable $e){}','non-blocking capture'],
  [file_get_contents($files[3]),'/api/taxonomy/queue','admin API'],
  [file_get_contents($files[4]),'Taxonomy Expansion Queue','admin UI'],
  [file_get_contents($files[5]),'api/taxonomy/.*$ api/taxonomy.php','route wiring']
];
$failed=[];foreach($checks as [$src,$needle,$label])if(strpos($src,$needle)===false)$failed[]=$label;
if($failed){fwrite(STDERR,"Taxonomy expansion queue check failed:\n- ".implode("\n- ",$failed)."\n");exit(1);}echo "Taxonomy expansion queue check passed.\n";
