<?php
$path=__DIR__.'/../software_reviews_page.php';
$src=file_get_contents($path);
if($src===false){fwrite(STDERR,"Cannot read software_reviews_page.php\n");exit(1);}
$required=[
  "ProductEvaluation::publishedForProduct",
  "TechSelectAI Product Evaluation",
  "Independent product assessment",
  "techselect-evaluation",
  "methodology_version",
  "evidence_count",
  "Product Evaluation, and Public Review Intelligence",
  "See methodology",
];
foreach($required as $needle){
  if(strpos($src,$needle)===false){fwrite(STDERR,"Missing public evaluation UI contract: {$needle}\n");exit(1);}
}
if(strpos($src,"require_once __DIR__.'/app/lib/ProductEvaluation.php';")===false){fwrite(STDERR,"ProductEvaluation dependency not loaded\n");exit(1);}
if(strpos($src,'$productEvaluation=null')===false){fwrite(STDERR,"Graceful no-evaluation state missing\n");exit(1);}
echo "product_evaluation_public_ui_check: OK\n";
