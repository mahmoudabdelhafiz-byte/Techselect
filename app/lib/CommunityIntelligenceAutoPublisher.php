<?php

final class CommunityIntelligenceAutoPublisher
{
    private const SENSITIVE_TERMS=['fraud','fraudulent','scam','scammer','illegal','criminal','crime','lawsuit','bribe','bribery','theft','stolen','corrupt','corruption'];

    public static function settings(PDO $pdo): array
    {
        $defaults=['enabled'=>0,'min_usable_sources'=>15,'min_source_diversity'=>3,'min_confidence'=>0.75,'max_single_domain_share'=>0.50,'min_recent_sources'=>5,'recent_days'=>365,'max_score_movement'=>1.00,'extreme_low_score'=>1.50,'extreme_high_score'=>4.80,'max_suspicious_ratio'=>0.35];
        try{$row=$pdo->query("SELECT * FROM community_intelligence_auto_publish_settings WHERE id=1 LIMIT 1")->fetch(PDO::FETCH_ASSOC);if(!$row)return $defaults;foreach($defaults as $k=>$v){if(array_key_exists($k,$row))$defaults[$k]=is_int($v)?(int)$row[$k]:(float)$row[$k];}$defaults['enabled']=!empty($row['enabled'])?1:0;$defaults['updated_at']=$row['updated_at']??null;return $defaults;}catch(Throwable $e){return $defaults+['migration_required'=>true];}
    }

    public static function updateSettings(PDO $pdo,array $input,int $userId): array
    {
        $current=self::settings($pdo);$intRanges=['min_usable_sources'=>[5,500],'min_source_diversity'=>[2,20],'min_recent_sources'=>[0,500],'recent_days'=>[30,1095]];$floatRanges=['min_confidence'=>[0.50,1.00],'max_single_domain_share'=>[0.10,1.00],'max_score_movement'=>[0.10,3.00],'extreme_low_score'=>[0.00,2.50],'extreme_high_score'=>[2.50,5.00],'max_suspicious_ratio'=>[0.00,1.00]];$next=$current;$next['enabled']=!empty($input['enabled'])?1:0;
        foreach($intRanges as $k=>[$min,$max])if(array_key_exists($k,$input)){$v=(int)$input[$k];if($v<$min||$v>$max)throw new InvalidArgumentException("Invalid {$k}.");$next[$k]=$v;}
        foreach($floatRanges as $k=>[$min,$max])if(array_key_exists($k,$input)){$v=(float)$input[$k];if($v<$min||$v>$max)throw new InvalidArgumentException("Invalid {$k}.");$next[$k]=$v;}
        if($next['extreme_low_score'] >= $next['extreme_high_score'])throw new InvalidArgumentException('Extreme score thresholds are invalid.');
        $sql="INSERT INTO community_intelligence_auto_publish_settings(id,enabled,min_usable_sources,min_source_diversity,min_confidence,max_single_domain_share,min_recent_sources,recent_days,max_score_movement,extreme_low_score,extreme_high_score,max_suspicious_ratio,updated_by_user_id) VALUES(1,?,?,?,?,?,?,?,?,?,?,?,?) ON DUPLICATE KEY UPDATE enabled=VALUES(enabled),min_usable_sources=VALUES(min_usable_sources),min_source_diversity=VALUES(min_source_diversity),min_confidence=VALUES(min_confidence),max_single_domain_share=VALUES(max_single_domain_share),min_recent_sources=VALUES(min_recent_sources),recent_days=VALUES(recent_days),max_score_movement=VALUES(max_score_movement),extreme_low_score=VALUES(extreme_low_score),extreme_high_score=VALUES(extreme_high_score),max_suspicious_ratio=VALUES(max_suspicious_ratio),updated_by_user_id=VALUES(updated_by_user_id)";$pdo->prepare($sql)->execute([$next['enabled'],$next['min_usable_sources'],$next['min_source_diversity'],$next['min_confidence'],$next['max_single_domain_share'],$next['min_recent_sources'],$next['recent_days'],$next['max_score_movement'],$next['extreme_low_score'],$next['extreme_high_score'],$next['max_suspicious_ratio'],$userId]);return self::settings($pdo);
    }

