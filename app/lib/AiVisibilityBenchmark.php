<?php
final class AiVisibilityBenchmark {
    public static function prompts(PDO $pdo): array {
        return $pdo->query("SELECT id,prompt_key,prompt_text,query_type,category_key,context_label,is_active,sort_order FROM ai_visibility_prompts ORDER BY sort_order,id")->fetchAll(PDO::FETCH_ASSOC);
    }
    public static function dashboard(PDO $pdo,array $f=[]): array {
        $where=["o.observation_status='valid'"];$args=[];
        if(!empty($f['provider'])){$where[]='r.provider=?';$args[]=(string)$f['provider'];}
        if(!empty($f['query_type'])){$where[]='p.query_type=?';$args[]=(string)$f['query_type'];}
        $days=max(1,min(365,(int)($f['days']??90)));$where[]="o.answer_date>=DATE_SUB(NOW(),INTERVAL {$days} DAY)";
        $base=" FROM ai_visibility_observations o JOIN ai_visibility_runs r ON r.id=o.run_id JOIN ai_visibility_prompts p ON p.id=o.prompt_id WHERE ".implode(' AND ',$where);
        $st=$pdo->prepare("SELECT COUNT(*) valid_count,SUM(o.mentioned=1) mentions,SUM(o.cited=1) citations,COUNT(DISTINCT CASE WHEN o.cited=1 THEN o.cited_url END) unique_pages".$base);$st->execute($args);$m=$st->fetch(PDO::FETCH_ASSOC)?:[];$valid=(int)($m['valid_count']??0);
        $metrics=['valid_observations'=>$valid,'mention_rate'=>$valid?round(100*(int)$m['mentions']/$valid,1):0,'citation_rate'=>$valid?round(100*(int)$m['citations']/$valid,1):0,'unique_pages'=>(int)($m['unique_pages']??0)];
        $provider=self::group($pdo,"SELECT r.provider label,COUNT(*) n,SUM(o.mentioned=1) mentions,SUM(o.cited=1) citations".$base." GROUP BY r.provider ORDER BY n DESC",$args);
        $types=self::group($pdo,"SELECT p.query_type label,COUNT(*) n,SUM(o.mentioned=1) mentions,SUM(o.cited=1) citations".$base." GROUP BY p.query_type ORDER BY n DESC",$args);
        $trend=self::group($pdo,"SELECT DATE_FORMAT(o.answer_date,'%Y-%m') label,COUNT(*) n,SUM(o.mentioned=1) mentions,SUM(o.cited=1) citations".$base." GROUP BY DATE_FORMAT(o.answer_date,'%Y-%m') ORDER BY label",$args);
        $pages=self::group($pdo,"SELECT o.cited_url label,COUNT(*) n".$base." AND o.cited=1 AND o.cited_url IS NOT NULL GROUP BY o.cited_url ORDER BY n DESC LIMIT 20",$args);
        $gaps=self::group($pdo,"SELECT p.prompt_key,p.prompt_text,p.query_type,r.provider,o.other_sources_json,o.answer_date".$base." AND COALESCE(o.cited,0)=0 ORDER BY o.answer_date DESC LIMIT 50",$args);
        $invalid=$pdo->query("SELECT o.observation_status,COUNT(*) n FROM ai_visibility_observations o GROUP BY o.observation_status")->fetchAll(PDO::FETCH_ASSOC);
        return ['metrics'=>$metrics,'by_provider'=>$provider,'by_query_type'=>$types,'trend'=>$trend,'top_cited_pages'=>$pages,'gaps'=>$gaps,'observation_statuses'=>$invalid,'days'=>$days];
    }
    public static function importRun(PDO $pdo,array $data,int $uid): array {
        $provider=trim((string)($data['provider']??''));if($provider==='')throw new InvalidArgumentException('provider_required');
        $mode=(string)($data['run_mode']??'manual');if(!in_array($mode,['manual','semi_automated','import','automated'],true))throw new InvalidArgumentException('invalid_run_mode');
        $rows=$data['observations']??[];if(!is_array($rows)||!$rows)throw new InvalidArgumentException('observations_required');
        $pdo->beginTransaction();try{
            $st=$pdo->prepare("INSERT INTO ai_visibility_runs(provider,model_name,run_mode,status,started_at,completed_at,notes,created_by_user_id) VALUES(?,?,?,'complete',COALESCE(?,NOW()),NOW(),?,?)");$st->execute([$provider,trim((string)($data['model_name']??''))?:null,$mode,$data['started_at']??null,$data['notes']??null,$uid]);$run=(int)$pdo->lastInsertId();
            $find=$pdo->prepare('SELECT id FROM ai_visibility_prompts WHERE prompt_key=?');$ins=$pdo->prepare("INSERT INTO ai_visibility_observations(run_id,prompt_id,observation_status,answer_date,mentioned,cited,cited_url,source_position,other_sources_json,response_reference,notes) VALUES(?,?,?,?,?,?,?,?,?,?,?)");$ok=0;
            foreach($rows as $r){$find->execute([(string)($r['prompt_key']??'')]);$pid=(int)$find->fetchColumn();if(!$pid)throw new InvalidArgumentException('unknown_prompt_key');$status=(string)($r['status']??'valid');if(!in_array($status,['valid','ambiguous','failed'],true))throw new InvalidArgumentException('invalid_observation_status');$mentioned=$status==='valid'?(isset($r['mentioned'])?(int)(bool)$r['mentioned']:0):null;$cited=$status==='valid'?(isset($r['cited'])?(int)(bool)$r['cited']:0):null;$other=$r['other_sources']??[];$ins->execute([$run,$pid,$status,$r['answer_date']??date('Y-m-d H:i:s'),$mentioned,$cited,$r['cited_url']??null,isset($r['source_position'])?(int)$r['source_position']:null,json_encode(is_array($other)?$other:[]),$r['response_reference']??null,$r['notes']??null]);$ok++;}
            $pdo->commit();return ['run_id'=>$run,'observations'=>$ok];
        }catch(Throwable $e){$pdo->rollBack();throw $e;}
    }
    public static function runs(PDO $pdo): array {return $pdo->query("SELECT r.id,r.provider,r.model_name,r.run_mode,r.status,r.started_at,r.completed_at,COUNT(o.id) observations,SUM(o.observation_status='valid') valid_observations FROM ai_visibility_runs r LEFT JOIN ai_visibility_observations o ON o.run_id=r.id GROUP BY r.id ORDER BY r.started_at DESC LIMIT 100")->fetchAll(PDO::FETCH_ASSOC);}
    private static function group(PDO $pdo,string $sql,array $args): array {$st=$pdo->prepare($sql);$st->execute($args);$rows=$st->fetchAll(PDO::FETCH_ASSOC);foreach($rows as &$r){if(isset($r['n'])&&(int)$r['n']>0){$r['mention_rate']=isset($r['mentions'])?round(100*(int)$r['mentions']/(int)$r['n'],1):null;$r['citation_rate']=isset($r['citations'])?round(100*(int)$r['citations']/(int)$r['n'],1):null;}}return $rows;}
}
