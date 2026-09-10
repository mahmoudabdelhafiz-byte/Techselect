<?php
$root=dirname(__DIR__);
$checks=[
 'trust.php'=>['Commercial relationships never determine TechSelectAI recommendation scores or rankings','TechSelectAI is operated by','Barmageyat','Unknown ≠ Not Supported','Fit Score','Evidence Confidence','Verified Review Score','Public Review Intelligence','application/ld+json'],
 '.htaccess'=>['RewriteRule ^trust/?$ trust.php'],
 'sitemap.php'=>["add_url($urls,'/trust'"],
 'frontend/src/trustLink.js'=>['Trust & methodology','/trust'],
 'frontend/src/main.jsx'=>["import'./trustLink.js'"]
];
$failed=[];
foreach($checks as $file=>$needles){$path=$root.'/'.$file;$text=is_file($path)?file_get_contents($path):'';foreach($needles as $needle){if(strpos($text,$needle)===false)$failed[]="$file missing $needle";}}
if($failed){fwrite(STDERR,"Trust authority check failed:\n- ".implode("\n- ",$failed)."\n");exit(1);}echo "Trust authority check passed.\n";