    public static function setManualHold(PDO $pdo,int $productId,?string $reason): void
    {
        $reason=trim((string)$reason);if(mb_strlen($reason)>255)throw new InvalidArgumentException('Manual hold reason is too long.');$pdo->prepare("UPDATE product_public_review_intelligence SET auto_publish_manual_hold_reason=? WHERE product_id=?")->execute([$reason!==''?$reason:null,$productId]);
    }

    public static function evaluate(PDO $pdo,int $productId,array $candidate,array $prior=[]): array
    {
        $policy=self::settings($pdo);$metrics=self::sourceMetrics($pdo,$productId,(int)$policy['recent_days']);$usable=(int)($candidate['sources_analyzed']??0);$types=(int)($candidate['source_type_count']??0);$confidence=(float)($candidate['confidence_score']??0);$score=isset($candidate['score_5'])?(float)$candidate['score_5']:null;$priorPublished=(($prior['review_status']??'')==='published'&&!empty($prior['published_at']));$priorScore=$priorPublished&&isset($prior['score_5'])?(float)$prior['score_5']:null;$movement=($priorScore!==null&&$score!==null)?abs($score-$priorScore):0.0;$manualHold=trim((string)($prior['auto_publish_manual_hold_reason']??''));$sensitive=self::containsSensitiveLanguage($candidate);$minD=(int)$policy['min_source_diversity'];
        $gates=['policy_enabled'=>['pass'=>!empty($policy['enabled']),'value'=>(int)$policy['enabled'],'required'=>1],'sufficient_data'=>['pass'=>empty($candidate['insufficient_data'])&&$score!==null,'value'=>$candidate['insufficient_data']??1,'required'=>0],'usable_sources'=>['pass'=>$usable>=(int)$policy['min_usable_sources'],'value'=>$usable,'required'=>(int)$policy['min_usable_sources']],'source_diversity'=>['pass'=>$types>=$minD&&$metrics['domain_count']>=$minD,'value'=>['types'=>$types,'domains'=>$metrics['domain_count']],'required'=>['types'=>$minD,'domains'=>$minD]],'confidence'=>['pass'=>$confidence>=(float)$policy['min_confidence'],'value'=>$confidence,'required'=>(float)$policy['min_confidence']],'domain_concentration'=>['pass'=>$metrics['max_domain_share']<=(float)$policy['max_single_domain_share'],'value'=>$metrics['max_domain_share'],'required'=>(float)$policy['max_single_domain_share']],'recent_sources'=>['pass'=>$metrics['recent_count']>=(int)$policy['min_recent_sources'],'value'=>$metrics['recent_count'],'required'=>(int)$policy['min_recent_sources']],'source_policy_clear'=>['pass'=>$metrics['unresolved_policy_count']===0,'value'=>$metrics['unresolved_policy_count'],'required'=>0],'suspicious_mix'=>['pass'=>$metrics['suspicious_ratio']<=(float)$policy['max_suspicious_ratio'],'value'=>$metrics['suspicious_ratio'],'required'=>(float)$policy['max_suspicious_ratio']],'score_stability'=>['pass'=>$priorScore===null||$movement<=(float)$policy['max_score_movement'],'value'=>round($movement,2),'required'=>(float)$policy['max_score_movement']],'non_extreme_score'=>['pass'=>$score!==null&&$score>(float)$policy['extreme_low_score']&&$score<(float)$policy['extreme_high_score'],'value'=>$score,'required'=>[(float)$policy['extreme_low_score'],(float)$policy['extreme_high_score']]],'manual_product_match_hold'=>['pass'=>$manualHold==='','value'=>$manualHold?:null,'required'=>null],'sensitive_language'=>['pass'=>!$sensitive,'value'=>$sensitive,'required'=>false]];
        $failed=array_keys(array_filter($gates,static fn($g)=>empty($g['pass'])));$decision=$failed?'review_required':'auto_publish';return ['decision'=>$decision,'eligible'=>$decision==='auto_publish','failed_gates'=>$failed,'gates'=>$gates,'prior_published_score'=>$priorScore,'candidate_score'=>$score,'source_metrics'=>$metrics,'policy'=>$policy];
    }

