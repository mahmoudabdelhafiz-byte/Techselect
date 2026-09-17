<?php

declare(strict_types=1);

$root=dirname(__DIR__);
$files=glob($root.'/db/mysql/{105,106,107,108,109,110,111}_*.sql', GLOB_BRACE) ?: [];
$errors=[];

if(count($files)!==7){
    $errors[]='Expected catalog migrations 105 through 111 to be present.';
}

foreach($files as $file){
    $sql=(string)file_get_contents($file);
    if(strpos($sql,'x.description')===false){
        continue;
    }

    if(!preg_match('/FROM\s+modules\s+m\s+JOIN\s*\(\s*SELECT\s+.+?\s+module_slug\s*,.+?\s+name\s*,.+?\s+slug\s*,.+?\s+description(?:\s*,|\s+UNION\s+ALL)/is',$sql)){
        $errors[]=basename($file).': derived capability table uses x.description without an explicit description alias.';
    }
}

if($errors){
    fwrite(STDERR,"Catalog derived-column alias check failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}

echo "Catalog derived-column alias check passed for migrations 105-111.\n";
