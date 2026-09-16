<?php
if(PHP_SAPI!=='cli'){http_response_code(404);exit;}
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/Mailer.php';
require_once __DIR__.'/../app/lib/ProductFollows.php';
$config=require __DIR__.'/../app/config.php';
$pdo=Db::pdo();
$base=rtrim((string)($config['site_url']??'https://techselectai.com'),'/');
$products=$pdo->query("SELECT id,name,slug,last_reviewed_at FROM products WHERE status='active' ORDER BY id")->fetchAll()?:[];
$baseline=0;$events=0;$queued=0;$sent=0;$failed=0;

foreach($products as $product){
    $pid=(int)$product['id'];
    $snapshot=ProductFollows::semanticSnapshot($pdo,$pid);
    $json=json_encode($snapshot,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);
    $hash=ProductFollows::snapshotHash($snapshot);
    $st=$pdo->prepare("SELECT semantic_hash FROM product_follow_snapshots WHERE product_id=? LIMIT 1");
    $st->execute([$pid]);
    $old=$st->fetchColumn();

    if(!$old){
        $pdo->prepare("INSERT INTO product_follow_snapshots(product_id,semantic_hash,snapshot_json,checked_at) VALUES(?,?,?,NOW())")
            ->execute([$pid,$hash,$json]);
        $baseline++;
        continue;
    }

    if(hash_equals((string)$old,$hash)){
        $pdo->prepare("UPDATE product_follow_snapshots SET checked_at=NOW() WHERE product_id=?")->execute([$pid]);
        continue;
    }

    $summary='TechSelectAI detected meaningful changes to the researched product profile, such as capabilities, deployment, integrations, pricing, editions, or product details.';
    $pdo->prepare("INSERT INTO product_update_events(product_id,previous_hash,current_hash,change_summary,detected_at) VALUES(?,?,?,?,NOW())")
        ->execute([$pid,$old,$hash,$summary]);
    $eventId=(int)$pdo->lastInsertId();
    $pdo->prepare("UPDATE product_follow_snapshots SET semantic_hash=?,snapshot_json=?,checked_at=NOW(),updated_at=NOW() WHERE product_id=?")
        ->execute([$hash,$json,$pid]);
    $events++;

    $q=$pdo->prepare("SELECT pf.id follow_id FROM product_follows pf JOIN users u ON u.id=pf.user_id WHERE pf.product_id=? AND pf.status='active' AND u.status='active' AND u.email_verified_at IS NOT NULL");
    $q->execute([$pid]);
    foreach($q->fetchAll()?:[] as $f){
        $pdo->prepare("INSERT IGNORE INTO product_update_deliveries(event_id,follow_id,status,attempt_count,next_attempt_at) VALUES(?,?,'pending',0,NOW())")
            ->execute([$eventId,(int)$f['follow_id']]);
        $queued++;
    }
}

// Delivery is deliberately independent from snapshot detection. This allows transient
// mail failures to retry on later worker runs even when no additional product change
// has occurred since the original event.
$deliveries=$pdo->query("SELECT d.id,d.event_id,d.follow_id,d.attempt_count,e.product_id,p.name product_name,p.slug product_slug,pf.unsubscribe_token,u.email,u.full_name FROM product_update_deliveries d JOIN product_update_events e ON e.id=d.event_id JOIN products p ON p.id=e.product_id JOIN product_follows pf ON pf.id=d.follow_id JOIN users u ON u.id=pf.user_id WHERE d.status IN ('pending','failed') AND d.attempt_count<5 AND (d.next_attempt_at IS NULL OR d.next_attempt_at<=NOW()) AND pf.status='active' AND u.status='active' AND u.email_verified_at IS NOT NULL ORDER BY d.created_at,d.id LIMIT 250")->fetchAll()?:[];
foreach($deliveries as $d){
    $productUrl=$base.'/software/'.$d['product_slug'];
    $unsubscribeUrl=$base.'/product_follow_unsubscribe.php?token='.$d['unsubscribe_token'];
    $subject=$d['product_name'].' has new verified updates on TechSelectAI';
    $body="Hello ".$d['full_name'].",\n\nTechSelectAI detected meaningful updates to the researched profile for ".$d['product_name'].".\n\nReview the latest evidence-backed profile:\n".$productUrl."\n\nWhat may have changed: capabilities, integrations, deployment/mobile access, pricing/editions, or other researched product facts. Unknown information remains not yet verified rather than unsupported.\n\nUnfollow only this product:\n".$unsubscribeUrl."\n\nTechSelectAI\n";
    $ok=Mailer::send($config,(string)$d['email'],$subject,$body);
    if($ok){
        $pdo->prepare("UPDATE product_update_deliveries SET status='sent',attempt_count=attempt_count+1,attempted_at=NOW(),next_attempt_at=NULL,sent_at=NOW(),error_message=NULL WHERE id=?")
            ->execute([(int)$d['id']]);
        $pdo->prepare("UPDATE product_follows SET last_notified_at=NOW() WHERE id=?")->execute([(int)$d['follow_id']]);
        $sent++;
    }else{
        $pdo->prepare("UPDATE product_update_deliveries SET status='failed',attempt_count=attempt_count+1,attempted_at=NOW(),next_attempt_at=DATE_ADD(NOW(),INTERVAL 30 MINUTE),error_message='mail_transport_failed' WHERE id=?")
            ->execute([(int)$d['id']]);
        $failed++;
    }
}

echo json_encode(['products'=>count($products),'baselines'=>$baseline,'events'=>$events,'queued'=>$queued,'sent'=>$sent,'failed'=>$failed],JSON_UNESCAPED_SLASHES).PHP_EOL;
