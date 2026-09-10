<?php
final class UserConsultationHistory {
  public static function create(PDO $pdo, ?array $user, string $businessProblem, string $source='ai_chat'): array {
    $visitorRaw=bin2hex(random_bytes(24));
    $visitorHash=hash('sha256',$visitorRaw,true);
    $public=bin2hex(random_bytes(24));
    $uid=$user ? (int)$user['id'] : null;
    $pdo->beginTransaction();
    try {
      $st=$pdo->prepare("INSERT INTO visitor_sessions(session_token_hash,user_id) VALUES(?,?)");
      $st->execute([$visitorHash,$uid]);
      $visitorId=(int)$pdo->lastInsertId();
      $st=$pdo->prepare("INSERT INTO consultations(public_token,visitor_session_id,user_id,business_problem,original_user_request,consultation_source,status) VALUES(?,?,?,?,?,?,'in_progress')");
      $st->execute([$public,$visitorId,$uid,$businessProblem,$businessProblem,$source]);
      $id=(int)$pdo->lastInsertId();
      $pdo->prepare("INSERT INTO consultation_messages(consultation_id,sender_type,message_text,message_type) VALUES(?,'user',?,'normal')")->execute([$id,$businessProblem]);
      $pdo->commit();
      return ['consultation_id'=>$id,'public_token'=>$public,'visitor_token'=>$visitorRaw,'saved_to_account'=>$uid!==null];
    } catch(Throwable $e) {
      if($pdo->inTransaction()) $pdo->rollBack();
      throw $e;
    }
  }

  public static function claim(PDO $pdo, int $userId, string $visitorToken): int {
    if(!preg_match('/^[a-f0-9]{48}$/',$visitorToken)) return 0;
    $hash=hash('sha256',$visitorToken,true);
    $pdo->beginTransaction();
    try {
      $st=$pdo->prepare("SELECT id,user_id FROM visitor_sessions WHERE session_token_hash=? LIMIT 1 FOR UPDATE");
      $st->execute([$hash]);
      $session=$st->fetch();
      if(!$session){$pdo->rollBack();return 0;}
      if($session['user_id']!==null && (int)$session['user_id']!==$userId){$pdo->rollBack();return 0;}
      $sid=(int)$session['id'];
      $pdo->prepare("UPDATE visitor_sessions SET user_id=?,last_seen_at=NOW() WHERE id=?")->execute([$userId,$sid]);
      $st=$pdo->prepare("UPDATE consultations SET user_id=? WHERE visitor_session_id=? AND user_id IS NULL");
      $st->execute([$userId,$sid]);
      $claimed=$st->rowCount();
      $pdo->commit();
      return $claimed;
    } catch(Throwable $e) {
      if($pdo->inTransaction()) $pdo->rollBack();
      throw $e;
    }
  }

  public static function listForUser(PDO $pdo, int $userId, int $limit=50): array {
    $limit=max(1,min(100,$limit));
    $sql="SELECT c.id,c.public_token,c.title,c.business_problem,c.status,c.consultation_source,c.started_at,c.completed_at,c.updated_at,cat.name category,cat.slug category_slug,COUNT(DISTINCT r.id) recommendation_count FROM consultations c LEFT JOIN categories cat ON cat.id=c.category_id LEFT JOIN consultation_recommendations r ON r.consultation_id=c.id WHERE c.user_id=? GROUP BY c.id,c.public_token,c.title,c.business_problem,c.status,c.consultation_source,c.started_at,c.completed_at,c.updated_at,cat.name,cat.slug ORDER BY c.updated_at DESC,c.id DESC LIMIT ".$limit;
    $st=$pdo->prepare($sql);$st->execute([$userId]);$rows=$st->fetchAll()?:[];
    if(!$rows) return [];
    $top=$pdo->prepare("SELECT cr.consultation_id,p.name,p.slug,cr.recommendation_rank,cr.overall_score FROM consultation_recommendations cr JOIN products p ON p.id=cr.product_id WHERE cr.consultation_id=? ORDER BY cr.recommendation_rank ASC,cr.overall_score DESC LIMIT 3");
    foreach($rows as &$row){$top->execute([(int)$row['id']]);$row['top_recommendations']=$top->fetchAll()?:[];}
    unset($row);
    return $rows;
  }
}
