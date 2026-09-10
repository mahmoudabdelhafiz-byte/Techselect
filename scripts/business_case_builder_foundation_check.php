<?php
$root=dirname(__DIR__);
$checks=[
 'db/mysql/021_business_case_builder.sql'=>['CREATE TABLE IF NOT EXISTS business_cases','assumptions_json','verified_facts_json','generated_output_json','business_case_events','started','generated','saved','exported'],
 'api/business_cases.php'=>['/api/business-cases','authentication_required','requireCsrf','sameOrigin','business_case_events','verified_facts','invalid_consultation'],
 '.htaccess'=>['api/business-cases(?:/.*)?$ api/business_cases.php']
];
$failed=[];
foreach($checks as $file=>$needles){$text=is_file($root.'/'.$file)?file_get_contents($root.'/'.$file):'';foreach($needles as $needle){if(strpos($text,$needle)===false)$failed[]="$file missing $needle";}}
if($failed){fwrite(STDERR,"Business Case Builder foundation check failed:\n- ".implode("\n- ",$failed)."\n");exit(1);}echo "Business Case Builder foundation check passed.\n";
