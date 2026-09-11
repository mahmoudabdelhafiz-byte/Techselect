<?php
$schema=file_get_contents(__DIR__.'/../db/mysql/042_vendor_portfolios.sql');
$lib=file_get_contents(__DIR__.'/../app/lib/VendorPortfolio.php');
$page=file_get_contents(__DIR__.'/../vendor_profile.php');
$ht=file_get_contents(__DIR__.'/../.htaccess');
$fail=[];
foreach(['vendor_product_relationships','vendor_relationship_territories','software_owner','authorized_reseller','implementation_partner','verification_status','territory_type','territory_code'] as $n)if(strpos($schema,$n)===false)$fail[]='schema missing '.$n;
foreach(['RELATIONSHIP_TYPES','partnersForProduct','relationshipsForVendor','matchesTerritory','GCC','MENA','GLOBAL'] as $n)if(strpos($lib,$n)===false)$fail[]='model missing '.$n;
foreach(['Owned / developed software','Represented / partner software','Relationship evidence','do not influence TechSelectAI recommendation ranking'] as $n)if(strpos($page,$n)===false)$fail[]='profile missing '.$n;
if(strpos($ht,'^vendors/[a-z0-9-]+/?$ vendor_profile.php')===false)$fail[]='vendor route missing';
if($fail){fwrite(STDERR,implode("\n",$fail)."\n");exit(1);}echo "vendor_portfolio_check: OK\n";
