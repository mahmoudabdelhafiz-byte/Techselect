<?php
$root=dirname(__DIR__);
$checks=[
  'frontend/src/homepageValue.js'=>['AI-powered software & technology advisory','Decide what technology to buy — and why.','Get My Recommendations','Commercial relationships never determine TechSelectAI recommendation scores or rankings.','/methodology','/trust','/software','No signup required to get recommendations.'],
  'frontend/src/main.jsx'=>["import'./homepageValue.js'"]
];
$failed=[];
foreach($checks as $file=>$needles){$text=@file_get_contents($root.'/'.$file)?:'';foreach($needles as $needle){if(strpos($text,$needle)===false)$failed[]="$file missing $needle";}}
if($failed){fwrite(STDERR,"Homepage value proposition check failed:\n- ".implode("\n- ",$failed)."\n");exit(1);}echo "Homepage value proposition check passed.\n";
