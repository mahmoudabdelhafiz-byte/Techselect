<?php
final class EvidenceRefreshScheduler{
  private const LOCK_NAME='techselectai:evidence-refresh-scheduler';
  private const DEFAULT_INTERVAL_HOURS=168;
  private const DEFAULT_LIMIT=25;
  private const MAX_LIMIT=100;

  public static function run(PDO $pdo,int $intervalHours=self::DEFAULT_INTERVAL_HOURS,int $limit=self::DEFAULT_LIMIT):array{
    if($intervalHours<1||$intervalHours>8760)throw new InvalidArgumentException('invalid_interval_hours');
    if($limit<1||$limit>self::MAX_LIMIT)throw new InvalidArgumentException('invalid_batch_limit');

    $lock=$pdo->query("SELECT GET_LOCK(".$pdo->quote(self::LOCK_NAME).",0)")->fetchColumn();
    if((int)$lock!==1)throw new RuntimeException('scheduler_locked');

    try{
      $sql="SELECT es.id,COALESCE(MAX(rc.checked_at),es.checked_at) last_attempt_at FROM evidence_sources es JOIN products p ON p.id=es.product_id LEFT JOIN evidence_refresh_checks rc ON rc.evidence_source_id=es.id WHERE p.status='active' AND TRIM(COALESCE(es.source_url,''))<>'' GROUP BY es.id,es.checked_at HAVING last_attempt_at<=DATE_SUB(NOW(),INTERVAL {$intervalHours} HOUR) ORDER BY last_attempt_at ASC,es.id ASC LIMIT {$limit}";
      $rows=$pdo->query($sql)->fetchAll();$ids=array_map(static fn($r)=>(int)$r['id'],$rows);
      $summary=['selected'=>count($ids),'checked'=>0,'initial'=>0,'unchanged'=>0,'changed'=>0,'errors'=>0,'candidates_created'=>0,'results'=>[]];

      foreach($ids as $sourceId){
        try{$result=EvidenceRefresh::check($pdo,$sourceId);}
        catch(Throwable $e){$result=['source_id'=>$sourceId,'state'=>'error','error'=>'runner_source_failure'];}
        $summary['checked']++;
        $state=(string)($result['state']??'error');
        if($state==='error')$summary['errors']++;
        elseif(isset($summary[$state]))$summary[$state]++;
        else $summary['errors']++;
        if(!empty($result['candidate_created']))$summary['candidates_created']++;
        $summary['results'][]=$result;
      }
      return $summary;
    }finally{
      try{$pdo->query("SELECT RELEASE_LOCK(".$pdo->quote(self::LOCK_NAME).")");}catch(Throwable $ignored){}
    }
  }
}
