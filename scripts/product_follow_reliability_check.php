<?php
$root=dirname(__DIR__);$failed=[];
$files=[
 'app/lib/ProductFollows.php',
 'scripts/product_follow_updates.php',
 'product_follow_unsubscribe.php',
 'db/mysql/103_product_follow_reliability.sql',
];
foreach($files as $file)if(!is_file($root.'/'.$file))$failed[]="missing $file";
$lib=@file_get_contents($root.'/app/lib/ProductFollows.php')?:'';
$worker=@file_get_contents($root.'/scripts/product_follow_updates.php')?:'';
$unsub=@file_get_contents($root.'/product_follow_unsubscribe.php')?:'';
$migration=@file_get_contents($root.'/db/mysql/103_product_follow_reliability.sql')?:'';
foreach(['pi.notes','pd.notes','scope,evidence_url'] as $legacy)if(strpos($lib,$legacy)!==false)$failed[]="semantic snapshot still references legacy field pattern: $legacy";
foreach(['SELECT i.slug AS integration_slug,pi.*','SELECT dm.slug AS deployment_slug,pd.*','SELECT * FROM product_mobile_access'] as $needle)if(strpos($lib,$needle)===false)$failed[]="snapshot hardening missing: $needle";
if(strpos($unsub,"$method==='POST'")===false||strpos($unsub,'unsubscribeTarget')===false)$failed[]='unsubscribe must preview on GET and mutate only after POST confirmation';
if(strpos($worker,"d.status IN ('pending','failed')")===false||strpos($worker,'attempt_count<5')===false)$failed[]='worker must retry pending/failed deliveries independently';
if(strpos($worker,'INSERT IGNORE INTO product_update_events')!==false)$failed[]='event creation must not suppress legitimate repeated state transitions';
foreach(['DROP INDEX uq_product_update_hash','idx_product_update_hash(product_id,current_hash)','attempt_count','next_attempt_at'] as $needle)if(strpos($migration,$needle)===false)$failed[]="migration missing $needle";
if($failed){fwrite(STDERR,"Product Follow reliability checks failed:\n- ".implode("\n- ",$failed)."\n");exit(1);}echo "Product Follow reliability checks passed.\n";
