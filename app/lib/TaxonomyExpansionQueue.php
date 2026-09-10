<?php
final class TaxonomyExpansionQueue {
  private static function normalize(string $topic): array {
    $label=trim(preg_replace('/\s+/u',' ',$topic));
    $key=mb_strtolower($label,'UTF-8');
    $key=preg_replace('/[^\p{L}\p{N}]+/u','-',$key);
    $key=trim($key,'-');
    if($key==='')$key='unmapped-technology';
    return [mb_substr($key,0,160,'UTF-8'),mb_substr($label?:'Unmapped technology',0,180,'UTF-8')];
  }

  public static function capture(PDO $pdo,string $topic,string $example,?int $consultationId=null): void {
    [$key,$label]=self::normalize($topic);
    $example=mb_substr(trim($example),0,1000,'UTF-8');
    $pdo->beginTransaction();
    try{
      $st=$pdo->prepare("INSERT INTO taxonomy_expansion_queue(topic_key,topic_label,occurrence_count,first_seen_at,last_seen_at,latest_example_request) VALUES(?,?,1,NOW(),NOW(),?) ON DUPLICATE KEY UPDATE topic_label=VALUES(topic_label),occurrence_count=occurrence_count+1,last_seen_at=NOW(),latest_example_request=VALUES(latest_example_request),updated_at=NOW()");
      $st->execute([$key,$label,$example?:null]);
      $q=$pdo->prepare("SELECT id FROM taxonomy_expansion_queue WHERE topic_key=? LIMIT 1");$q->execute([$key]);$queueId=(int)$q->fetchColumn();
      if($queueId){$o=$pdo->prepare("INSERT INTO taxonomy_expansion_occurrences(queue_id,consultation_id,example_request) VALUES(?,?,?)");$o->execute([$queueId,$consultationId,$example?:null]);}
      $pdo->commit();
    }catch(Throwable $e){if($pdo->inTransaction())$pdo->rollBack();throw $e;}
  }

  public static function list(PDO $pdo): array {
    return $pdo->query("SELECT id,topic_key,topic_label,occurrence_count,first_seen_at,last_seen_at,latest_example_request,status,priority,admin_notes,updated_at FROM taxonomy_expansion_queue ORDER BY FIELD(priority,'high','normal','low'), occurrence_count DESC,last_seen_at DESC")->fetchAll();
  }

  public static function update(PDO $pdo,int $id,array $data): array {
    $status=(string)($data['status']??'new');$priority=(string)($data['priority']??'normal');$notes=isset($data['admin_notes'])?trim((string)$data['admin_notes']):null;
    if(!in_array($status,['new','researching','planned','added_to_catalog','ignored'],true))throw new InvalidArgumentException('invalid_status');
    if(!in_array($priority,['high','normal','low'],true))throw new InvalidArgumentException('invalid_priority');
    $st=$pdo->prepare("UPDATE taxonomy_expansion_queue SET status=?,priority=?,admin_notes=?,updated_at=NOW() WHERE id=?");$st->execute([$status,$priority,$notes?:null,$id]);
    $q=$pdo->prepare("SELECT id,topic_key,topic_label,occurrence_count,first_seen_at,last_seen_at,latest_example_request,status,priority,admin_notes,updated_at FROM taxonomy_expansion_queue WHERE id=?");$q->execute([$id]);$row=$q->fetch();if(!$row)throw new RuntimeException('not_found');return $row;
  }
}
