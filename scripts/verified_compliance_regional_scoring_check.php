<?php
$root=dirname(__DIR__);
$checks=[
 'app/lib/Scoring.php'=>["'not_yet_verified'=>0.40","'not_supported'=>0.00","'limited_availability'=>0.65","'not_available'=>0.00",'public static function regional'],
 'api/recommend.php'=>['product_regional_availability','product_compliance','compliance_standards','session_country_code','requestedStandards','regional_country_code','requested_compliance','php-v1.3-verified-compliance-regional','Scoring::regional','Scoring::support']
];
$failed=[];
foreach($checks as $file=>$needles){$text=@file_get_contents($root.'/'.$file)?:'';foreach($needles as $needle)if(strpos($text,$needle)===false)$failed[]="$file missing $needle";}
$api=@file_get_contents($root.'/api/recommend.php')?:'';
if(strpos($api,"$dims['regional']=")===false)$failed[]='Regional dimension is not conditionally evaluated';
if(strpos($api,"$dims['security']=")===false)$failed[]='Security/compliance dimension is not conditionally evaluated';
if(strpos($api,"$storedRegional=$r['regional']??40")===false)$failed[]='Unevaluated regional storage fallback missing';
if(strpos($api,"$storedSecurity=$r['security']??40")===false)$failed[]='Unevaluated security storage fallback missing';
if(strpos($api,"'regional'=>$dims['regional']??null")===false)$failed[]='Regional output must preserve unevaluated null state';
if(strpos($api,"'security'=>$dims['security']??null")===false)$failed[]='Security output must preserve unevaluated null state';
if(strpos($api,"if($requestedStandards)")===false)$failed[]='Compliance scoring must require buyer-requested standards';
if(strpos($api,"if($countryCode!=='')")===false)$failed[]='Regional scoring must require country context';
if($failed){fwrite(STDERR,"Verified compliance/regional scoring checks failed:\n- ".implode("\n- ",$failed)."\n");exit(1);}echo "Verified compliance/regional scoring checks passed.\n";
