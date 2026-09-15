<?php
if(PHP_SAPI!=='cli'){http_response_code(404);exit;}
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/Mailer.php';
require_once __DIR__.'/../app/lib/ProductFollows.php';
$config=require __DIR__.'/../app/config.php';
$pdo=Db::pdo();
$base=rtrim((string)($config['site_url']??'https://techselectai.com'),'/');
$products=$pdo->query("SELECT id,name,slug,last_reviewed_at FROM products WHERE status='active' ORDER BY id")->fetchAll()?:[];
$baseline=0;$events=0;$sent=0;$failed=0;
foreach($products as $product){
    $pid=(int)$product['id'];$snapshot=ProductFollows::semanticSnapshot($pdo,$pid);$json=json_encode($snapshot,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);$hash=ProductFollows::snapshotHash($snapshot);
    $st=$pdo->prepare("SELECT semantic_hash FROM product_follow_snapshots WHERE product_id=? LIMIT 1");$st->execute([$pid]);$old=$st->fetchColumn();
    if(!$old){$pdo->prepare("INSERT INTO product_follow_snapshots(product_id,semantic_hash,snapshot_json,checked_at) VALUES(?,?,?,NOW())")->execute([$pid,$hash,$json]);$baseline++;continue;}
    if(hash_equals((string)$old,$hash)){$pdo->prepare("UPDATE product_follow_snapshots SET checked_at=NOW() WHERE product_id=?")->execute([$pid]);continue;}
    $summary='TechSelectAI detected meaningful changes to the researched product profile, such as capabilities, deployment, integrations, pricing, editions, or product details.';
    $pdo->prepare("INSERT IGNORE INTO product_update_events(product_id,previous_hash,current_hash,change_summary,detected_at) VALUES(?,?,?,?,NOW())")->execute([$pid,$old,$hash,$summary]);$eventId=(int)$pdo->lastInsertId();
    $pdo->prepare("UPDATE product_follow_snapshots SET semantic_hash=?,snapshot_json=?,checked_at=NOW(),updated_at=NOW() WHERE product_id=?")->execute([$hash,$json,$pid]);if(!$eventId)continue;$events++;
    $q=$pdo->prepare("SELECT pf.id follow_id,pf.unsubscribe_token,u.email,u.full_name FROM product_follows pf JOIN users u ON u.id=pf.user_id WHERE pf.product_id=? AND pf.status='active' AND u.status='active' AND u.email_verified_at IS NOT NULL");$q->execute([$pid]);
    foreach($q->fetchAll()?:[] as $f){
        $pdo->prepare("INSERT IGNORE INTO product_update_deliveries(event_id,follow_id,status) VALUES(?,?,'pending')")->execute([$eventId,(int)$f['follow_id']]);$check=$pdo->prepare("SELECT id,status FROM product_update_deliveries WHERE event_id=? AND follow_id=? LIMIT 1");$check->execute([$eventId,(int)$f['follow_id']]);$delivery=$check->fetch();if(!$delivery||$delivery['status']==='sent')continue;
        $productUrl=$base.'/software/'.$product['slug'];$unsubscribeUrl=$base.'/product_follow_unsubscribe.php?token='.$f['unsubscribe_token'];$subject=$product['name'].' has new verified updates on TechSelectAI';
        $body="Hello ".$f['full_name'].",\n\nTechSelectAI detected meaningful updates to the researched profile for ".$product['name'].".\n\nReview the latest evidence-backed profile:\n".$productUrl."\n\nWhat may have changed: capabilities, integrations, deployment/mobile access, pricing/editions, or other researched product facts. Unknown information remains not yet verified rather than unsupported.\n\nUnfollow only this product:\n".$unsubscribeUrl."\n\nTechSelectAI\n";
        $ok=Mailer::send($config,(string)$f['email'],$subject,$body);
        if($ok){$pdo->prepare("UPDATE product_update_deliveries SET status='sent',attempted_at=NOW(),sent_at=NOW(),error_message=NULL WHERE id=?")->execute([(int)$delivery['id']]);$pdo->prepare("UPDATE product_follows SET last_notified_at=NOW() WHERE id=?")->execute([(int)$f['follow_id']]);$sent++;}
        else{$pdo->prepare("UPDATE product_update_deliveries SET status='failed',attempted_at=NOW(),error_message='mail_transport_failed' WHERE id=?")->execute([(int)$delivery['id']]);$failed++;}
    }
}
echo json_encode(['products'=>count($products),'baselines'=>$baseline,'events'=>$events,'sent'=>$sent,'failed'=>$failed],JSON_UNESCAPED_SLASHES).PHP_EOL;
