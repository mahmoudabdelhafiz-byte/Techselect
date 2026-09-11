<?php
$schema=file_get_contents(__DIR__.'/../db/mysql/045_vendor_relationship_claims.sql');
$lib=file_get_contents(__DIR__.'/../app/lib/VendorRelationshipClaim.php');
$admin=file_get_contents(__DIR__.'/../api/vendor_relationship_claim_admin.php');
$routes=file_get_contents(__DIR__.'/../.htaccess');
$fail=[];
foreach(['vendor_relationship_claims','territory_fingerprint','vendor_relationship_claim_history','relationship_id'] as $n)if(strpos($schema,$n)===false)$fail[]='schema missing '.$n;
foreach(['authorized_reseller','implementation_partner','local_agent','territory_required','fingerprint','verification_status=\'verified\'','vendor_relationship_territories'] as $n)if(strpos($lib,$n)===false)$fail[]='service missing '.$n;
foreach(['request_information','approve','reject','revoke','VENDOR_RELATIONSHIP_CLAIM_'] as $n)if(strpos($admin,$n)===false)$fail[]='admin missing '.$n;
foreach(['add-existing-software','vendor-relationship-claims-admin','api/vendor-relationship-claims'] as $n)if(strpos($routes,$n)===false)$fail[]='route missing '.$n;
$territories=[['type'=>'country','code'=>'sa','name'=>'Saudi Arabia'],['type'=>'region','code'=>'gcc','name'=>'GCC']];
require_once __DIR__.'/../app/lib/VendorRelationshipClaim.php';
if(count(VendorRelationshipClaim::normalizeTerritories($territories))!==2)$fail[]='territory normalization failed';
if(VendorRelationshipClaim::fingerprint($territories)!==VendorRelationshipClaim::fingerprint(array_reverse($territories)))$fail[]='territory fingerprint must be order-independent';
if($fail){fwrite(STDERR,implode("\n",$fail)."\n");exit(1);}echo "vendor_relationship_claim_check: OK\n";
