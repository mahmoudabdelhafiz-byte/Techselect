<?php
final class UserConsultationHistory {
  public static function create(PDO $pdo, ?array $user, string $businessProblem, string $source='ai_chat', array $acquisition=[]): array {
    $visitorRaw=bin2hex(random_bytes(24));
    $visitorHash=hash('sha256',$visitorRaw,true);
    $public=bin2hex(random_bytes(24));
    $uid=$user ? (int)$user['id'] : null;
    $utmSource=self::clean($acquisition['utm_source']??null,190);
    $utmMedium=self::clean($acquisition['utm_medium']??null,190);
    $utmCampaign=self::clean($acquisition['utm_campaign']??null,190);
    $referrer=self::clean($acquisition['referrer']??null,1000);
    $pdo->beginTransaction();
    try {
      $st=$pdo->prepare("INSERT INTO visitor_sessions(session_token_hash,user_id,utm_source,utm_medium,utm_campaign,referrer) VALUES(?,?,?,?,?,?)");
      $st->execute([$visitorHash,$uid,$utmSource,$utmMedium,$utmCampaign,$referrer]);
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

  private static function clean($v,int $max):?string{$v=trim((string)$v);return $v===''?null:mb_substr($v,0,$max);}

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

  public static function resumeForUser(PDO $pdo, int $userId, string $publicToken): ?array {
    if(!preg_match('/^[a-f0-9]{48}$/',$publicToken)) return null;
    $st=$pdo->prepare("SELECT id,public_token,business_problem FROM consultations WHERE public_token=? AND user_id=? LIMIT 1");
    $st->execute([$publicToken,$userId]);$c=$st->fetch();if(!$c)return null;
    $messages=$pdo->prepare("SELECT sender_type,message_text FROM consultation_messages WHERE consultation_id=? ORDER BY created_at,id");
    $messages->execute([$c['id']]);
    $uiMessages=[];foreach($messages->fetchAll()?:[] as $m)$uiMessages[]=['role'=>$m['sender_type']==='assistant'?'assistant':'user','text'=>$m['message_text']];
    $rec=$pdo->prepare("SELECT cr.recommendation_rank rank,cr.overall_score overall,cr.functional_score functional,cr.mandatory_score mandatory,cr.evidence_score evidence,cr.recommendation_status status,cr.mandatory_gap_count mandatory_gaps,p.id product_id,p.name product_name,p.slug product_slug FROM consultation_recommendations cr JOIN products p ON p.id=cr.product_id WHERE cr.consultation_id=? ORDER BY cr.generated_at DESC,cr.recommendation_rank ASC LIMIT 10");
    $rec->execute([$c['id']]);$results=[];
    foreach($rec->fetchAll()?:[] as $r)$results[]=['rank'=>(int)$r['rank'],'product'=>['id'=>(int)$r['product_id'],'name'=>$r['product_name'],'slug'=>$r['product_slug']],'overall'=>(float)$r['overall'],'functional'=>(float)$r['functional'],'mandatory'=>(float)$r['mandatory'],'evidence'=>(float)$r['evidence'],'status'=>$r['status'],'mandatory_gaps'=>(int)$r['mandatory_gaps']];
    return ['problem'=>$c['business_problem'],'c'=>['consultation_id'=>(int)$c['id'],'public_token'=>$c['public_token'],'saved_to_account'=>true],'msgs'=>$uiMessages,'extraction'=>null,'results'=>$results];
  }
}
