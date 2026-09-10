<?php
$root=dirname(__DIR__);
$checks=[
 'business_case_start.php'=>['Build a Business Case','/api/business-cases','/api/auth/csrf','verified product facts','management-ready justification'],
 'frontend/src/businessCaseCta.js'=>['Build a Business Case','techselectai.activeConsultation.v1','/build-business-case?'],
 'frontend/src/main.jsx'=>["import'./businessCaseCta.js'"],
 'my_consultations.php'=>['Build a Business Case','/build-business-case?product='],
 'brand_page.php'=>['ts-bc-public','Build a Business Case','/build-business-case?product='],
 '.htaccess'=>['^build-business-case/?$ business_case_start.php']
];
$failed=[];
foreach($checks as $file=>$needles){$text=is_file($root.'/'.$file)?file_get_contents($root.'/'.$file):'';foreach($needles as $needle){if(strpos($text,$needle)===false)$failed[]="$file missing $needle";}}
if($failed){fwrite(STDERR,"Business Case entry-point check failed:\n- ".implode("\n- ",$failed)."\n");exit(1);}echo "Business Case entry-point check passed.\n";
