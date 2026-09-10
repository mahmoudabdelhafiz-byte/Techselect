<?php
$root=dirname(__DIR__);
$checks=[
  'frontend/src/consultationSave.js'=>['Save this consultation','/api/auth/csrf','/register?next=%2F','/login?next=%2F','Saved to your account','/my-consultations','techselectai.activeConsultation.v1'],
  'frontend/src/main.jsx'=>["import'./consultationSave.js'"],
  'account.php'=>['activeVisitorToken','/api/account/claim-consultation','safeNext']
];
$failed=[];
foreach($checks as $file=>$needles){$path=$root.'/'.$file;$text=is_file($path)?file_get_contents($path):'';foreach($needles as $needle){if(strpos($text,$needle)===false)$failed[]="$file missing $needle";}}
if($failed){fwrite(STDERR,"Consultation save flow check failed:\n- ".implode("\n- ",$failed)."\n");exit(1);}echo "Consultation save flow check passed.\n";