    public static function auditDecision(PDO $pdo,int $productId,?int $analysisRunId,array $decision): void
    {
        try{$pdo->prepare("INSERT INTO community_intelligence_auto_publish_history(product_id,analysis_run_id,decision,prior_published_score,candidate_score,gate_results_json,policy_snapshot_json) VALUES(?,?,?,?,?,?,?)")->execute([$productId,$analysisRunId,$decision['decision'],$decision['prior_published_score'],$decision['candidate_score'],json_encode(['failed_gates'=>$decision['failed_gates'],'gates'=>$decision['gates'],'source_metrics'=>$decision['source_metrics']],JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE),json_encode($decision['policy'],JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE)]);}catch(Throwable $e){}
    }

    public static function evaluateExisting(PDO $pdo,int $productId): array
    {
        $st=$pdo->prepare("SELECT * FROM product_public_review_intelligence WHERE product_id=? LIMIT 1");$st->execute([$productId]);$row=$st->fetch(PDO::FETCH_ASSOC);if(!$row)throw new RuntimeException('Community Intelligence record not found.');$held=json_decode((string)($row['auto_publish_candidate_json']??''),true);
        if(is_array($held)&&$held){$candidate=$held;$candidate['strengths']=$held['strengths']??[];$candidate['concerns']=$held['concerns']??[];$candidate['themes']=$held['themes']??[];$decision=self::evaluate($pdo,$productId,$candidate,$row);if($decision['eligible'])self::applyCandidateSnapshot($pdo,$productId,$held);self::applyDecision($pdo,$productId,$row,$decision,isset($held['analysis_run_id'])?(int)$held['analysis_run_id']:null);return $decision;}
        $candidate=$row;$candidate['strengths']=json_decode($row['strengths_json']??'[]',true)?:[];$candidate['concerns']=json_decode($row['concerns_json']??'[]',true)?:[];$candidate['themes']=json_decode($row['themes_json']??'{}',true)?:[];$decision=self::evaluate($pdo,$productId,$candidate,$row);self::applyDecision($pdo,$productId,$row,$decision,isset($row['analysis_run_id'])?(int)$row['analysis_run_id']:null);return $decision;
    }

    public static function applyDecision(PDO $pdo,int $productId,array $prior,array $decision,?int $analysisRunId=null): void
    {
        $json=json_encode(['failed_gates'=>$decision['failed_gates'],'gates'=>$decision['gates'],'source_metrics'=>$decision['source_metrics']],JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);$reason=$decision['failed_gates']?implode(', ',array_slice($decision['failed_gates'],0,6)):null;
        if($decision['eligible']){$pdo->prepare("UPDATE product_public_review_intelligence SET review_status='published',published_at=COALESCE(published_at,NOW()),publication_mode='auto',auto_publish_checked_at=NOW(),auto_publish_decision_json=?,auto_publish_hold_reason=NULL,auto_publish_candidate_json=NULL,previous_published_score=? WHERE product_id=?")->execute([$json,$decision['prior_published_score'],$productId]);}
        else{$wasPublished=(($prior['review_status']??'')==='published'&&!empty($prior['published_at']));$status=$wasPublished?'published':'needs_review';$pdo->prepare("UPDATE product_public_review_intelligence SET review_status=?,auto_publish_checked_at=NOW(),auto_publish_decision_json=?,auto_publish_hold_reason=?,previous_published_score=? WHERE product_id=?")->execute([$status,$json,$reason,$decision['prior_published_score'],$productId]);}
        self::auditDecision($pdo,$productId,$analysisRunId,$decision);
    }

