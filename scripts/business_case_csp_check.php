<?php
$files=['business_case_builder.php','my_business_cases.php'];
$failed=false;
foreach($files as $file){
    $src=file_get_contents(__DIR__.'/../'.$file);
    foreach(['Content-Security-Policy','nonce-','<script nonce='] as $needle){
        if(strpos($src,$needle)===false){fwrite(STDERR,"{$file}: missing {$needle}\n");$failed=true;}
    }
}
if($failed)exit(1);
echo "Business case CSP contract OK\n";
