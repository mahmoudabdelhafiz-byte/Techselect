<?php
$root=dirname(__DIR__);
$checks=[
 'decision_guide.php'=>[
  'crm-saudi-arabia',
  'salesforce-vs-dynamics-enterprise',
  'cloud-vs-self-hosted-crm',
  'Evidence boundary:',
  'not_yet_verified',
  'does not currently model a complete Saudi-specific score',
  'Products are shown alphabetically',
  'Commercial relationships do not determine recommendation scores or rankings',
  'application/ld+json',
  'data-citation-section'
 ],
 '.htaccess'=>['^guides/[a-z0-9-]+/?$ decision_guide.php'],
 'sitemap.php'=>[
  '/guides/crm-saudi-arabia',
  '/guides/salesforce-vs-dynamics-enterprise',
  '/guides/cloud-vs-self-hosted-crm'
 ],
 'llms.txt'=>[
  'Evidence-backed decision guides',
  'Decision guides are not generic winner lists',
  'https://techselectai.com/guides/crm-saudi-arabia'
 ]
];
$failed=[];
foreach($checks as $file=>$needles){
 $text=@file_get_contents($root.'/'.$file)?:'';
 foreach($needles as $needle)if(strpos($text,$needle)===false)$failed[]="$file missing $needle";
}
$guide=@file_get_contents($root.'/decision_guide.php')?:'';
foreach(['ORDER BY p.name','support_status<>' . "'not_yet_verified'",'Start a personalized consultation','/methodology','/trust'] as $needle){
 if(strpos($guide,$needle)===false)$failed[]="decision_guide.php missing guardrail $needle";
}
if(strpos($guide,'ORDER BY known_confidence DESC')!==false||strpos($guide,'ORDER BY supported_facts DESC')!==false)$failed[]='decision guide must not sort category products into a pseudo-ranking';
if($failed){fwrite(STDERR,"SEO decision content checks failed:\n- ".implode("\n- ",$failed)."\n");exit(1);}echo "SEO decision content checks passed.\n";
