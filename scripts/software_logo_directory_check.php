<?php
$root=dirname(__DIR__);
$files=[
    'db/mysql/014_add_product_logo_metadata.sql',
    'software_logo_page.php',
    'frontend/src/softwareLogos.js',
    'frontend/src/main.jsx',
    'scripts/software_logo_backfill.php',
];
$failed=0;
foreach($files as $file){
    if(!is_file($root.'/'.$file)){echo "FAIL missing {$file}\n";$failed++;}
    else echo "PASS {$file}\n";
}
if($failed)exit(2);

$migration=file_get_contents($root.'/db/mysql/014_add_product_logo_metadata.sql');
$surface=file_get_contents($root.'/software_logo_page.php');
$js=file_get_contents($root.'/frontend/src/softwareLogos.js');
$main=file_get_contents($root.'/frontend/src/main.jsx');
$backfill=file_get_contents($root.'/scripts/software_logo_backfill.php');

$checks=[
    'schema stores local logo path'=>str_contains($migration,'logo_path'),
    'schema stores official source'=>str_contains($migration,'logo_source_url'),
    'existing surface exposes active logo map'=>str_contains($surface,"status='active'")&&str_contains($surface,"logo_map"),
    'logo map restricts paths to media/software'=>str_contains($surface,"str_starts_with(\$relative,'media/software/')"),
    'directory uses approved local logo path'=>str_contains($js,'product?.logo_path'),
    'directory has fallback initials'=>str_contains($js,'software-card-logo__fallback'),
    'directory reads existing logo surface'=>str_contains($js,'/software_logo_page.php?logo_map=1'),
    'frontend loads logo enhancer'=>str_contains($main,"import'./softwareLogos.js'"),
    'backfill defaults to dry run'=>str_contains($backfill,"in_array('--apply',\$argv,true)"),
    'backfill requires high-confidence candidate'=>str_contains($backfill,">=100"),
    'backfill uses official-site manager'=>str_contains($backfill,'SoftwareLogoManager::discover'),
];
foreach($checks as $label=>$ok){echo ($ok?'PASS ':'FAIL ').$label."\n";if(!$ok)$failed++;}

if(preg_match('/clearbit|logo\.dev|brandfetch|g2\.com|capterra/i',$surface.$js.$backfill)){
    echo "FAIL third-party logo service/reference detected\n";$failed++;
}else echo "PASS no third-party logo source dependency\n";

exit($failed?2:0);
