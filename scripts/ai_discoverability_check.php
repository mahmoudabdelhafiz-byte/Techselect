<?php
$root=dirname(__DIR__);
$robots=(string)@file_get_contents($root.'/robots.txt');
$llms=(string)@file_get_contents($root.'/llms.txt');
$sitemap=(string)@file_get_contents($root.'/sitemap.php');
$checks=[
  'robots exists'=>$robots!=='',
  'OAI SearchBot allowed'=>strpos($robots,'User-agent: OAI-SearchBot')!==false && strpos($robots,"User-agent: OAI-SearchBot\nAllow: /")!==false,
  'ChatGPT user agent allowed'=>strpos($robots,'User-agent: ChatGPT-User')!==false,
  'Claude SearchBot allowed'=>strpos($robots,'User-agent: Claude-SearchBot')!==false,
  'Claude user agent allowed'=>strpos($robots,'User-agent: Claude-User')!==false,
  'ClaudeBot allowed'=>strpos($robots,'User-agent: ClaudeBot')!==false,
  'sitemap declared'=>strpos($robots,'Sitemap: https://techselectai.com/sitemap.xml')!==false,
  'llms exists'=>$llms!=='',
  'llms methodology link'=>strpos($llms,'https://techselectai.com/methodology')!==false,
  'llms software path'=>strpos($llms,'https://techselectai.com/software/{product-slug}')!==false,
  'llms category path'=>strpos($llms,'https://techselectai.com/categories/{category-slug}')!==false,
  'llms capability path'=>strpos($llms,'https://techselectai.com/capabilities/{capability-slug}')!==false,
  'llms integration path'=>strpos($llms,'https://techselectai.com/integrations/{integration-slug}')!==false,
  'llms comparison path'=>strpos($llms,'https://techselectai.com/compare/{product-a}-vs-{product-b}')!==false,
  'unknown distinction'=>strpos($llms,'Unknown or not-yet-verified')!==false,
  'score separation'=>strpos($llms,'Verified Review Score')!==false && strpos($llms,'Public Review Intelligence')!==false,
  'sitemap has methodology'=>strpos($sitemap,"'/methodology'")!==false,
];
$failed=[];
foreach($checks as $label=>$ok){echo ($ok?'PASS':'FAIL').' '.$label.PHP_EOL;if(!$ok)$failed[]=$label;}
if($failed){fwrite(STDERR,"AI discoverability checks failed:\n- ".implode("\n- ",$failed)."\n");exit(1);}
echo "AI discoverability checks passed.\n";
