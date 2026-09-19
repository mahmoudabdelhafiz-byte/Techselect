<?php

declare(strict_types=1);

$root=dirname(__DIR__);
$files=glob($root.'/db/mysql/{105,106,107,108,109,110,111,112,113,114,115,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146}_*.sql', GLOB_BRACE) ?: [];
$errors=[];
$totalBlocks=0;

if(count($files)!==41){
    $errors[]='Expected catalog migrations 105 through 115 plus 117-146 to be present.';
}

foreach($files as $file){
    $sql=(string)file_get_contents($file);
    preg_match_all(
        '/SELECT\s+m\.id,x\.name,x\.slug,x\.description.*?FROM\s+modules\s+m\s+JOIN\s*\(\s*(SELECT.*?\)\s*x\s+ON\s+x\.module_slug=m\.slug)/is',
        $sql,$matches
    );
    foreach($matches[1] ?? [] as $index => $block){
        $totalBlocks++;
        if(!preg_match("/\bslug\s*,\s*'(?:''|[^'])*'\s+description(?:\s*,|\s+UNION\s+ALL)/is",$block)){
            $errors[]=basename($file).': capability block '.($index+1).' uses x.description without explicitly aliasing the derived description column.';
        }
    }
}

if($totalBlocks!==35){
    $errors[]="Expected 35 capability derived-table blocks across catalog migrations 105-115 and 117-146; found {$totalBlocks}.";
}
if($errors){
    fwrite(STDERR,"Catalog derived-column alias check failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}
echo "Catalog derived-column alias check passed for all 35 capability blocks in catalog migrations 105-115 and 117-146.\n";
