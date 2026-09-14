<?php

declare(strict_types=1);

$root = dirname(__DIR__);
$migration = $root . '/db/mysql/080_expand_thin_categories_batch2.sql';
if (!is_file($migration)) { fwrite(STDERR,"Missing migration: {$migration}\n"); exit(1); }
$sql = file_get_contents($migration) ?: '';
$failures = [];
$require = static function(bool $ok,string $message) use (&$failures): void { if(!$ok)$failures[]=$message; };

$require(stripos($sql,'INSERT INTO categories')===false,'080 must not create categories.');
$require(stripos($sql,'INSERT INTO modules')===false,'080 must not create modules.');
$require(stripos($sql,'INSERT INTO capabilities')===false,'080 must not create capabilities.');

$products=[
 'exabeam-new-scale-siem'=>'siem-security-operations',
 'sailpoint-identity-security-cloud'=>'identity-access-management',
 'wallix-bastion'=>'privileged-access-management',
 'koerber-warehouse-management'=>'warehouse-management-systems',
 'pega-platform'=>'low-code-bpm',
];
foreach($products as $slug=>$category){
 $require(substr_count($sql,"'{$slug}'")>=2,"Product {$slug} is not consistently referenced.");
 $require(strpos($sql,"'{$category}'")!==false,"Category {$category} is not reused for {$slug}.");
}

$require(strpos($sql,'ON DUPLICATE KEY UPDATE')!==false,'080 must be idempotent.');
$require(strpos($sql,'last_reviewed_at')!==false,'Products must update last_reviewed_at.');
$require(strpos($sql,"'not_yet_verified'")!==false,'Unknown facts must remain not_yet_verified.');
$require(strpos($sql,'product_capability_evidence')!==false,'Known facts must link to evidence.');
$require(strpos($sql,"1,'verified','high'")!==false,'Evidence must be vendor-owned, verified and high confidence.');
$require(stripos($sql,'g2.com')===false,'G2 data must not be ingested.');
$require(stripos($sql,'capterra')===false,'Capterra data must not be ingested.');

$officialHosts=['exabeam.com','docs.exabeam.com','sailpoint.com','documentation.sailpoint.com','wallix.com','koerber-supplychain.com','pega.com'];
preg_match_all("/'https:\/\/([^\/']+)[^']*'/",$sql,$urls);
foreach($urls[1]??[] as $host){
 $host=strtolower($host);$ok=false;
 foreach($officialHosts as $allowed){if($host===$allowed||str_ends_with($host,'.'.$allowed)){$ok=true;break;}}
 $require($ok,"Unexpected non-first-party host in migration: {$host}");
}

$migrationFiles=glob($root.'/db/mysql/*.sql')?:[];
foreach(array_keys($products) as $slug){
 $hits=0;
 foreach($migrationFiles as $file){if($file===$migration)continue;$text=file_get_contents($file)?:'';if(strpos($text,"'{$slug}'")!==false)$hits++;}
 $require($hits===0,"Potential duplicate product shell already exists for {$slug}.");
}

$require(strpos($sql,"SELECT p.id,i.id,'not_yet_verified',0")!==false,'Integration support must remain unknown when not reviewed.');
$require(strpos($sql,"'public-saas'")!==false,'080 should include verified SaaS deployment facts where explicit.');
$require(strpos($sql,"'on-premise'")!==false,'080 should include verified on-premise deployment facts where explicit.');

if($failures!==[]){foreach($failures as $failure)fwrite(STDERR,"FAIL: {$failure}\n");exit(1);} 
echo "Catalog 080 thin-category contract passed.\n";
