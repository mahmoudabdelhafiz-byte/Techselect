<?php
final class ProgrammaticSeoQualityGate {
    public static function settings(PDO $pdo): array {
        $defaults=['min_indexable_body_chars'=>1400,'min_noindex_body_chars'=>800,'min_indexable_evidence'=>3,'min_noindex_evidence'=>2,'min_indexable_sources'=>2,'min_internal_links'=>2,'min_rationale_chars'=>250,'max_freshness_days'=>180,'near_duplicate_threshold'=>0.82];
        try{$q=$pdo->query('SELECT setting_key,setting_value FROM seo_quality_gate_settings');foreach($q as $r)if(array_key_exists($r['setting_key'],$defaults))$defaults[$r['setting_key']]=(float)$r['setting_value'];}catch(Throwable $e){}
        return $defaults;
    }

    public static function evaluate(PDO $pdo,array $page): array {
        $s=self::settings($pdo);$reasons=[];$hard=[];$soft=[];
        $body=trim(strip_tags((string)($page['body_text']??'')));$rationale=trim(strip_tags((string)($page['recommendation_text']??'')));
        $title=trim((string)($page['title']??''));$h1=trim((string)($page['h1']??''));$meta=trim((string)($page['meta_description']??''));
        $evidence=(int)($page['evidence_count']??0);$sources=(int)($page['source_count']??0);$links=(int)($page['internal_link_count']??0);
        if(mb_strlen($body)<$s['min_noindex_body_chars'])$hard[]='body_too_thin_to_publish';
        if($evidence<$s['min_noindex_evidence'])$hard[]='insufficient_evidence_to_publish';
        if($title===''||$h1==='')$hard[]='missing_title_or_h1';
        if(mb_strlen($body)<$s['min_indexable_body_chars'])$soft[]='body_below_indexable_threshold';
        if($evidence<$s['min_indexable_evidence'])$soft[]='evidence_below_indexable_threshold';
        if($sources<$s['min_indexable_sources'])$soft[]='insufficient_source_diversity';
        if($links<$s['min_internal_links'])$soft[]='insufficient_internal_links';
        if(mb_strlen($rationale)<$s['min_rationale_chars'])$soft[]='recommendation_rationale_too_thin';
        if(mb_strlen($title)<30||mb_strlen($title)>75)$soft[]='title_length_outside_target';
        if(mb_strlen($h1)<20||mb_strlen($h1)>110)$soft[]='h1_length_outside_target';
        if(mb_strlen($meta)<100||mb_strlen($meta)>180)$soft[]='meta_description_length_outside_target';
        if(empty($page['last_reviewed_at']))$soft[]='freshness_unknown';else{$age=(int)floor((time()-strtotime($page['last_reviewed_at']))/86400);if($age>$s['max_freshness_days'])$soft[]='stale_content';}
        $duplicate=self::bestDuplicate($pdo,$page,$s['near_duplicate_threshold']);$canonical=null;
        if($duplicate){$soft[]='near_duplicate_or_overlapping_intent';$canonical=$duplicate['canonical_path'];}
        $reasons=array_values(array_unique(array_merge($hard,$soft)));
        $decision=$hard?'not_generated':($soft?'published_noindex':'indexable');
        $checks=10;$penalty=count($hard)*18+count($soft)*7;$score=max(0,min(100,100-$penalty));
        return ['decision'=>$decision,'score'=>$score,'reasons'=>$reasons,'canonical_target_path'=>$canonical,'thresholds'=>$s];
    }

    public static function run(PDO $pdo,int $pageId,?int $userId=null): array {
        $q=$pdo->prepare('SELECT * FROM seo_generated_pages WHERE id=? LIMIT 1');$q->execute([$pageId]);$page=$q->fetch(PDO::FETCH_ASSOC);if(!$page)throw new RuntimeException('page_not_found');
        $result=self::evaluate($pdo,$page);
        $pdo->prepare('UPDATE seo_generated_pages SET quality_decision=?,quality_score=?,gate_reasons_json=?,canonical_target_path=?,last_gate_run_at=NOW() WHERE id=?')->execute([$result['decision'],$result['score'],json_encode($result['reasons']),$result['canonical_target_path'],$pageId]);
        $pdo->prepare('INSERT INTO seo_quality_gate_runs(page_id,decision,score,reasons_json,canonical_target_path,thresholds_json,run_by_user_id) VALUES(?,?,?,?,?,?,?)')->execute([$pageId,$result['decision'],$result['score'],json_encode($result['reasons']),$result['canonical_target_path'],json_encode($result['thresholds']),$userId]);
        return $result;
    }

    public static function robotsFor(array $page): string {
        return (($page['status']??'draft')==='published'&&($page['quality_decision']??'pending')==='indexable')?'index,follow,max-snippet:-1,max-image-preview:large':'noindex,follow';
    }

    public static function isIndexable(array $page): bool {return ($page['status']??'')==='published'&&($page['quality_decision']??'')==='indexable';}

    private static function bestDuplicate(PDO $pdo,array $page,float $threshold): ?array {
        $id=(int)($page['id']??0);$intent=self::normalize((string)($page['intent_key']??''));$body=self::tokens((string)($page['body_text']??''));$fp=trim((string)($page['evidence_fingerprint']??''));
        $q=$pdo->prepare("SELECT id,canonical_path,intent_key,body_text,evidence_fingerprint,quality_score,quality_decision,status FROM seo_generated_pages WHERE id<>? AND status<>'archived' ORDER BY quality_score DESC,id ASC LIMIT 300");$q->execute([$id]);
        foreach($q->fetchAll(PDO::FETCH_ASSOC) as $other){
            $sameIntent=$intent!==''&&$intent===self::normalize((string)$other['intent_key']);$sameEvidence=$fp!==''&&hash_equals($fp,(string)($other['evidence_fingerprint']??''));$sim=self::jaccard($body,self::tokens((string)($other['body_text']??'')));
            if($sameIntent||($sameEvidence&&$sim>=0.60)||$sim>=$threshold)return $other;
        }
        return null;
    }
    private static function normalize(string $s):string{$s=mb_strtolower(trim($s));$s=preg_replace('/[^a-z0-9]+/u',' ',$s);return trim(preg_replace('/\s+/',' ',$s));}
    private static function tokens(string $s):array{$parts=preg_split('/\s+/u',self::normalize(strip_tags($s)),-1,PREG_SPLIT_NO_EMPTY);return array_fill_keys(array_values(array_unique(array_filter($parts,fn($x)=>mb_strlen($x)>=3))),true);}
    private static function jaccard(array $a,array $b):float{if(!$a||!$b)return 0;$i=count(array_intersect_key($a,$b));$u=count($a+$b);return $u?$i/$u:0;}
}
