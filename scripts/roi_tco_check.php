<?php
$root=dirname(__DIR__);$checks=[
 'migration'=>['db/mysql/037_roi_tco_models.sql','CREATE TABLE IF NOT EXISTS roi_tco_models'],
 'calculator'=>['app/lib/RoiTcoModel.php','unknown_inputs'],
 'three_year'=>['app/lib/RoiTcoModel.php','tco_3_year'],
 'five_year'=>['app/lib/RoiTcoModel.php','tco_5_year'],
 'verified_boundary'=>['app/lib/RoiTcoModel.php','Reference evidence only'],
 'preview_tier'=>['api/roi_tco.php',"'selection_projects'"],
 'pro_tier'=>['api/roi_tco.php',"'roi_tco_model'"],
 'business_case_sync'=>['api/roi_tco.php','syncCaseRoi'],
 'matrix_snapshot'=>['api/roi_tco.php','matrixSnapshot'],
 'route'=>['.htaccess','^roi-tco/?$'],
 'api_route'=>['.htaccess','^api/roi-tco'],
];$fail=[];foreach($checks as $name=>[$file,$needle]){$p=$root.'/'.$file;$txt=is_file($p)?file_get_contents($p):'';if(strpos($txt,$needle)===false)$fail[]=$name;}if($fail){fwrite(STDERR,'ROI/TCO checks failed: '.implode(', ',$fail).PHP_EOL);exit(1);}echo "ROI/TCO checks passed\n";
