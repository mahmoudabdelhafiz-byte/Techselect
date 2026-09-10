<?php
$root=dirname(__DIR__);
$checks=[
  'trust.php'=>['Trust & Methodology','Commercial relationships never determine TechSelectAI recommendation scores or rankings.','TechSelectAI is operated by Barmageyat.','Functional Fit','35%','Unknown does not mean unsupported.','Sponsored placements are clearly identified','Verified Reviews','Public Review Intelligence'],
  '.htaccess'=>['RewriteRule ^trust/?$ brand_page.php'],
  'brand_page.php'=>["'/trust','/trust/','/trust.php'","$target='trust.php'"],
  'frontend/src/accountNav.js'=>['/trust','Trust & Methodology']
];
$failed=[];
foreach($checks as $file=>$needles){$path=$root.'/'.$file;$text=is_file($path)?file_get_contents($path):'';foreach($needles as $needle){if(strpos($text,$needle)===false)$failed[]="$file missing $needle";}}
if($failed){fwrite(STDERR,"Trust methodology check failed:\n- ".implode("\n- ",$failed)."\n");exit(1);}echo "Trust methodology check passed.\n";