    private static function applyCandidateSnapshot(PDO $pdo,int $productId,array $s): void
    {
        $sql="UPDATE product_public_review_intelligence SET analysis_run_id=?,score_5=?,positive_sentiment_pct=?,confidence_score=?,confidence_label=?,sources_analyzed=?,source_type_count=?,insufficient_data=?,strengths_json=?,concerns_json=?,themes_json=?,source_mix_json=?,date_range_start=?,date_range_end=?,methodology_version=?,last_analyzed_at=? WHERE product_id=?";$pdo->prepare($sql)->execute([(int)$s['analysis_run_id'],$s['score_5'],$s['positive_sentiment_pct'],$s['confidence_score'],$s['confidence_label'],(int)$s['sources_analyzed'],(int)$s['source_type_count'],!empty($s['insufficient_data'])?1:0,json_encode($s['strengths']??[]),json_encode($s['concerns']??[]),json_encode($s['themes']??[]),json_encode($s['source_mix']??[]),$s['date_range_start']??null,$s['date_range_end']??null,$s['methodology_version'],$s['last_analyzed_at']??gmdate('Y-m-d H:i:s'),$productId]);
    }

    private static function sourceMetrics(PDO $pdo,int $productId,int $recentDays): array
    {
        $sql="SELECT s.id,s.source_url,s.source_type,s.source_published_at,s.access_policy,sg.id signal_id,sg.source_confidence,sg.specificity_score,sg.duplicate_suspected,sg.spam_suspected,sg.affiliate_suspected,sg.vendor_promotion_suspected,sg.bot_suspected,sg.low_signal_suspected,sg.exclusion_reason FROM public_review_sources s LEFT JOIN public_review_signals sg ON sg.id=(SELECT MAX(x.id) FROM public_review_signals x WHERE x.source_id=s.id) WHERE s.product_id=? AND s.status='active'";$st=$pdo->prepare($sql);$st->execute([$productId]);$rows=$st->fetchAll(PDO::FETCH_ASSOC);$domains=[];$recent=0;$unresolved=0;$suspicious=0;$analyzed=0;$usable=0;$cutoff=time()-($recentDays*86400);
        foreach($rows as $r){$policy=(string)($r['access_policy']??'pending_review');if(in_array($policy,['pending_review','restricted'],true))$unresolved++;if($policy!=='permitted'||empty($r['signal_id']))continue;$analyzed++;$flagged=!empty($r['duplicate_suspected'])||!empty($r['spam_suspected'])||!empty($r['affiliate_suspected'])||!empty($r['vendor_promotion_suspected'])||!empty($r['bot_suspected'])||!empty($r['low_signal_suspected'])||!empty($r['exclusion_reason']);if($flagged)$suspicious++;if($flagged||(float)($r['source_confidence']??0)<0.35||(float)($r['specificity_score']??0)<0.30)continue;$usable++;$host=strtolower((string)parse_url((string)$r['source_url'],PHP_URL_HOST));$host=preg_replace('/^www\./','',$host);if($host!=='')$domains[$host]=($domains[$host]??0)+1;if(!empty($r['source_published_at'])&&strtotime((string)$r['source_published_at'])>=$cutoff)$recent++;}
        $max=$domains?max($domains):0;$den=max(1,array_sum($domains));return ['domain_count'=>count($domains),'max_domain_share'=>round($max/$den,3),'recent_count'=>$recent,'unresolved_policy_count'=>$unresolved,'suspicious_ratio'=>round($suspicious/max(1,$analyzed),3),'analyzed_source_count'=>$analyzed,'usable_source_count'=>$usable];
    }

    private static function containsSensitiveLanguage(array $candidate): bool
    {
        $parts=[];foreach(['strengths','concerns'] as $k)foreach((array)($candidate[$k]??[]) as $v)$parts[]=is_scalar($v)?(string)$v:json_encode($v);foreach((array)($candidate['themes']??[]) as $vals)foreach((array)$vals as $v)$parts[]=is_scalar($v)?(string)$v:json_encode($v);$text=mb_strtolower(implode(' ',array_filter($parts)));foreach(self::SENSITIVE_TERMS as $term)if(preg_match('/\b'.preg_quote($term,'/').'\b/u',$text))return true;return false;
    }
}
