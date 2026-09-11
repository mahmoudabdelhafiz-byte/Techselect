<?php
$root=dirname(__DIR__);
$checks=[
 'scenario_decision_guide.php'=>[
  "'hrms-arabic-mena'",
  "'itsm-multi-site-enterprise'",
  "ORDER BY p.name",
  'Evidence coverage is a data-quality indicator, not a product rank or recommendation.',
  'not yet verified, not unsupported',
  'data-citation-section',
  'application/ld+json',
  'Get My Recommendations'
 ],
 '.htaccess'=>['hrms-arabic-mena','itsm-multi-site-enterprise','scenario_decision_guide.php'],
 'sitemap.php'=>['/guides/hrms-arabic-mena','/guides/itsm-multi-site-enterprise'],
 'llms.txt'=>['HRMS & HCM for Arabic-Speaking and MENA Organizations','ITSM Software for Multi-Site Enterprise Operations','Product ordering on category decision guides is alphabetical']
];
$failed=[];
foreach($checks as $file=>$needles){
 $text=@file_get_contents($root.'/'.$file);
 if($text===false){$failed[]="$file missing";continue;}
 foreach($needles as $needle)if(strpos($text,$needle)===false)$failed[]="$file missing: $needle";
}
$renderer=@file_get_contents($root.'/scenario_decision_guide.php')?:'';
foreach(['ORDER BY known_facts','ORDER BY known_confidence','ORDER BY supported_facts','best product','best HRMS','best ITSM'] as $forbidden){
 if(stripos($renderer,$forbidden)!==false)$failed[]="scenario_decision_guide.php contains forbidden pseudo-ranking pattern: $forbidden";
}
if($failed){fwrite(STDERR,"SEO decision content Phase 2 check failed:\n- ".implode("\n- ",$failed)."\n");exit(1);}
echo "SEO decision content Phase 2 check passed.\n";
