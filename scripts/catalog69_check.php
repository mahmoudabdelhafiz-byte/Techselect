<?php
$path=__DIR__.'/../db/mysql/069_catalog_pm_bi_collaboration.sql';
$sql=file_get_contents($path);
if($sql===false){fwrite(STDERR,"Unable to read migration 069\n");exit(1);}
$products=['asana','monday-work-management','clickup','wrike','smartsheet','zoho-projects','microsoft-power-bi','tableau','qlik-sense','looker','microsoft-teams','slack','google-workspace','zoom-workplace','notion'];
foreach($products as $slug){
    if(strpos($sql,"'{$slug}'")===false){fwrite(STDERR,"Missing product slug: {$slug}\n");exit(1);}
}
foreach(['project-management','business-intelligence','collaboration'] as $category){
    if(strpos($sql,"'{$category}'")===false){fwrite(STDERR,"Missing category: {$category}\n");exit(1);}
}
if(substr_count($sql,"'vendor_documentation'")<1 || substr_count($sql,"'verified','high'")<1){
    fwrite(STDERR,"First-party verified evidence seed missing\n");exit(1);
}
if(strpos($sql,"'not_yet_verified',0")===false){
    fwrite(STDERR,"Explicit unknown-state seeding missing\n");exit(1);
}
if(preg_match("/catalog69_facts[\\s\\S]*?'not_supported'/",$sql)){
    fwrite(STDERR,"Migration 069 must not infer unsupported facts from missing evidence\n");exit(1);
}
if(substr_count($sql,"'supported',0.")<30){
    fwrite(STDERR,"Expected at least 30 evidence-backed supported capability facts\n");exit(1);
}
echo "Catalog 069 contract OK: 15 products, 3 categories, evidence-first facts.\n";
