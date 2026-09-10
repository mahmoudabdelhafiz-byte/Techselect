<?php
$root=dirname(__DIR__);
$checks=[
 'app/lib/AiBusinessCase.php'=>['TechSelectAI Business Case Builder','VERIFIED_FACTS','USER_ASSUMPTIONS','financial_roi_assumptions','https://api.openai.com/v1/responses'],
 'api/business_cases.php'=>['/generate','AiBusinessCase::generate','business-case-generate','generated_output_json','generated_at'],
 'business_case_builder.php'=>['Business Case Builder','Verified context','Your assumptions','Generate business case','/api/business-cases/'],
 'my_business_cases.php'=>['My Business Cases','/business-case?id='],
 '.htaccess'=>['^my-business-cases/?$ my_business_cases.php','^business-case/?$ business_case_builder.php'],
 'frontend/src/accountNav.js'=>['/my-business-cases','My Business Cases']
];
$failed=[];foreach($checks as $file=>$needles){$p=$root.'/'.$file;$t=is_file($p)?file_get_contents($p):'';foreach($needles as $n)if(strpos($t,$n)===false)$failed[]="$file missing $n";}
if($failed){fwrite(STDERR,"Business case generation check failed:\n- ".implode("\n- ",$failed)."\n");exit(1);}echo "Business case generation check passed.\n";
