<?php
$root=dirname(__DIR__);
$files=[
  'migration'=>$root.'/db/mysql/039_catalog_expansion_batch3.sql',
  'guard'=>$root.'/app/lib/CategoryGuard.php',
  'sitemap'=>$root.'/sitemap.php',
];
foreach($files as $name=>$path){if(!is_file($path)){fwrite(STDERR,"missing $name: $path\n");exit(1);}}
$m=file_get_contents($files['migration']);$g=file_get_contents($files['guard']);$s=file_get_contents($files['sitemap']);
$categories=['ai-platforms','healthcare-ehr','retail-pos','cad-engineering'];
$products=['microsoft-foundry','google-vertex-ai','amazon-bedrock','ibm-watsonx-ai','epic-ehr','oracle-health-ehr','intersystems-trakcare','meditech-expanse','oracle-retail-xstore','shopify-pos','lightspeed-retail-pos','square-for-retail','autodesk-autocad','solidworks','siemens-nx-cad','ptc-creo'];
foreach($categories as $x){if(strpos($m,"'$x'")===false||strpos($g,"'$x'")===false){fwrite(STDERR,"missing category/alias: $x\n");exit(1);}}
foreach($products as $x){if(strpos($m,"'$x'")===false){fwrite(STDERR,"missing product: $x\n");exit(1);}}
if(substr_count($m,"'not_yet_verified',0")<1){fwrite(STDERR,"missing conservative unknown defaults\n");exit(1);}
if(stripos($m,'product_pricing')!==false||stripos($m,'product_compliance')!==false||stripos($m,'product_regional_availability')!==false){fwrite(STDERR,"unexpected pricing/compliance/regional claims\n");exit(1);}
if(strpos($s,"COUNT(*) FROM product_capabilities")===false||strpos($s,"EXISTS(SELECT 1 FROM evidence_sources")===false){fwrite(STDERR,"sitemap evidence gate missing\n");exit(1);}
if(strpos($s,"/software/")===false||strpos($s,"/categories/")===false||strpos($s,"/compare/")===false){fwrite(STDERR,"sitemap catalog routes missing\n");exit(1);}
echo "catalog expansion batch 3 static checks passed\n";
