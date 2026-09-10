<?php
$root=dirname(__DIR__);
$checks=[
  'methodology.php'=>['Fit Score weights','Functional Fit','35%','Must-Have Compliance','20%','Unknown ≠ Not Supported','Evidence Confidence','Barmageyat','CardIQ','/trust'],
  '.htaccess'=>['RewriteRule ^methodology/?$ methodology.php [QSA,L]'],
  'sitemap.php'=>["add_url($urls,'/methodology'"],
  'llms.txt'=>['https://techselectai.com/methodology'],
  'frontend/src/trustLink.js'=>["['Trust','/trust']","['Methodology','/methodology']"]
];
$failed=[];
foreach($checks as $file=>$needles){$path=$root.'/'.$file;$text=is_file($path)?file_get_contents($path):'';foreach($needles as $needle){if(strpos($text,$needle)===false)$failed[]="$file missing $needle";}}
if($failed){fwrite(STDERR,"Methodology visibility check failed:\n- ".implode("\n- ",$failed)."\n");exit(1);}echo "Methodology visibility check passed.\n";
