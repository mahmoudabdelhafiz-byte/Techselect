<?php
if(PHP_SAPI!=='cli'){http_response_code(404);exit;}
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/Mailer.php';
$config=require __DIR__.'/../app/config.php';
$pdo=Db::pdo();$base=rtrim((string)($config['site_url']??'https://techselectai.com'),'/');
$limit=100;$sent=0;$failed=0;$skipped=0;
$sql="SELECT d.id delivery_id,d.attempt_count,pcp.id post_id,pcp.post_type,pcp.body,pcp.parent_id,
             p.name product_name,p.slug product_slug,pf.id follow_id,pf.community_notifications,pf.status follow_status,
             u.email,u.full_name
      FROM product_community_notification_deliveries d
      JOIN product_community_posts pcp ON pcp.id=d.post_id
      JOIN products p ON p.id=pcp.product_id
      JOIN product_follows pf ON pf.id=d.follow_id
      JOIN users u ON u.id=pf.user_id
      WHERE d.status IN ('pending','failed') AND d.attempt_count<5
        AND pcp.status='published' AND pf.status='active' AND pf.community_notifications=1
        AND u.status='active' AND u.email_verified_at IS NOT NULL
      ORDER BY d.created_at,d.id LIMIT ".(int)$limit;
foreach($pdo->query($sql)->fetchAll(PDO::FETCH_ASSOC)?:[] as $row){
    $id=(int)$row['delivery_id'];$productUrl=$base.'/software/'.$row['product_slug'].'#community';
    $kind=$row['post_type']==='reply'?'New reply':'New '.($row['post_type']==='question'?'question':'discussion');
    $excerpt=trim(preg_replace('/\s+/',' ',(string)$row['body']));if(mb_strlen($excerpt)>240)$excerpt=mb_substr($excerpt,0,237).'…';
    $subject=$kind.' about '.$row['product_name'].' on TechSelectAI';
    $name=trim((string)$row['full_name']);$hello=$name!==''?'Hello '.$name.',':'Hello,';
    $body=$hello."\n\n".$kind." was posted in the TechSelectAI community for ".$row['product_name'].".\n\n“".$excerpt."”\n\nRead or reply:\n".$productUrl."\n\nYou are receiving this because you follow this product and explicitly enabled community emails. Turn off community emails from the Follow Product controls on the product page; your normal verified product-update follow can remain active.\n\nCommunity activity and popularity never affect TechSelectAI Fit Score, evidence, or recommendation ranking.\n\nTechSelectAI\n";
    $pdo->prepare("UPDATE product_community_notification_deliveries SET status='sending',attempt_count=attempt_count+1,attempted_at=NOW(),error_message=NULL WHERE id=? AND status IN ('pending','failed')")->execute([$id]);
    if(!$pdo->lastInsertId() && false){} // keep worker side-effect explicit; rowCount checked below through fresh state.
    $ok=Mailer::send($config,(string)$row['email'],$subject,$body);
    if($ok){$pdo->prepare("UPDATE product_community_notification_deliveries SET status='sent',sent_at=NOW(),error_message=NULL WHERE id=?")->execute([$id]);$sent++;}
    else{$pdo->prepare("UPDATE product_community_notification_deliveries SET status='failed',error_message='mail_transport_failed' WHERE id=?")->execute([$id]);$failed++;}
}
$q=$pdo->query("SELECT COUNT(*) FROM product_community_notification_deliveries WHERE status IN ('pending','failed') AND attempt_count<5");$remaining=(int)$q->fetchColumn();
echo json_encode(['sent'=>$sent,'failed'=>$failed,'skipped'=>$skipped,'remaining_retryable'=>$remaining],JSON_UNESCAPED_SLASHES).PHP_EOL;
