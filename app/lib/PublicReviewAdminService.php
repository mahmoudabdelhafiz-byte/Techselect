<?php

require_once __DIR__.'/PublicReviewIngestion.php';
require_once __DIR__.'/PublicReviewAiAnalyzer.php';

final class PublicReviewAdminService
{
    private static function validateUrl(string $url):string
    {
        $url=trim($url);if(!filter_var($url,FILTER_VALIDATE_URL))throw new InvalidArgumentException('A valid public source URL is required.');
        $scheme=strtolower((string)parse_url($url,PHP_URL_SCHEME));if(!in_array($scheme,['http','https'],true))throw new InvalidArgumentException('Only http/https public URLs are allowed.');return $url;
    }
    public static function addSource(PDO $pdo,array $input):array
    {
        $productId=(int)($input['product_id']??0);if($productId<1)throw new InvalidArgumentException('product_id is required.');$url=self::validateUrl((string)($input['source_url']??''));
        $type=strtolower(trim((string)($input['source_type']??'')));if(!preg_match('/^[a-z0-9_-]{2,50}$/',$type))throw new InvalidArgumentException('Invalid source_type.');
        $name=trim((string)($input['source_name']??''))?:null;$published=trim((string)($input['source_published_at']??''))?:null;$notes=trim((string)($input['access_policy_notes']??''))?:null;
        $exists=$pdo->prepare("SELECT id FROM products WHERE id=? AND status='active'");$exists->execute([$productId]);if(!$exists->fetchColumn())throw new InvalidArgumentException('Active product not found.');
        $st=$pdo->prepare("INSERT INTO public_review_sources(product_id,source_url,source_url_hash,source_type,source_name,source_published_at,access_policy,access_policy_notes,status) VALUES(?,?,?,?,?,?,'pending_review',?,'active')");
        $st->execute([$productId,$url,PublicReviewIngestion::urlHash($url),$type,$name,$published,$notes]);return self::getSource($pdo,(int)$pdo->lastInsertId());
    }
    public static function getSource(PDO $pdo,int $id):array
    {
        $st=$pdo->prepare("SELECT s.id,s.product_id,p.name product,p.slug product_slug,s.source_url,s.source_type,s.source_name,s.source_published_at,s.access_policy,s.access_policy_checked_at,s.access_policy_notes,s.status,s.created_at,s.updated_at FROM public_review_sources s JOIN products p ON p.id=s.product_id WHERE s.id=?");$st->execute([$id]);$row=$st->fetch();if(!$row)throw new RuntimeException('PRI source not found.');return $row;
    }
    public static function listSources(PDO $pdo,?int $productId=null):array
    {
        if($productId){$st=$pdo->prepare("SELECT s.id,s.product_id,p.name product,p.slug product_slug,s.source_url,s.source_type,s.source_name,s.source_published_at,s.access_policy,s.access_policy_checked_at,s.access_policy_notes,s.status,s.created_at,s.updated_at FROM public_review_sources s JOIN products p ON p.id=s.product_id WHERE s.product_id=? ORDER BY s.created_at DESC");$st->execute([$productId]);}
        else{$st=$pdo->query("SELECT s.id,s.product_id,p.name product,p.slug product_slug,s.source_url,s.source_type,s.source_name,s.source_published_at,s.access_policy,s.access_policy_checked_at,s.access_policy_notes,s.status,s.created_at,s.updated_at FROM public_review_sources s JOIN products p ON p.id=s.product_id ORDER BY s.created_at DESC LIMIT 300");}return $st->fetchAll();
    }
    public static function setPolicy(PDO $pdo,int $id,string $policy,?string $notes):array
    {
        if(!in_array($policy,['pending_review','permitted','restricted','blocked'],true))throw new InvalidArgumentException('Invalid source policy.');self::getSource($pdo,$id);$pdo->prepare("UPDATE public_review_sources SET access_policy=?,access_policy_checked_at=NOW(),access_policy_notes=? WHERE id=?")->execute([$policy,$notes,$id]);return self::getSource($pdo,$id);
    }
    public static function analyzeProduct(PDO $pdo,int $productId,array $snapshots):array
    {
        if($productId<1)throw new InvalidArgumentException('product_id is required.');if(!$snapshots)throw new InvalidArgumentException('At least one source snapshot is required.');if(count($snapshots)>25)throw new InvalidArgumentException('Maximum 25 source snapshots per run.');
        $model=trim((string)getenv('TECHSELECT_PRI_MODEL'));$run=$pdo->prepare("INSERT INTO public_review_analysis_runs(product_id,model_provider,model_name,analysis_version,status,source_count) VALUES(?,'OpenAI',?,?,'running',?)");$run->execute([$productId,$model?:null,PublicReviewIngestion::ANALYSIS_VERSION,count($snapshots)]);$runId=(int)$pdo->lastInsertId();$eligible=0;$excluded=0;$errors=[];
        try{
            foreach($snapshots as $snapshot){$sourceId=(int)($snapshot['source_id']??0);$content=trim((string)($snapshot['content']??''));if($sourceId<1||$content===''){$excluded++;$errors[]=['source_id'=>$sourceId,'error'=>'source_id_and_content_required'];continue;}
                $st=$pdo->prepare("SELECT * FROM public_review_sources WHERE id=? AND product_id=? LIMIT 1");$st->execute([$sourceId,$productId]);$source=$st->fetch();if(!$source){$excluded++;$errors[]=['source_id'=>$sourceId,'error'=>'source_not_found'];continue;}try{PublicReviewIngestion::validateSource($source);}catch(Throwable $e){$excluded++;$errors[]=['source_id'=>$sourceId,'error'=>$e->getMessage()];continue;}
                $fingerprint=PublicReviewIngestion::contentFingerprint($content);$dup=$pdo->prepare("SELECT COUNT(*) FROM public_review_sources WHERE product_id=? AND id<>? AND content_fingerprint=?");$dup->execute([$productId,$sourceId,$fingerprint]);$duplicate=(int)$dup->fetchColumn()>0;
                try{$raw=PublicReviewAiAnalyzer::analyze($content,$source);if($duplicate)$raw['duplicate_suspected']=true;$signal=PublicReviewIngestion::normalizeDerivedSignal($raw);$pdo->prepare("UPDATE public_review_sources SET content_fingerprint=? WHERE id=?")->execute([$fingerprint,$sourceId]);
                    $pdo->prepare("INSERT INTO public_review_signals(source_id,analysis_run_id,sentiment_score,sentiment_label,public_rating,public_rating_scale,topic_json,themes_json,reviewer_context_json,source_confidence,source_quality,independence_score,specificity_score,duplicate_suspected,spam_suspected,affiliate_suspected,vendor_promotion_suspected,bot_suspected,low_signal_suspected,exclusion_reason,retrieved_at) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,NOW())")->execute([$sourceId,$runId,$signal['sentiment_score'],$signal['sentiment_label'],$signal['public_rating'],$signal['public_rating_scale'],json_encode($signal['topics'],JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES),json_encode($signal['themes'],JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES),json_encode($signal['reviewer_context'],JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES),$signal['source_confidence'],$signal['source_quality'],$signal['independence_score'],$signal['specificity_score'],$signal['duplicate_suspected']?1:0,$signal['spam_suspected']?1:0,$signal['affiliate_suspected']?1:0,$signal['vendor_promotion_suspected']?1:0,$signal['bot_suspected']?1:0,$signal['low_signal_suspected']?1:0,$signal['exclusion_reason']]);
                    if(PublicReviewIngestion::isEligibleSignal($signal))$eligible++;else{$excluded++;$errors[]=['source_id'=>$sourceId,'error'=>'signal_excluded','reason'=>$signal['exclusion_reason']??'low_confidence'];}
                }catch(Throwable $e){$excluded++;$errors[]=['source_id'=>$sourceId,'error'=>$e->getMessage()];}}
            $pdo->prepare("UPDATE public_review_analysis_runs SET status='completed',eligible_source_count=?,excluded_source_count=?,completed_at=NOW() WHERE id=?")->execute([$eligible,$excluded,$runId]);$rows=self::latestSignals($pdo,$productId);$intelligence=PublicReviewIntelligence::calculate($rows);[$strengths,$concerns,$themes,$mix,$start,$end]=self::summaries($rows);
            $pdo->prepare("INSERT INTO product_public_review_intelligence(product_id,analysis_run_id,score_5,positive_sentiment_pct,confidence_score,confidence_label,sources_analyzed,source_type_count,insufficient_data,strengths_json,concerns_json,themes_json,source_mix_json,date_range_start,date_range_end,methodology_version,last_analyzed_at) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,NOW()) ON DUPLICATE KEY UPDATE analysis_run_id=VALUES(analysis_run_id),score_5=VALUES(score_5),positive_sentiment_pct=VALUES(positive_sentiment_pct),confidence_score=VALUES(confidence_score),confidence_label=VALUES(confidence_label),sources_analyzed=VALUES(sources_analyzed),source_type_count=VALUES(source_type_count),insufficient_data=VALUES(insufficient_data),strengths_json=VALUES(strengths_json),concerns_json=VALUES(concerns_json),themes_json=VALUES(themes_json),source_mix_json=VALUES(source_mix_json),date_range_start=VALUES(date_range_start),date_range_end=VALUES(date_range_end),methodology_version=VALUES(methodology_version),last_analyzed_at=NOW()")->execute([$productId,$runId,$intelligence['score_5'],$intelligence['positive_sentiment_pct'],$intelligence['confidence_score'],$intelligence['confidence_label'],$intelligence['sources_analyzed'],$intelligence['source_type_count'],$intelligence['insufficient_data']?1:0,json_encode($strengths),json_encode($concerns),json_encode($themes),json_encode($mix),$start,$end,$intelligence['methodology_version']]);
            return ['analysis_run_id'=>$runId,'eligible'=>$eligible,'excluded'=>$excluded,'errors'=>$errors,'intelligence'=>$intelligence,'strengths'=>$strengths,'concerns'=>$concerns,'themes'=>$themes,'source_mix'=>$mix,'date_range'=>[$start,$end]];
        }catch(Throwable $e){$pdo->prepare("UPDATE public_review_analysis_runs SET status='failed',completed_at=NOW(),error_message=? WHERE id=?")->execute([mb_substr($e->getMessage(),0,2000),$runId]);throw $e;}
    }
    private static function latestSignals(PDO $pdo,int $productId):array
    {
        $sql="SELECT s.id source_id,s.source_type,s.source_published_at,s.access_policy,s.status,sg.sentiment_score,sg.sentiment_label,sg.public_rating,sg.public_rating_scale,sg.topic_json,sg.themes_json,sg.reviewer_context_json,sg.source_confidence,sg.source_quality,sg.independence_score,sg.specificity_score,sg.duplicate_suspected,sg.spam_suspected,sg.affiliate_suspected,sg.vendor_promotion_suspected,sg.bot_suspected,sg.low_signal_suspected,sg.exclusion_reason FROM public_review_sources s JOIN public_review_signals sg ON sg.id=(SELECT MAX(sg2.id) FROM public_review_signals sg2 WHERE sg2.source_id=s.id) WHERE s.product_id=? AND s.status='active' AND s.access_policy='permitted'";$st=$pdo->prepare($sql);$st->execute([$productId]);$rows=$st->fetchAll();foreach($rows as &$r){$r['topics']=json_decode($r['topic_json']??'[]',true)?:[];$r['themes']=json_decode($r['themes_json']??'{}',true)?:[];}unset($r);return array_values(array_filter($rows,fn($r)=>PublicReviewIngestion::isEligibleSignal($r)));
    }
    private static function summaries(array $rows):array
    {
        $themeKeys=['strengths','weaknesses','implementation','support','pricing_value','integrations','reliability','usability','best_fit','poor_fit'];$counts=array_fill_keys($themeKeys,[]);$mix=[];$dates=[];
        foreach($rows as $r){$mix[$r['source_type']]=($mix[$r['source_type']]??0)+1;if(!empty($r['source_published_at']))$dates[]=$r['source_published_at'];foreach($themeKeys as $k)foreach(($r['themes'][$k]??[]) as $v){$v=trim((string)$v);if($v!=='')$counts[$k][$v]=($counts[$k][$v]??0)+1;}}
        $themes=[];foreach($counts as $k=>$vals){arsort($vals);$themes[$k]=array_slice(array_keys($vals),0,6);}sort($dates);$start=$dates?$dates[0]:null;$end=$dates?$dates[count($dates)-1]:null;return [$themes['strengths'],$themes['weaknesses'],$themes,$mix,$start,$end];
    }
}
