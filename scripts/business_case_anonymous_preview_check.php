<?php
$root=dirname(__DIR__);
$checks=[
  'api/business_cases.php'=>['/api/business-cases/preview','business-case-preview','temporary'=>true,'consultation_token','public_token','bc_assumptions'],
  'business_case_start.php'=>['Generate free preview','Temporary preview · not yet saved','/api/business-cases/preview','Save & continue','techselectai.businessCaseDraft.v1','public_token']
];
$failed=[];
foreach($checks as $file=>$needles){$text=@file_get_contents($root.'/'.$file)?:'';foreach($needles as $needle){$needle=is_int($needle)?(string)$needle:$needle;if(strpos($text,$needle)===false)$failed[]="$file missing $needle";}}
if(strpos(@file_get_contents($root.'/api/business_cases.php')?:'',"INSERT INTO business_cases")===false)$failed[]='saved business-case persistence unexpectedly missing';
if($failed){fwrite(STDERR,"Business Case anonymous preview check failed:\n- ".implode("\n- ",$failed)."\n");exit(1);}echo "Business Case anonymous preview check passed.\n";
