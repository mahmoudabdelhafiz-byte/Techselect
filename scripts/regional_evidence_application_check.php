<?php
$root=dirname(__DIR__);
$checks=[
 'db/mysql/029_regional_availability.sql'=>['CREATE TABLE IF NOT EXISTS product_regional_availability','availability_status VARCHAR(40) NOT NULL DEFAULT \'not_yet_verified\'','UNIQUE KEY uq_product_regional_availability','EG','SA','AE'],
 'app/lib/EvidenceFactApplicator.php'=>['REGIONAL_STATUSES','regional_availability','product_regional_availability','availability_status','availability_notes','invalid_country_code','invalid_availability_status','regionalSnapshot','source_url','last_verified_at'],
 'evidence_refresh_review.js'=>['Regional availability','ISO alpha-2 country code','availability_status','availability_notes','does not change scoring']
];
$failed=[];
foreach($checks as $file=>$needles){$text=@file_get_contents($root.'/'.$file)?:'';foreach($needles as $needle)if(strpos($text,$needle)===false)$failed[]="$file missing $needle";}
$migration=@file_get_contents($root.'/db/mysql/029_regional_availability.sql')?:'';
if(strpos($migration,"INSERT INTO product_regional_availability")!==false)$failed[]='Regional migration must not seed product availability claims';
$svc=@file_get_contents($root.'/app/lib/EvidenceFactApplicator.php')?:'';
if(strpos($svc,"private const REGIONAL_STATUSES=['available','limited_availability','not_available','not_yet_verified']")===false)$failed[]='Regional status allowlist missing';
if(strpos($svc,"['availability_status','confidence_score','availability_notes']")===false)$failed[]='Regional field allowlist missing';
if(strpos($svc,"$proposalDomain==='regional_availability'&&$targetDomain==='regional'")===false)$failed[]='Regional proposal/domain compatibility missing';
if(strpos($svc,"SELECT id FROM countries WHERE code=?")===false)$failed[]='Regional application must resolve canonical countries';
if(strpos($svc,"source_url=?,last_verified_at=NOW()")===false)$failed[]='Regional application must retain source and verification timestamp';
if($failed){fwrite(STDERR,"Regional evidence application checks failed:\n- ".implode("\n- ",$failed)."\n");exit(1);}echo "Regional evidence application checks passed.\n";
